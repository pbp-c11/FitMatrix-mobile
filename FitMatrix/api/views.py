from __future__ import annotations

from typing import Any

from django.contrib.auth import get_user_model
from django.db.models import Count, Min, Q
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import permissions, serializers, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from accounts.models import (
    CollectionItem,
    WishlistCollection,
    WishlistItem,
)
from places.models import Place
from places.services import newest_places, search_places, spotlight_places
from reviews.models import Review as PlaceReview
from scheduling.models import Booking, SessionSlot, Trainer

from .serializers import (
    BookingSerializer,
    CollectionItemSerializer,
    MeUpdateSerializer,
    PlaceReviewSerializer,
    PlaceSerializer,
    PlaceSummarySerializer,
    RegisterSerializer,
    SessionSlotSerializer,
    TrainerSerializer,
    TrainerSummarySerializer,
    UserSerializer,
    WishlistCollectionSerializer,
    WishlistItemSerializer,
)

User = get_user_model()


class IdentifierTokenObtainPairSerializer(TokenObtainPairSerializer):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # Allow clients to send either username or identifier without failing required-field validation.
        if "username" in self.fields:
            self.fields["username"].required = False
            self.fields["username"].allow_blank = True
        # Provide an identifier alias for convenience (username or email).
        self.fields["identifier"] = serializers.CharField(
            required=False,
            allow_blank=True,
            write_only=True,
        )

    @classmethod
    def get_token(cls, user: User):
        token = super().get_token(user)
        token["display_name"] = user.display_name
        token["role"] = user.role
        return token

    def validate(self, attrs: dict[str, Any]) -> dict[str, Any]:
        attrs = attrs.copy()
        identifier = attrs.get("username") or self.initial_data.get("identifier")
        if identifier:
            attrs["username"] = identifier
            if "@" in identifier:
                try:
                    user_obj = User.objects.get(email__iexact=identifier)
                    attrs["username"] = user_obj.get_username()
                except User.DoesNotExist:
                    pass
        return super().validate(attrs)


class IdentifierTokenObtainPairView(TokenObtainPairView):
    serializer_class = IdentifierTokenObtainPairSerializer


class RegisterView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response(UserSerializer(user, context={"request": request}).data, status=status.HTTP_201_CREATED)


class MeView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        serializer = UserSerializer(request.user, context={"request": request})
        return Response(serializer.data)

    def patch(self, request):
        serializer = MeUpdateSerializer(request.user, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(UserSerializer(request.user, context={"request": request}).data)


class HomeSummaryView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        summary = {
            "place_count": Place.objects.filter(is_active=True).count(),
            "studio_count": Place.objects.filter(is_active=True, facility_type=Place.FacilityType.STUDIO).count(),
            "trainer_count": Place.objects.filter(
                is_active=True,
                facility_type__in=[Place.FacilityType.GYM, Place.FacilityType.STUDIO],
            ).count(),
        }
        trending = (
            Place.objects.filter(is_active=True)
            .annotate(
                rate_count=Count("reviews", distinct=True),
            )
            .filter(rate_count__gte=1)
            .order_by("-rating_avg", "-rate_count")[:6]
        )
        payload = {
            "summary": summary,
            "spotlights": PlaceSummarySerializer(spotlight_places(limit=3), many=True).data,
            "newest": PlaceSummarySerializer(newest_places(limit=6), many=True).data,
            "trending": PlaceSummarySerializer(trending, many=True).data,
        }
        return Response(payload)


class PlaceViewSet(viewsets.ModelViewSet):
    serializer_class = PlaceSerializer
    lookup_field = "slug"

    def get_permissions(self):
        if self.action in {"create", "update", "partial_update", "destroy", "toggle_active"}:
            return [permissions.IsAdminUser()]
        return [permissions.AllowAny()]

    def get_queryset(self):
        query = self.request.query_params.get("q", "").strip()
        facility_type = self.request.query_params.get("type") or self.request.query_params.get("facility_type")
        city = self.request.query_params.get("city", "").strip()
        price_key = self.request.query_params.get("price")
        amenities_raw = self.request.query_params.getlist("amenities") or []
        sort = self.request.query_params.get("sort")

        if self.request.user.is_staff or getattr(self.request.user, "is_admin", False):
            qs = Place.objects.all()
        else:
            qs = Place.objects.active()
        qs = qs.search(query)
        qs = qs.by_type(facility_type)
        if city:
            qs = qs.filter(city__icontains=city)
        if price_key:
            from places.services import apply_price_filter

            qs = apply_price_filter(qs, price_key)
        if amenities_raw:
            for amenity in amenities_raw:
                qs = qs.filter(amenities__icontains=amenity)
        if sort == "newest":
            qs = qs.order_by("-created_at")
        elif sort == "rating":
            qs = qs.order_by("-rating_avg", "-likes")
        else:
            qs = qs.order_by("-highlight_score", "-rating_avg", "name")
        return qs

    @action(detail=True, methods=["post"], permission_classes=[permissions.IsAdminUser])
    def toggle_active(self, request, slug=None):
        place = self.get_object()
        place.is_active = not place.is_active
        place.save(update_fields=["is_active"])
        return Response({"is_active": place.is_active})


class TrainerViewSet(viewsets.ModelViewSet):
    serializer_class = TrainerSerializer

    def get_permissions(self):
        if self.action in {"create", "update", "partial_update", "destroy", "toggle_active"}:
            return [permissions.IsAdminUser()]
        return [permissions.AllowAny()]

    def get_queryset(self):
        query = self.request.query_params.get("q", "").strip()
        focus = self.request.query_params.get("focus", "").strip()
        qs = Trainer.objects.all()
        if not (self.request.user.is_staff or getattr(self.request.user, "is_admin", False)):
            qs = qs.filter(is_active=True)
        if query:
            qs = qs.filter(Q(name__icontains=query) | Q(specialties__icontains=query))
        if focus:
            qs = qs.filter(specialties__icontains=focus)
        qs = qs.annotate(
            next_available=Min("slots__start"),
            active_slots=Count("slots", filter=Q(slots__start__gte=timezone.now(), slots__is_active=True)),
        ).order_by("-likes", "-rating_avg", "name")
        return qs

    @action(detail=True, methods=["get"], permission_classes=[permissions.AllowAny])
    def slots(self, request, pk=None):
        trainer = self.get_object()
        slots = (
            trainer.slots.filter(is_active=True, start__gte=timezone.now())
            .select_related("place", "trainer")
            .order_by("start")
        )
        serializer = SessionSlotSerializer(slots, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=["post"], permission_classes=[permissions.IsAdminUser])
    def toggle_active(self, request, pk=None):
        trainer = self.get_object()
        trainer.is_active = not trainer.is_active
        trainer.save(update_fields=["is_active"])
        return Response({"is_active": trainer.is_active})


class SessionSlotViewSet(viewsets.ModelViewSet):
    serializer_class = SessionSlotSerializer
    permission_classes = [permissions.AllowAny]

    def get_permissions(self):
        if self.action in {"create", "update", "partial_update", "destroy"}:
            return [permissions.IsAdminUser()]
        return [permissions.AllowAny()]

    def get_queryset(self):
        query = self.request.query_params.get("q", "").strip()
        trainer_id = self.request.query_params.get("trainer")
        qs = SessionSlot.objects.select_related("trainer", "place")
        if not (self.request.user.is_staff or getattr(self.request.user, "is_admin", False)):
            qs = qs.filter(is_active=True, start__gte=timezone.now())
        if query:
            qs = qs.filter(
                Q(trainer__name__icontains=query)
                | Q(place__name__icontains=query)
                | Q(place__city__icontains=query)
            )
        if trainer_id:
            qs = qs.filter(trainer_id=trainer_id)
        return qs.order_by("start")


class BookingViewSet(viewsets.ModelViewSet):
    serializer_class = BookingSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        now = timezone.now()
        Booking.objects.filter(
            status=Booking.Status.BOOKED,
            slot__end__lt=now,
        ).update(status=Booking.Status.COMPLETED, updated_at=now)
        qs = Booking.objects.select_related("slot__trainer", "slot__place")
        if self.request.user.is_staff or getattr(self.request.user, "is_admin", False):
            return qs.order_by("-created_at")
        return qs.filter(user=self.request.user).order_by("-created_at")

    def perform_create(self, serializer: BookingSerializer):
        serializer.save(user=self.request.user)

    @action(detail=True, methods=["post"], permission_classes=[permissions.IsAuthenticated])
    def cancel(self, request, pk=None):
        booking = self.get_object()
        if not (request.user.is_staff or getattr(request.user, "is_admin", False) or booking.user == request.user):
            return Response(status=status.HTTP_403_FORBIDDEN)
        if booking.status != Booking.Status.CANCELLED:
            booking.cancel()
        return Response({"status": booking.status})

    @action(detail=True, methods=["post"], permission_classes=[permissions.IsAuthenticated])
    def reschedule(self, request, pk=None):
        booking = self.get_object()
        if booking.user != request.user and not (request.user.is_staff or getattr(request.user, "is_admin", False)):
            return Response(status=status.HTTP_403_FORBIDDEN)
        new_slot_id = request.data.get("slot")
        if not new_slot_id:
            return Response({"detail": "slot is required"}, status=status.HTTP_400_BAD_REQUEST)
        new_slot = get_object_or_404(SessionSlot, pk=new_slot_id)
        if new_slot.seats_left() <= 0:
            return Response({"detail": "Selected slot is full."}, status=status.HTTP_400_BAD_REQUEST)
        if Booking.objects.filter(
            user=booking.user,
            slot=new_slot,
            status=Booking.Status.BOOKED,
        ).exclude(pk=booking.pk).exists():
            return Response({"detail": "You already booked this slot."}, status=status.HTTP_400_BAD_REQUEST)
        booking.slot = new_slot
        booking.status = Booking.Status.BOOKED
        booking.save(update_fields=["slot", "status", "updated_at"])
        return Response(BookingSerializer(booking).data)


class WishlistViewSet(viewsets.ViewSet):
    permission_classes = [permissions.IsAuthenticated]

    def list(self, request):
        items = WishlistItem.objects.filter(user=request.user).select_related("place", "trainer")
        serializer = WishlistItemSerializer(items, many=True)
        return Response(serializer.data)

    def create(self, request):
        kind = request.data.get("kind")
        target_id = request.data.get("target_id")
        if kind not in {"place", "trainer"}:
            return Response({"detail": "Invalid kind"}, status=status.HTTP_400_BAD_REQUEST)
        if not target_id:
            return Response({"detail": "target_id is required"}, status=status.HTTP_400_BAD_REQUEST)

        filters: dict[str, Any] = {"user": request.user}
        if kind == "place":
            target = get_object_or_404(Place, pk=target_id)
            filters["place"] = target
        else:
            target = get_object_or_404(Trainer, pk=target_id)
            filters["trainer"] = target

        item = WishlistItem.objects.filter(**filters).first()
        status_label = "added"
        if item:
            item.delete()
            status_label = "removed"
        else:
            WishlistItem.objects.create(**filters)

        items = WishlistItem.objects.filter(user=request.user).select_related("place", "trainer")
        serializer = WishlistItemSerializer(items, many=True)
        return Response({"status": status_label, "items": serializer.data})


class WishlistCollectionViewSet(viewsets.ModelViewSet):
    serializer_class = WishlistCollectionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return WishlistCollection.objects.filter(user=self.request.user).prefetch_related("items__place")

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=True, methods=["post"])
    def add_item(self, request, pk=None):
        collection = self.get_object()
        place_id = request.data.get("place_id")
        if not place_id:
            return Response({"detail": "place_id is required"}, status=status.HTTP_400_BAD_REQUEST)
        place = get_object_or_404(Place, pk=place_id)
        CollectionItem.objects.get_or_create(collection=collection, place=place)
        WishlistItem.objects.get_or_create(user=request.user, place=place)
        collection.refresh_from_db()
        return Response(WishlistCollectionSerializer(collection).data)

    @action(detail=True, methods=["post"])
    def remove_item(self, request, pk=None):
        collection = self.get_object()
        item_id = request.data.get("item_id")
        if not item_id:
            return Response({"detail": "item_id is required"}, status=status.HTTP_400_BAD_REQUEST)
        item = get_object_or_404(CollectionItem, pk=item_id, collection=collection)
        item.delete()
        collection.refresh_from_db()
        return Response(WishlistCollectionSerializer(collection).data)


class PlaceReviewViewSet(viewsets.ModelViewSet):
    serializer_class = PlaceReviewSerializer

    def get_permissions(self):
        if self.action in {"create", "update", "partial_update", "destroy"}:
            return [permissions.IsAuthenticated()]
        return [permissions.AllowAny()]

    def get_queryset(self):
        place_slug = self.request.query_params.get("place")
        qs = PlaceReview.objects.select_related("user", "place")
        if place_slug:
            qs = qs.filter(place__slug=place_slug)
        if not (self.request.user.is_staff or getattr(self.request.user, "is_admin", False)):
            qs = qs.filter(place__is_active=True)
        return qs.order_by("-created_at")

    def perform_create(self, serializer):
        place_slug = self.request.data.get("place")
        place = get_object_or_404(Place, slug=place_slug)
        serializer.context["place"] = place
        serializer.save()


from __future__ import annotations

from typing import Any

from django.contrib.auth import get_user_model
from django.utils import timezone
from rest_framework import serializers

from accounts.models import (
    CollectionItem,
    WishlistCollection,
    WishlistItem,
)
from places.models import Place
from reviews.models import Review as PlaceReview
from scheduling.models import Booking, SessionSlot, Trainer


User = get_user_model()


def build_absolute_uri(request, url: str | None) -> str | None:
    if not url:
        return None
    if request:
        try:
            return request.build_absolute_uri(url)
        except Exception:
            return url
    return url


class UserSerializer(serializers.ModelSerializer):
    avatar = serializers.SerializerMethodField()
    is_admin = serializers.BooleanField(read_only=True)

    class Meta:
        model = User
        fields = ["id", "username", "email", "display_name", "role", "is_admin", "avatar"]

    def get_avatar(self, obj: User) -> str | None:
        request = self.context.get("request")
        if obj.avatar:
            return build_absolute_uri(request, obj.avatar.url)
        return None


class MeUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["display_name", "email", "avatar"]


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)
    avatar = serializers.ImageField(required=False, allow_null=True)

    class Meta:
        model = User
        fields = ["username", "email", "display_name", "password", "avatar"]

    def create(self, validated_data: dict[str, Any]) -> User:
        password = validated_data.pop("password")
        user = User(**validated_data)
        user.set_password(password)
        user.save()
        return user


class PlaceSerializer(serializers.ModelSerializer):
    price_display = serializers.SerializerMethodField()
    google_maps_url = serializers.SerializerMethodField()

    class Meta:
        model = Place
        fields = [
            "id",
            "name",
            "slug",
            "tagline",
            "summary",
            "address",
            "city",
            "facility_type",
            "amenities",
            "highlight_score",
            "accent_color",
            "hero_image",
            "gallery",
            "is_free",
            "price",
            "rating_avg",
            "likes",
            "is_active",
            "price_display",
            "google_maps_url",
            "latitude",
            "longitude",
        ]
        read_only_fields = ["slug", "price_display", "google_maps_url"]

    def to_representation(self, instance: Place) -> dict[str, Any]:
        data = super().to_representation(instance)
        data["amenities"] = instance.amenities_list()
        data["gallery"] = instance.gallery_list()
        return data

    def get_price_display(self, obj: Place) -> str:
        return obj.price_display()

    def get_google_maps_url(self, obj: Place) -> str | None:
        return obj.google_maps_url()


class PlaceSummarySerializer(serializers.ModelSerializer):
    price_display = serializers.SerializerMethodField()

    class Meta:
        model = Place
        fields = [
            "id",
            "name",
            "slug",
            "city",
            "facility_type",
            "price_display",
            "rating_avg",
            "likes",
            "hero_image",
            "accent_color",
        ]

    def get_price_display(self, obj: Place) -> str:
        return obj.price_display()


class TrainerSummarySerializer(serializers.ModelSerializer):
    class Meta:
        model = Trainer
        fields = [
            "id",
            "name",
            "specialties",
            "price_per_session",
            "rating_avg",
            "likes",
            "calendly_url",
            "is_active",
        ]


class TrainerSerializer(serializers.ModelSerializer):
    next_available = serializers.DateTimeField(read_only=True)
    active_slots = serializers.IntegerField(read_only=True)

    class Meta:
        model = Trainer
        fields = [
            "id",
            "name",
            "specialties",
            "bio",
            "price_per_session",
            "likes",
            "calendly_url",
            "rating_avg",
            "is_active",
            "next_available",
            "active_slots",
        ]


class SessionSlotSerializer(serializers.ModelSerializer):
    seats_left = serializers.SerializerMethodField()
    trainer = TrainerSummarySerializer(read_only=True)
    place = PlaceSummarySerializer(read_only=True)
    trainer_id = serializers.PrimaryKeyRelatedField(
        source="trainer",
        queryset=Trainer.objects.all(),
        write_only=True,
        required=True,
    )
    place_id = serializers.PrimaryKeyRelatedField(
        source="place",
        queryset=Place.objects.all(),
        write_only=True,
        required=True,
    )

    class Meta:
        model = SessionSlot
        fields = [
            "id",
            "trainer",
            "trainer_id",
            "place",
            "place_id",
            "start",
            "end",
            "capacity",
            "is_active",
            "seats_left",
        ]

    def get_seats_left(self, obj: SessionSlot) -> int:
        return obj.seats_left()


class BookingSerializer(serializers.ModelSerializer):
    slot = SessionSlotSerializer(read_only=True)
    slot_id = serializers.PrimaryKeyRelatedField(
        source="slot",
        queryset=SessionSlot.objects.select_related("trainer", "place"),
        write_only=True,
        required=True,
    )

    class Meta:
        model = Booking
        fields = ["id", "slot", "slot_id", "status", "created_at", "updated_at"]
        read_only_fields = ["status", "created_at", "updated_at"]

    def validate_slot(self, slot: SessionSlot) -> SessionSlot:
        request = self.context.get("request")
        user = getattr(request, "user", None)
        if slot.start < timezone.now():
            raise serializers.ValidationError("This slot has already started.")
        if slot.seats_left() <= 0:
            raise serializers.ValidationError("This slot is already full.")
        if user and Booking.objects.filter(
            user=user,
            slot=slot,
            status=Booking.Status.BOOKED,
        ).exists():
            raise serializers.ValidationError("You already booked this slot.")
        return slot

    def create(self, validated_data: dict[str, Any]) -> Booking:
        request = self.context.get("request")
        user = validated_data.pop("user", None) or getattr(request, "user", None)
        slot: SessionSlot = validated_data["slot"]
        booking, created = Booking.objects.get_or_create(user=user, slot=slot)
        if not created and booking.status == Booking.Status.CANCELLED:
            booking.status = Booking.Status.BOOKED
            booking.save(update_fields=["status", "updated_at"])
        return booking


class WishlistItemSerializer(serializers.ModelSerializer):
    kind = serializers.SerializerMethodField()
    place = PlaceSummarySerializer(read_only=True)
    trainer = TrainerSummarySerializer(read_only=True)

    class Meta:
        model = WishlistItem
        fields = ["id", "kind", "place", "trainer", "created_at"]

    def get_kind(self, obj: WishlistItem) -> str:
        return "place" if obj.place_id else "trainer"


class CollectionItemSerializer(serializers.ModelSerializer):
    place = PlaceSummarySerializer(read_only=True)

    class Meta:
        model = CollectionItem
        fields = ["id", "place", "added_at"]


class WishlistCollectionSerializer(serializers.ModelSerializer):
    items = CollectionItemSerializer(many=True, read_only=True)

    class Meta:
        model = WishlistCollection
        fields = ["id", "name", "description", "created_at", "items"]


class PlaceReviewSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)

    class Meta:
        model = PlaceReview
        fields = ["id", "user", "rating", "body", "created_at", "place_id"]
        read_only_fields = ["id", "user", "created_at", "place_id"]

    def create(self, validated_data: dict[str, Any]) -> PlaceReview:
        request = self.context.get("request")
        user = getattr(request, "user", None)
        place: Place = self.context["place"]
        return PlaceReview.objects.create(user=user, place=place, **validated_data)


from __future__ import annotations
import json
import time
from django.contrib import messages
from django.contrib.auth import login, logout
from django.contrib.auth.decorators import login_required, user_passes_test
from django.contrib.auth.views import PasswordChangeView
from django.core.cache import cache
from django.core.paginator import Paginator
from django.http import HttpRequest, JsonResponse
from django.shortcuts import get_object_or_404, redirect, render
from django.urls import reverse_lazy
from django.utils import timezone
from django.views.decorators.http import require_GET, require_POST
from django.views.decorators.csrf import csrf_exempt

from reviews.models import Review
from scheduling.forms import SessionSlotForm, TrainerForm
from scheduling.models import Booking, SessionSlot, Trainer
from places.models import Place
from .models import ActivityLog, CollectionItem, User, WishlistCollection, WishlistItem
from .forms import (
    AccessiblePasswordChangeForm,
    AdminPlaceForm,
    AdminUserCreationForm,
    LoginForm,
    ProfileForm,
    RegisterForm,
)

# ============================================================
# ⚙️ CONFIG
# ============================================================

THROTTLE_LIMIT = 5
THROTTLE_TIMEOUT = 600
THROTTLE_DELAY = 2


def is_admin(user: User) -> bool:
    return user.is_authenticated and user.is_admin


# ============================================================
# 🧡 WISHLIST & COLLECTION
# ============================================================

@login_required
def wishlist_page(request):
    collections = (
        WishlistCollection.objects.filter(user=request.user)
        .prefetch_related("items__place")
        .order_by("name")
    )
    return render(request, "accounts/wishlist_page.html", {"collections": collections})


@login_required
def wishlist_collection_detail(request, pk):
    collection = get_object_or_404(WishlistCollection, pk=pk, user=request.user)
    items = collection.items.select_related("place")
    return render(
        request,
        "accounts/wishlist_collection_detail.html",
        {"collection": collection, "items": items},
    )


@csrf_exempt
@login_required
@require_POST
def delete_collection_view(request, pk):
    """Delete an entire wishlist collection."""
    try:
        collection = get_object_or_404(WishlistCollection, pk=pk, user=request.user)
        collection.delete()
        return JsonResponse({"success": True})
    except Exception as e:
        print("❌ ERROR deleting collection:", e)
        return JsonResponse({"error": str(e)}, status=400)


@csrf_exempt
@login_required
@require_POST
def delete_collection_item_view(request, pk):
    """Delete a specific item from a user's collection."""
    try:
        item = get_object_or_404(CollectionItem, pk=pk, collection__user=request.user)
        item.delete()
        return JsonResponse({"success": True})
    except Exception as e:
        print("❌ ERROR deleting collection item:", e)
        return JsonResponse({"error": str(e)}, status=400)


@login_required
@require_GET
def get_user_collections(request):
    collections = (
        WishlistCollection.objects.filter(user=request.user)
        .order_by("name")
        .values("id", "name")
    )
    return JsonResponse({"collections": list(collections)})


@login_required
@csrf_exempt
def create_collection_view(request):
    """Create a new collection and optionally add a place to it."""
    if request.method != "POST":
        return JsonResponse({"error": "Invalid request method"}, status=405)

    try:
        data = json.loads(request.body.decode("utf-8"))
    except Exception:
        return JsonResponse({"error": "Invalid JSON"}, status=400)

    name = data.get("name")
    description = data.get("description", "")
    place_id = data.get("place_id")

    if not name:
        return JsonResponse({"error": "Collection name required."}, status=400)

    collection, _ = WishlistCollection.objects.get_or_create(
        user=request.user, name=name, defaults={"description": description}
    )

    if place_id:
        try:
            place = get_object_or_404(Place, pk=place_id)
            CollectionItem.objects.get_or_create(collection=collection, place=place)
            WishlistItem.objects.get_or_create(user=request.user, place=place)
        except Exception:
            return JsonResponse({"error": "Invalid place_id"}, status=400)

    return JsonResponse(
        {"status": "added", "collection": {"id": collection.id, "name": collection.name}}
    )


@login_required
@csrf_exempt
def add_to_collection_view(request):
    """Add a place to an existing collection."""
    if request.method != "POST":
        return JsonResponse({"error": "Invalid request method"}, status=405)

    try:
        data = json.loads(request.body.decode("utf-8"))
    except Exception:
        return JsonResponse({"error": "Invalid JSON"}, status=400)

    collection_id = data.get("collection_id")
    place_id = data.get("place_id")

    if not collection_id or not place_id:
        return JsonResponse({"error": "Missing collection_id or place_id"}, status=400)

    collection = get_object_or_404(WishlistCollection, pk=collection_id, user=request.user)
    place = get_object_or_404(Place, pk=place_id)

    CollectionItem.objects.get_or_create(collection=collection, place=place)
    WishlistItem.objects.get_or_create(user=request.user, place=place)
    return JsonResponse(
        {"status": "added", "collection": {"id": collection.id, "name": collection.name}}
    )


# ============================================================
# 👤 AUTH, LOGIN, REGISTER, PROFILE
# ============================================================

def register_view(request):
    if request.user.is_authenticated:
        return redirect("accounts:profile")
    form = RegisterForm(request.POST or None, request.FILES or None)
    if request.method == "POST" and form.is_valid():
        user = form.save()
        login(request, user)
        ActivityLog.objects.create(user=user, type=ActivityLog.Types.LOGIN)
        messages.success(request, "Welcome to FitMatrix! Your account is ready.")
        return redirect("accounts:profile")
    return render(request, "accounts/register.html", {"form": form})


def _throttle_key(identifier: str, request: HttpRequest) -> str:
    client_id = request.META.get("REMOTE_ADDR", "unknown")
    return f"login_attempts:{identifier.lower()}:{client_id}"


def login_view(request):
    if request.user.is_authenticated:
        return redirect("accounts:profile")
    form = LoginForm(request.POST or None)
    throttle_identifier = request.POST.get("identifier", "")
    key = _throttle_key(throttle_identifier, request)
    attempts = cache.get(key, 0)
    if request.method == "POST":
        if attempts >= THROTTLE_LIMIT:
            time.sleep(THROTTLE_DELAY)
            form.add_error(None, "Invalid credentials.")
        elif form.is_valid():
            user = form.get_user()
            if user:
                login(request, user)
                cache.delete(key)
                ActivityLog.objects.create(user=user, type=ActivityLog.Types.LOGIN)
                messages.success(request, "You are logged in.")
                return redirect("accounts:profile")
        else:
            cache.set(key, attempts + 1, THROTTLE_TIMEOUT)
            if attempts + 1 >= THROTTLE_LIMIT:
                time.sleep(THROTTLE_DELAY)
    return render(request, "accounts/login.html", {"form": form, "throttled": attempts >= THROTTLE_LIMIT})


@require_POST
@login_required
def logout_view(request):
    ActivityLog.objects.create(user=request.user, type=ActivityLog.Types.LOGOUT)
    logout(request)
    messages.info(request, "You have been logged out.")
    return redirect("accounts:login")


@login_required
def profile_view(request):
    now = timezone.now()
    bookings = (
        Booking.objects.filter(user=request.user)
        .select_related("slot__trainer", "slot__place")
        .order_by("-slot__start")
    )
    current_booking = bookings.filter(
        slot__start__lte=now,
        slot__end__gte=now,
        status=Booking.Status.BOOKED,
    ).first()
    past_bookings = bookings.filter(slot__end__lt=now)
    activity_page = Paginator(ActivityLog.objects.filter(user=request.user), 10).get_page(request.GET.get("page"))
    wishlist_qs = (
        WishlistItem.objects.filter(user=request.user)
        .select_related("place", "trainer")
        .order_by("-created_at")
    )
    wishlist_page = Paginator(wishlist_qs, 12).get_page(request.GET.get("wishlist_page"))
    reviews = Review.objects.filter(user=request.user).select_related("trainer")
    profile_form = ProfileForm(instance=request.user)
    password_form = AccessiblePasswordChangeForm(user=request.user)
    return render(
        request,
        "accounts/profile.html",
        {
            "current_booking": current_booking,
            "past_bookings": past_bookings,
            "activity_page": activity_page,
            "wishlist_page": wishlist_page,
            "reviews": reviews,
            "profile_form": profile_form,
            "password_form": password_form,
        },
    )


@login_required
def profile_edit_view(request):
    user = request.user
    form = ProfileForm(request.POST or None, request.FILES or None, instance=user)
    if request.method == "POST" and form.is_valid():
        form.save()
        ActivityLog.objects.create(user=user, type=ActivityLog.Types.PROFILE_UPDATED)
        messages.success(request, "Profile updated successfully.")
        return redirect("accounts:profile")
    return render(request, "accounts/profile_edit.html", {"form": form})


# ============================================================
# 🔒 PASSWORD CHANGE VIEW
# ============================================================

class DashboardPasswordChangeView(PasswordChangeView):
    form_class = AccessiblePasswordChangeForm
    template_name = "accounts/password_change.html"
    success_url = reverse_lazy("accounts:profile")

    def form_valid(self, form: AccessiblePasswordChangeForm):
        response = super().form_valid(form)
        ActivityLog.objects.create(
            user=self.request.user,
            type=ActivityLog.Types.PASSWORD_CHANGED
        )
        messages.success(self.request, "Password updated successfully.")
        return response


# ============================================================
# 📜 ACTIVITY HISTORY VIEW
# ============================================================

@login_required
@require_GET
def activity_history_view(request):
    logs = ActivityLog.objects.filter(user=request.user).order_by("-timestamp")
    page_obj = Paginator(logs, 20).get_page(request.GET.get("page"))
    return render(request, "accounts/activity_history.html", {"page_obj": page_obj})

# ============================================================
# 🧠 ADMIN AREA
# ============================================================

@user_passes_test(is_admin)
def admin_console_view(request):
    total_users = User.objects.count()
    total_bookings = Booking.objects.count()
    total_places = Place.objects.count()
    total_trainers = Trainer.objects.count()
    upcoming_slots = SessionSlot.objects.filter(start__gte=timezone.now()).count()
    return render(request, "accounts/admin/console.html", {
        "total_users": total_users,
        "total_bookings": total_bookings,
        "total_places": total_places,
        "total_trainers": total_trainers,
        "upcoming_slots": upcoming_slots,
    })


@user_passes_test(is_admin)
def admin_users_list(request):
    admins = User.objects.filter(role=User.Roles.ADMIN).order_by("username")
    form = AdminUserCreationForm(request.POST or None)
    if request.method == "POST" and form.is_valid():
        new_admin = form.save()
        messages.success(request, f"Admin account '{new_admin.username}' created successfully.")
        return redirect("accounts:admin-users")
    return render(request, "accounts/admin/admins_list.html", {"admins": admins, "form": form})


@user_passes_test(is_admin)
def admin_places_list(request):
    places = Place.objects.order_by("name")
    return render(request, "accounts/admin/places_list.html", {"places": places})


@user_passes_test(is_admin)
def admin_place_create(request):
    form = AdminPlaceForm(request.POST or None)
    if request.method == "POST" and form.is_valid():
        form.save()
        messages.success(request, "Place created successfully.")
        return redirect("accounts:admin-places")
    return render(request, "accounts/admin/place_form.html", {"form": form})


@user_passes_test(is_admin)
def admin_place_edit(request, pk):
    place = get_object_or_404(Place, pk=pk)
    form = AdminPlaceForm(request.POST or None, instance=place)
    if request.method == "POST" and form.is_valid():
        form.save()
        messages.success(request, "Place updated successfully.")
        return redirect("accounts:admin-places")
    return render(request, "accounts/admin/place_form.html", {"form": form, "place": place})


@user_passes_test(is_admin)
@require_POST
def admin_place_delete(request, pk):
    place = get_object_or_404(Place, pk=pk)
    place.delete()
    messages.info(request, "Place deleted.")
    return redirect("accounts:admin-places")


@user_passes_test(is_admin)
@require_POST
def admin_place_toggle(request, pk):
    place = get_object_or_404(Place, pk=pk)
    place.is_active = not place.is_active
    place.save(update_fields=["is_active"])
    messages.success(request, "Place status updated.")
    return redirect("accounts:admin-places")


@user_passes_test(is_admin)
def admin_trainers_list(request):
    trainers = Trainer.objects.order_by("name")
    return render(request, "accounts/admin/trainers_list.html", {"trainers": trainers})


@user_passes_test(is_admin)
def admin_trainer_create(request):
    form = TrainerForm(request.POST or None)
    if request.method == "POST" and form.is_valid():
        form.save()
        messages.success(request, "Trainer created successfully.")
        return redirect("accounts:admin-trainers")
    return render(request, "accounts/admin/trainer_form.html", {"form": form})


@user_passes_test(is_admin)
def admin_trainer_edit(request, pk):
    trainer = get_object_or_404(Trainer, pk=pk)
    form = TrainerForm(request.POST or None, instance=trainer)
    if request.method == "POST" and form.is_valid():
        form.save()
        messages.success(request, "Trainer updated successfully.")
        return redirect("accounts:admin-trainers")
    return render(request, "accounts/admin/trainer_form.html", {"form": form, "trainer": trainer})


@user_passes_test(is_admin)
@require_POST
def admin_trainer_toggle(request, pk):
    trainer = get_object_or_404(Trainer, pk=pk)
    trainer.is_active = not trainer.is_active
    trainer.save(update_fields=["is_active"])
    messages.info(request, "Trainer visibility toggled.")
    return redirect("accounts:admin-trainers")


@user_passes_test(is_admin)
def admin_slots_list(request):
    slots = SessionSlot.objects.select_related("trainer", "place").order_by("start")
    return render(request, "accounts/admin/slots_list.html", {"slots": slots})


@user_passes_test(is_admin)
def admin_slot_create(request):
    form = SessionSlotForm(request.POST or None)
    if request.method == "POST" and form.is_valid():
        form.save()
        messages.success(request, "Session slot created.")
        return redirect("accounts:admin-slots")
    return render(request, "accounts/admin/slot_form.html", {"form": form})


@user_passes_test(is_admin)
def admin_slot_edit(request, pk):
    slot = get_object_or_404(SessionSlot, pk=pk)
    form = SessionSlotForm(request.POST or None, instance=slot)
    if request.method == "POST" and form.is_valid():
        form.save()
        messages.success(request, "Session slot updated.")
        return redirect("accounts:admin-slots")
    return render(request, "accounts/admin/slot_form.html", {"form": form, "slot": slot})


@user_passes_test(is_admin)
@require_POST
def admin_slot_toggle(request, pk):
    slot = get_object_or_404(SessionSlot, pk=pk)
    slot.is_active = not slot.is_active
    slot.save(update_fields=["is_active"])
    messages.info(request, "Slot status toggled.")
    return redirect("accounts:admin-slots")


@user_passes_test(is_admin)
def admin_bookings_list(request):
    bookings = (
        Booking.objects.select_related("user", "slot__trainer", "slot__place")
        .order_by("-created_at")
    )
    return render(request, "accounts/admin/bookings_list.html", {"bookings": bookings})


@user_passes_test(is_admin)
@require_POST
def admin_booking_cancel(request, pk):
    booking = get_object_or_404(Booking, pk=pk)
    if booking.status == Booking.Status.CANCELLED:
        messages.warning(request, "Booking already cancelled.")
    else:
        booking.cancel(by_admin=True)
        messages.success(request, "Booking cancelled.")
    return redirect("accounts:admin-bookings")


@user_passes_test(is_admin)
def admin_reviews_list(request):
    reviews = Review.objects.select_related("trainer", "user", "booking")
    return render(request, "accounts/admin/reviews_list.html", {"reviews": reviews})


@user_passes_test(is_admin)
@require_POST
def admin_review_toggle(request, pk):
    review = get_object_or_404(Review, pk=pk)
    review.is_visible = not review.is_visible
    review.save(update_fields=["is_visible"])
    messages.info(request, "Review visibility updated.")
    return redirect("accounts:admin-reviews")
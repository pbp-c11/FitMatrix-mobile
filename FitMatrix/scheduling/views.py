from __future__ import annotations

from django.contrib import messages
from django.contrib.auth.decorators import login_required
from django.db.models import Count, Min, Q
from django.http import HttpRequest, HttpResponse
from django.shortcuts import get_object_or_404, redirect, render
from django.utils import timezone
from django.views.decorators.http import require_POST

from accounts.models import WishlistItem
from reviews.models import Review

from .forms import BookingRequestForm, BookingRescheduleForm
from .models import Booking, SessionSlot, Trainer


def trainer_list(request: HttpRequest) -> HttpResponse:
    query = request.GET.get("q", "").strip()
    focus = request.GET.get("focus", "").strip()

    trainers = Trainer.objects.filter(is_active=True)
    if query:
        trainers = trainers.filter(Q(name__icontains=query) | Q(specialties__icontains=query))
    if focus:
        trainers = trainers.filter(specialties__icontains=focus)

    trainers = trainers.annotate(
        next_available=Min("slots__start"),
        active_slots=Count("slots", filter=Q(slots__start__gte=timezone.now(), slots__is_active=True)),
    ).order_by("-likes", "-rating_avg", "name")

    wishlist_trainers: set[int] = set()
    if request.user.is_authenticated:
        wishlist_trainers = set(
            WishlistItem.objects.filter(user=request.user, trainer__isnull=False).values_list("trainer_id", flat=True)
        )

    context = {
        "trainers": trainers,
        "query": query,
        "focus": focus,
        "wishlist_trainers": wishlist_trainers,
    }
    return render(request, "scheduling/trainers.html", context)


def trainer_detail(request: HttpRequest, pk: int) -> HttpResponse:
    trainer = get_object_or_404(Trainer, pk=pk, is_active=True)
    upcoming_slots = (
        trainer.slots.filter(is_active=True, start__gte=timezone.now())
        .select_related("place")
        .order_by("start")
    )
    is_favorite = False
    if request.user.is_authenticated:
        is_favorite = WishlistItem.objects.filter(user=request.user, trainer=trainer).exists()
    reviews = (
        Review.objects.filter(trainer=trainer, is_visible=True)
        .select_related("user")
        .order_by("-created_at")
    )
    context = {
        "trainer": trainer,
        "upcoming_slots": upcoming_slots,
        "is_favorite": is_favorite,
        "reviews": reviews,
    }
    return render(request, "scheduling/trainer_detail.html", context)


@login_required
@require_POST
def booking_create(request: HttpRequest, pk: int) -> HttpResponse:
    slot = get_object_or_404(SessionSlot, pk=pk, is_active=True)
    form = BookingRequestForm(request.user, request.POST)
    if form.is_valid():
        slot = form.cleaned_data["slot"]
        booking, created = Booking.objects.get_or_create(user=request.user, slot=slot)
        if not created and booking.status == Booking.Status.CANCELLED:
            booking.status = Booking.Status.BOOKED
            booking.save(update_fields=["status", "updated_at"])
        elif not created:
            messages.error(request, "Unable to book this slot.")
            return redirect("scheduling:trainer-detail", pk=slot.trainer_id)
        messages.success(
            request,
            f"Session with {booking.slot.trainer.name} on {timezone.localtime(booking.slot.start):%d %b %H:%M} confirmed.",
        )
        return redirect("scheduling:booking-manage")
    errors = ", ".join(form.errors.get("slot", [])) or "Unable to book this slot."
    messages.error(request, errors)
    return redirect("scheduling:trainer-detail", pk=slot.trainer_id)


@login_required
def booking_manage(request: HttpRequest) -> HttpResponse:
    bookings = list(
        Booking.objects.select_related("slot__trainer", "slot__place", "review")
        .filter(user=request.user)
        .order_by("-slot__start")
    )
    now = timezone.now()
    for booking in bookings:
        if booking.status == Booking.Status.BOOKED and booking.slot.end < now:
            booking.status = Booking.Status.COMPLETED
            booking.save(update_fields=["status", "updated_at"])
    upcoming = [b for b in bookings if b.status == Booking.Status.BOOKED and b.slot.start >= now]
    past = [b for b in bookings if b.slot.start < now]
    context = {
        "upcoming": upcoming,
        "past": past,
    }
    return render(request, "scheduling/manage.html", context)


@login_required
@require_POST
def booking_cancel(request: HttpRequest, pk: int) -> HttpResponse:
    booking = get_object_or_404(Booking, pk=pk, user=request.user)
    if booking.status == Booking.Status.CANCELLED:
        messages.info(request, "Booking was already cancelled.")
    else:
        booking.cancel()
        messages.success(request, "Booking cancelled.")
    return redirect("scheduling:booking-manage")


@login_required
def booking_reschedule(request: HttpRequest, pk: int) -> HttpResponse:
    booking = get_object_or_404(Booking, pk=pk, user=request.user)
    if booking.status == Booking.Status.CANCELLED:
        messages.error(request, "Cannot reschedule a cancelled booking.")
        return redirect("scheduling:booking-manage")
    if request.method == "POST":
        form = BookingRescheduleForm(booking, request.POST)
        if form.is_valid():
            new_slot = form.cleaned_data["new_slot"]
            booking.slot = new_slot
            booking.status = Booking.Status.BOOKED
            booking.save(update_fields=["slot", "status", "updated_at"])
            messages.success(request, "Booking rescheduled successfully.")
            return redirect("scheduling:booking-manage")
    else:
        form = BookingRescheduleForm(booking)
    context = {
        "booking": booking,
        "form": form,
    }
    return render(request, "scheduling/reschedule.html", context)


def upcoming_sessions(request: HttpRequest) -> HttpResponse:
    query = request.GET.get("q", "").strip()
    slots_qs = SessionSlot.objects.select_related("trainer", "place").filter(
        is_active=True,
        start__gte=timezone.now(),
    )
    if query:
        slots_qs = slots_qs.filter(
            Q(trainer__name__icontains=query)
            | Q(place__name__icontains=query)
            | Q(place__city__icontains=query)
        )
    slots = list(slots_qs.order_by("start"))
    booked_slot_ids: set[int] = set()
    if request.user.is_authenticated:
        booked_slot_ids = set(
            Booking.objects.filter(
                user=request.user,
                slot__in=[slot.pk for slot in slots],
                status=Booking.Status.BOOKED,
            ).values_list("slot_id", flat=True)
        )
    context = {
        "slots": slots,
        "query": query,
        "booked_slot_ids": booked_slot_ids,
    }
    return render(request, "scheduling/sessions.html", context)

from __future__ import annotations

from datetime import timedelta

from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from django.test import TestCase
from django.urls import reverse
from django.utils import timezone

from accounts.models import ActivityLog
from places.models import Place
from scheduling.forms import BookingRequestForm
from scheduling.models import Booking, SessionSlot, Trainer

User = get_user_model()


class BookingRulesTests(TestCase):
    def setUp(self) -> None:
        self.user = User.objects.create_user(
            username="user1",
            email="user1@example.com",
            password="Testpass123!",
        )
        self.user2 = User.objects.create_user(
            username="user2",
            email="user2@example.com",
            password="Testpass123!",
        )
        self.trainer = Trainer.objects.create(name="Coach", specialties="Strength", bio="")
        self.place = Place.objects.create(
            name="Gym",
            address="Jl. Asia Afrika",
            city="Jakarta",
            is_free=True,
        )
        start = timezone.now() + timedelta(days=1)
        end = start + timedelta(hours=1)
        self.slot = SessionSlot.objects.create(
            trainer=self.trainer,
            place=self.place,
            start=start,
            end=end,
            capacity=1,
        )

    def test_unique_booking_per_user_slot(self) -> None:
        Booking.objects.create(user=self.user, slot=self.slot)
        with self.assertRaises(ValidationError):
            Booking(user=self.user, slot=self.slot).save()

    def test_capacity_enforced(self) -> None:
        Booking.objects.create(user=self.user, slot=self.slot)
        with self.assertRaises(ValidationError):
            Booking.objects.create(user=self.user2, slot=self.slot)

    def test_cancel_restores_capacity_and_logs(self) -> None:
        booking = Booking.objects.create(user=self.user, slot=self.slot)
        self.assertEqual(self.slot.seats_left(), 0)
        booking.cancel()
        self.assertEqual(self.slot.seats_left(), 1)
        self.assertTrue(
            ActivityLog.objects.filter(
                user=self.user, type=ActivityLog.Types.BOOKING_CANCELLED
            ).exists()
        )

    def test_cancel_by_admin_sets_flag_once(self) -> None:
        booking = Booking.objects.create(user=self.user, slot=self.slot)
        booking.cancel(by_admin=True)
        logs = ActivityLog.objects.filter(
            user=self.user,
            type=ActivityLog.Types.BOOKING_CANCELLED,
            meta__by_admin=True,
        )
        self.assertEqual(logs.count(), 1)
        # cancelling again should be a no-op
        booking.cancel(by_admin=True)
        self.assertEqual(logs.count(), 1)

    def test_can_rebook_cancelled_slot(self) -> None:
        booking = Booking.objects.create(user=self.user, slot=self.slot)
        booking.cancel()
        form = BookingRequestForm(self.user, data={"slot": self.slot.pk})
        self.assertTrue(form.is_valid())

    def test_booking_create_reactivates_cancelled_booking(self) -> None:
        booking = Booking.objects.create(user=self.user, slot=self.slot)
        booking.cancel()
        self.client.login(username="user1", password="Testpass123!")
        response = self.client.post(
            reverse("scheduling:booking-create", args=[self.slot.pk]),
            {"slot": self.slot.pk},
            follow=True,
        )
        self.assertRedirects(response, reverse("scheduling:booking-manage"))
        booking.refresh_from_db()
        self.assertEqual(booking.status, Booking.Status.BOOKED)
        self.assertEqual(
            Booking.objects.filter(user=self.user, slot=self.slot).count(),
            1,
        )

    def test_session_slot_validation_rules(self) -> None:
        with self.assertRaises(ValidationError):
            SessionSlot(
                trainer=self.trainer,
                place=self.place,
                start=self.slot.start,
                end=self.slot.start,
                capacity=1,
            ).full_clean()
        with self.assertRaises(ValidationError):
            SessionSlot(
                trainer=self.trainer,
                place=self.place,
                start=self.slot.start,
                end=self.slot.end,
                capacity=0,
            ).full_clean()

    def test_booking_creation_logs_activity(self) -> None:
        booking = Booking.objects.create(user=self.user, slot=self.slot)
        log = ActivityLog.objects.get(
            user=self.user,
            type=ActivityLog.Types.BOOKING_CREATED,
        )
        self.assertEqual(log.meta["booking_id"], booking.pk)

    def test_sessions_view_marks_cancelled_slot_as_available(self) -> None:
        booking = Booking.objects.create(user=self.user, slot=self.slot)
        booking.cancel()

        self.client.login(username="user1", password="Testpass123!")
        response = self.client.get(reverse("scheduling:sessions"))

        self.assertNotIn(self.slot.pk, response.context["booked_slot_ids"])
        self.assertContains(response, "Book slot")

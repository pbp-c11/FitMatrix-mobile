from __future__ import annotations

from datetime import timedelta
from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.test import TestCase
from django.utils import timezone

from places.models import Place
from scheduling.forms import (
    BookingRequestForm,
    BookingRescheduleForm,
    SessionSlotForm,
)
from scheduling.models import Booking, SessionSlot, Trainer

User = get_user_model()


class SchedulingFormTests(TestCase):
    def setUp(self) -> None:
        self.user = User.objects.create_user(
            username="member",
            email="member@example.com",
            password="Pass12345!",
        )
        self.other_user = User.objects.create_user(
            username="friend",
            email="friend@example.com",
            password="Pass12345!",
        )
        self.trainer = Trainer.objects.create(name="Coach A", specialties="Yoga")
        self.place = Place.objects.create(
            name="Calm Studio",
            address="Jl. Kenanga",
            city="Jakarta",
            is_free=True,
        )

    def test_session_slot_form_rejects_invalid_times(self) -> None:
        start = timezone.now() + timedelta(days=1)
        with patch.object(SessionSlot, "clean", autospec=True, return_value=None):
            form = SessionSlotForm(
                data={
                    "trainer": self.trainer.pk,
                    "place": self.place.pk,
                    "start": start.isoformat(),
                    "end": start.isoformat(),
                    "capacity": 5,
                    "is_active": True,
                }
            )
            self.assertFalse(form.is_valid())
        self.assertIn("End time must be after start time.", form.errors["end"])

    def test_booking_request_form_filters_active_slots(self) -> None:
        start = timezone.now() + timedelta(days=1)
        active_slot = SessionSlot.objects.create(
            trainer=self.trainer,
            place=self.place,
            start=start,
            end=start + timedelta(hours=1),
            capacity=2,
            is_active=True,
        )
        SessionSlot.objects.create(
            trainer=self.trainer,
            place=self.place,
            start=start + timedelta(hours=2),
            end=start + timedelta(hours=3),
            capacity=2,
            is_active=False,
        )
        form = BookingRequestForm(self.user)
        queryset = list(form.fields["slot"].queryset)
        self.assertEqual(queryset, [active_slot])

    def test_booking_request_form_validates_slot_rules(self) -> None:
        past_slot = SessionSlot.objects.create(
            trainer=self.trainer,
            place=self.place,
            start=timezone.now() - timedelta(hours=2),
            end=timezone.now() - timedelta(hours=1),
            capacity=1,
        )
        form = BookingRequestForm(self.user, data={"slot": past_slot.pk})
        self.assertFalse(form.is_valid())
        self.assertIn("This slot has already started.", form.errors["slot"])

        future_slot_full = SessionSlot.objects.create(
            trainer=self.trainer,
            place=self.place,
            start=timezone.now() + timedelta(days=1),
            end=timezone.now() + timedelta(days=1, hours=1),
            capacity=1,
        )
        Booking.objects.create(user=self.other_user, slot=future_slot_full)
        form = BookingRequestForm(self.user, data={"slot": future_slot_full.pk})
        self.assertFalse(form.is_valid())
        self.assertIn("This slot is fully booked.", form.errors["slot"])

        future_slot_user = SessionSlot.objects.create(
            trainer=self.trainer,
            place=self.place,
            start=timezone.now() + timedelta(days=2),
            end=timezone.now() + timedelta(days=2, hours=1),
            capacity=2,
        )
        Booking.objects.create(user=self.user, slot=future_slot_user, status=Booking.Status.BOOKED)
        form = BookingRequestForm(self.user, data={"slot": future_slot_user.pk})
        self.assertFalse(form.is_valid())
        self.assertIn("You have already booked this slot.", form.errors["slot"])

    def test_booking_reschedule_form_validations(self) -> None:
        start = timezone.now() + timedelta(days=3)
        slot = SessionSlot.objects.create(
            trainer=self.trainer,
            place=self.place,
            start=start,
            end=start + timedelta(hours=1),
            capacity=2,
        )
        booking = Booking.objects.create(user=self.user, slot=slot)
        alternative = SessionSlot.objects.create(
            trainer=self.trainer,
            place=self.place,
            start=start + timedelta(days=1),
            end=start + timedelta(days=1, hours=1),
            capacity=1,
        )
        full_slot = SessionSlot.objects.create(
            trainer=self.trainer,
            place=self.place,
            start=start + timedelta(days=2),
            end=start + timedelta(days=2, hours=1),
            capacity=1,
        )
        Booking.objects.create(user=self.other_user, slot=full_slot)

        form = BookingRescheduleForm(booking)
        queryset = list(form.fields["new_slot"].queryset)
        self.assertIn(alternative, queryset)
        self.assertNotIn(slot, queryset)

        form = BookingRescheduleForm(booking, data={"new_slot": full_slot.pk})
        self.assertFalse(form.is_valid())
        self.assertIn("Selected slot is already full.", form.errors["new_slot"])

        duplicate_slot = SessionSlot.objects.create(
            trainer=self.trainer,
            place=self.place,
            start=start + timedelta(days=3),
            end=start + timedelta(days=3, hours=1),
            capacity=2,
        )
        Booking.objects.create(user=self.user, slot=duplicate_slot)
        form = BookingRescheduleForm(booking, data={"new_slot": duplicate_slot.pk})
        self.assertFalse(form.is_valid())
        self.assertIn("You already have this slot booked.", form.errors["new_slot"])

        form = BookingRescheduleForm(booking, data={"new_slot": alternative.pk})
        self.assertTrue(form.is_valid())
        self.assertEqual(form.clean_new_slot(), alternative)

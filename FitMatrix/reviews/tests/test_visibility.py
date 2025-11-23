from __future__ import annotations

from datetime import timedelta

from django.contrib.auth import get_user_model
from django.test import TestCase
from django.utils import timezone

from places.models import Place
from reviews.models import Review
from scheduling.models import Booking, SessionSlot, Trainer

User = get_user_model()


class ReviewVisibilityTests(TestCase):
    def setUp(self) -> None:
        self.user = User.objects.create_user(
            username="reviewer",
            email="reviewer@example.com",
            password="StrongPass123!",
        )
        self.trainer = Trainer.objects.create(name="Guru", specialties="Yoga", bio="")
        self.place = Place.objects.create(
            name="Studio",
            address="Jl. Thamrin",
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
            capacity=5,
        )
        self.booking = Booking.objects.create(user=self.user, slot=self.slot)

    def test_visibility_toggle_updates_rating(self) -> None:
        review = Review.objects.create(
            booking=self.booking,
            user=self.user,
            trainer=self.trainer,
            rating=5,
            comment="Excellent",
        )
        self.trainer.refresh_from_db()
        self.assertEqual(self.trainer.rating_avg, 5)
        review.is_visible = False
        review.save(update_fields=["is_visible"])
        self.trainer.refresh_from_db()
        self.assertEqual(self.trainer.rating_avg, 0)
        review.is_visible = True
        review.rating = 3
        review.save(update_fields=["is_visible", "rating"])
        self.trainer.refresh_from_db()
        self.assertEqual(self.trainer.rating_avg, 3)

    def test_delete_review_updates_trainer_average(self) -> None:
        other_user = User.objects.create_user(
            username="reviewer2",
            email="reviewer2@example.com",
            password="StrongPass123!",
        )
        other_booking = Booking.objects.create(user=other_user, slot=self.slot)
        first = Review.objects.create(
            booking=self.booking,
            user=self.user,
            trainer=self.trainer,
            rating=5,
            comment="Great",
        )
        second = Review.objects.create(
            booking=other_booking,
            user=other_user,
            trainer=self.trainer,
            rating=1,
            comment="Needs work",
        )
        self.trainer.refresh_from_db()
        self.assertEqual(self.trainer.rating_avg, 3)
        second.delete()
        self.trainer.refresh_from_db()
        self.assertEqual(self.trainer.rating_avg, 5)
        first.delete()
        self.trainer.refresh_from_db()
        self.assertEqual(self.trainer.rating_avg, 0)

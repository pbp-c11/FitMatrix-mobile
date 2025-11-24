from __future__ import annotations

from django.contrib.auth import get_user_model
from django.test import TestCase

from places.forms import ReviewForm
from places.models import Place, Review

User = get_user_model()


class ReviewFormTests(TestCase):
    def setUp(self) -> None:
        self.user = User.objects.create_user(
            username="reviewer",
            email="reviewer@example.com",
            password="Pass12345!",
        )
        self.place = Place.objects.create(
            name="Spot A",
            address="Jl. Sudirman",
            city="Jakarta",
            is_free=True,
        )

    def test_form_has_expected_choices_and_widgets(self) -> None:
        form = ReviewForm()
        self.assertEqual(form.fields["rating"].choices[0], (1, "1"))
        self.assertEqual(form.fields["rating"].choices[-1], (5, "5"))
        self.assertIn("matrix-input", form.fields["rating"].widget.attrs.get("class", ""))
        self.assertIn("matrix-input", form.fields["body"].widget.attrs.get("class", ""))

    def test_form_validates_and_saves_review(self) -> None:
        instance = Review(place=self.place, user=self.user)
        form = ReviewForm(
            data={"rating": "4", "body": "Great vibe"},
            instance=instance,
        )
        self.assertTrue(form.is_valid())
        review = form.save()
        self.assertEqual(review.rating, 4)
        self.assertEqual(review.body, "Great vibe")
        self.assertEqual(review.place, self.place)
        self.assertEqual(review.user, self.user)

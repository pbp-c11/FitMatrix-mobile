from __future__ import annotations

from django.contrib.auth import get_user_model
from django.test import TestCase
from django.urls import reverse

from places.models import Place, Review

User = get_user_model()


class PlaceViewTests(TestCase):
    def setUp(self) -> None:
        self.user = User.objects.create_user(
            username="viewer",
            email="viewer@example.com",
            password="Pass12345!",
        )
        self.place = Place.objects.create(
            name="Alpha Studio",
            address="Jl. Melati",
            city="Jakarta",
            is_free=True,
            highlight_score=5,
        )

    def test_place_list_displays_all_places(self) -> None:
        beta = Place.objects.create(
            name="Beta Gym",
            address="Jl. Mawar",
            city="Bandung",
            is_free=False,
        )
        response = self.client.get(reverse("places:list"))
        self.assertEqual(response.status_code, 200)
        places = list(response.context["places"])
        self.assertIn(self.place, places)
        self.assertIn(beta, places)

    def test_place_detail_includes_reviews(self) -> None:
        Review.objects.create(place=self.place, user=self.user, rating=4, body="Nice")
        response = self.client.get(reverse("places:detail", args=[self.place.slug]))
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.context["place"], self.place)
        expected = list(Review.objects.filter(place=self.place).order_by("-created_at"))
        self.assertEqual(list(response.context["reviews"]), expected)

    def test_reviews_partial_returns_fragment(self) -> None:
        response = self.client.get(
            reverse("places:reviews_partial", args=[self.place.slug])
        )
        self.assertEqual(response.status_code, 200)
        self.assertTemplateUsed(response, "places/_reviews.html")

    def test_place_review_create_requires_fields(self) -> None:
        self.client.force_login(self.user)
        response = self.client.post(
            reverse("places:place_review_create", args=[self.place.slug]),
            {"body": "", "rating": ""},
            HTTP_X_REQUESTED_WITH="XMLHttpRequest",
        )
        self.assertEqual(response.status_code, 400)
        self.assertEqual(
            response.json(),
            {"success": False, "error": "Please fill in all fields."},
        )

    def test_place_review_create_rejects_invalid_rating(self) -> None:
        self.client.force_login(self.user)
        response = self.client.post(
            reverse("places:place_review_create", args=[self.place.slug]),
            {"body": "Content", "rating": "bad"},
            HTTP_X_REQUESTED_WITH="XMLHttpRequest",
        )
        self.assertEqual(response.status_code, 400)
        self.assertEqual(
            response.json(),
            {"success": False, "error": "Invalid rating value."},
        )

    def test_place_review_create_requires_authentication(self) -> None:
        response = self.client.post(
            reverse("places:place_review_create", args=[self.place.slug]),
            {"body": "Content", "rating": "5"},
            HTTP_X_REQUESTED_WITH="XMLHttpRequest",
        )
        self.assertEqual(response.status_code, 403)
        self.assertEqual(
            response.json(),
            {"success": False, "error": "You must be logged in."},
        )

    def test_place_review_create_success_ajax(self) -> None:
        self.client.force_login(self.user)
        response = self.client.post(
            reverse("places:place_review_create", args=[self.place.slug]),
            {"body": "Great spot", "rating": "5"},
            HTTP_X_REQUESTED_WITH="XMLHttpRequest",
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertTrue(data["success"])
        self.assertTrue(Review.objects.filter(place=self.place, user=self.user).exists())
        self.place.refresh_from_db()
        self.assertEqual(self.place.rating_avg, 5)

    def test_place_review_create_success_redirect(self) -> None:
        self.client.force_login(self.user)
        response = self.client.post(
            reverse("places:place_review_create", args=[self.place.slug]),
            {"body": "Nice place", "rating": "4"},
        )
        self.assertEqual(response.status_code, 302)
        self.assertEqual(response["Location"], reverse("places:detail", args=[self.place.slug]))

    def test_place_review_create_get_not_allowed(self) -> None:
        response = self.client.get(
            reverse("places:place_review_create", args=[self.place.slug])
        )
        self.assertEqual(response.status_code, 400)
        self.assertEqual(
            response.json(),
            {"success": False, "error": "Invalid request method."},
        )

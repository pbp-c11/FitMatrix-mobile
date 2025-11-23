from __future__ import annotations

from django.contrib.auth import get_user_model
from django.test import TestCase
from django.urls import reverse

from places.models import Place
from reviews.models import Review

User = get_user_model()


class HomeViewTests(TestCase):
    def setUp(self) -> None:
        self.user = User.objects.create_user(
            username="home-user",
            email="home@example.com",
            password="Pass12345!",
        )

    def test_home_view_populates_expected_context(self) -> None:
        trending = Place.objects.create(
            name="Trending Gym",
            address="Jl. Merdeka",
            city="Jakarta",
            is_free=True,
            highlight_score=5,
        )
        for _ in range(10):
            Review.objects.create(place=trending, user=self.user, rating=5)

        spotlight = Place.objects.create(
            name="Spotlight Studio",
            address="Jl. Anggrek",
            city="Bandung",
            is_free=False,
            highlight_score=3,
        )
        newest = Place.objects.create(
            name="Newest Court",
            address="Jl. Melur",
            city="Surabaya",
            is_free=True,
            highlight_score=1,
        )

        response = self.client.get(reverse("home"))
        self.assertEqual(response.status_code, 200)

        summary = response.context["summary"]
        self.assertEqual(summary["place_count"], Place.objects.filter(is_active=True).count())
        self.assertEqual(summary["studio_count"], Place.objects.filter(
            is_active=True, facility_type=Place.FacilityType.STUDIO
        ).count())

        trending_places = list(response.context["trending_places"])
        self.assertIn(trending, trending_places)

        newest_places = list(response.context["newest_places"])
        self.assertIn(newest, newest_places)

        spotlights = list(response.context["spotlights"])
        self.assertIn(spotlight, spotlights)

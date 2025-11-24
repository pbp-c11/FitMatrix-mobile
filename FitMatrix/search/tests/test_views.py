from __future__ import annotations

from django.contrib.auth import get_user_model
from django.test import Client, TestCase
from django.urls import reverse

from places.models import Place

User = get_user_model()


class SearchViewTests(TestCase):
    def setUp(self) -> None:
        self.client = Client()
        self.user = User.objects.create_user(
            username="seeker",
            email="seeker@example.com",
            password="ComplexPass123",
        )
        self.client.force_login(self.user)
        self.alpha = Place.objects.create(
            name="Alpha Gym",
            address="Jl. Melati",
            city="Jakarta",
            facility_type=Place.FacilityType.GYM,
            amenities=["Sauna", "Pool"],
            highlight_score=7,
            rating_avg=4.8,
            likes=100,
        )
        self.beta = Place.objects.create(
            name="Beta Studio",
            address="Jl. Mawar",
            city="Bandung",
            facility_type=Place.FacilityType.STUDIO,
            amenities=["Yoga", "Pilates"],
            highlight_score=5,
            rating_avg=4.6,
            likes=80,
        )

    def test_results_view_filters_city_amenities_and_sort(self) -> None:
        response = self.client.get(
            reverse("search:results"),
            {
                "q": "Alpha",
                "city": "Jakarta",
                "amenities": ["Sauna", "Pool"],
                "sort": "rating",
            },
        )
        self.assertEqual(response.status_code, 200)
        places = list(response.context["places"])
        self.assertEqual(places, [self.alpha])
        self.assertIn("recommended", response.context)

    def test_results_view_ajax_returns_partial_html(self) -> None:
        response = self.client.get(
            reverse("search:results"),
            {"q": "Studio", "type": Place.FacilityType.STUDIO},
            HTTP_X_REQUESTED_WITH="XMLHttpRequest",
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("html", data)
        self.assertEqual(data["count"], 1)
        self.assertIn(self.beta.name, data["html"])

    def test_price_filter_and_radius_keyword(self) -> None:
        gamma = Place.objects.create(
            name="Gamma Court",
            address="Jl. Melur",
            city="Jakarta",
            facility_type=Place.FacilityType.COURT,
            amenities=["Badminton"],
            highlight_score=9,
            rating_avg=4.9,
            likes=150,
            is_free=False,
            price=50000,
        )
        response = self.client.get(
            reverse("search:results"),
            {"q": "court", "price": "budget"},
        )
        self.assertEqual(list(response.context["places"]), [gamma])
        self.assertEqual(response.context["selected_price"], "budget")

    def test_sort_newest_orders_by_creation_time(self) -> None:
        gamma = Place.objects.create(
            name="Gamma Arena",
            address="Jl. Dahlia",
            city="Jakarta",
            facility_type=Place.FacilityType.GYM,
            amenities=["Sauna"],
            highlight_score=2,
            rating_avg=4.0,
            likes=10,
        )
        response = self.client.get(
            reverse("search:results"),
            {"sort": "newest"},
        )
        places = list(response.context["places"])
        self.assertEqual(places[0], gamma)

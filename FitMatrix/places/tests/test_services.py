from __future__ import annotations

from django.test import TestCase

from places.models import Place
from places.services import recommended_places, search_places


class PlaceServiceTests(TestCase):
    def setUp(self) -> None:
        self.gym = Place.objects.create(
            name="Test Gym",
            tagline="Functional gym",
            summary="Strength and conditioning lab.",
            address="Jl. Setiabudi No. 1",
            city="Jakarta",
            facility_type=Place.FacilityType.GYM,
            amenities=["Strength", "Conditioning"],
            highlight_score=8,
            hero_image="media/hero-athlete.jpg",
            price=200000,
            rating_avg=4.7,
            likes=120,
        )
        self.studio = Place.objects.create(
            name="Yoga Studio",
            tagline="Boutique studio",
            summary="Mindful movement.",
            address="Jl. Sudirman No. 2",
            city="Bandung",
            facility_type=Place.FacilityType.STUDIO,
            amenities=["Yoga", "Pilates"],
            highlight_score=6,
            hero_image="media/studio-flow.jpg",
            price=150000,
            rating_avg=4.5,
            likes=80,
        )
        self.pool = Place.objects.create(
            name="Hydro Pool",
            tagline="Aquatic centre",
            summary="Swim training.",
            address="Jl. Thamrin No. 3",
            city="Jakarta",
            facility_type=Place.FacilityType.SWIM,
            amenities=["Pool", "Recovery"],
            highlight_score=9,
            hero_image="media/aqua-circuit.jpg",
            price=300000,
            rating_avg=4.9,
            likes=200,
        )

    def test_search_by_facility_type(self) -> None:
        results = search_places(facility_type=Place.FacilityType.GYM)
        self.assertQuerySetEqual(
            results,
            [self.gym],
            ordered=False,
            transform=lambda x: x,
        )

    def test_search_price_filter_budget(self) -> None:
        results = search_places(price_key="mid")
        self.assertIn(self.studio, results)
        self.assertNotIn(self.pool, results)

    def test_recommended_places_prioritises_highlight(self) -> None:
        results = list(recommended_places())
        self.assertLessEqual(results.index(self.pool), results.index(self.gym))
        self.assertNotIn(self.studio, results[:1])  # lower highlight score

    def test_search_by_amenities_and_city(self) -> None:
        results = search_places(amenities=["Yoga"], city="Bandung")
        self.assertEqual(list(results), [self.studio])

    def test_search_sort_prioritises_highlight_score(self) -> None:
        Place.objects.create(
            name="Newest Gym",
            address="Jl. Sudirman",
            city="Jakarta",
            facility_type=Place.FacilityType.GYM,
            amenities=["Strength"],
            highlight_score=1,
        )
        ordered = list(search_places())
        # ensure default ordering uses highlight then rating/likes
        self.assertEqual(ordered[0], self.pool)

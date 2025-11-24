from __future__ import annotations

from decimal import Decimal

from django.test import TestCase
from django.urls import reverse

from places.models import Place


class PlaceModelTests(TestCase):
    def test_slug_generated_and_unique(self) -> None:
        first = Place.objects.create(
            name="Primal Fit",
            address="Jl. Senayan",
            city="Jakarta",
            is_free=True,
        )
        second = Place.objects.create(
            name="Primal Fit",
            address="Jl. Kemang",
            city="Jakarta",
            is_free=True,
        )
        self.assertTrue(first.slug.startswith("primal-fit"))
        self.assertNotEqual(first.slug, second.slug)

    def test_price_display_variants(self) -> None:
        free = Place.objects.create(
            name="Free Park",
            address="Jl. Merdeka",
            city="Bandung",
            is_free=True,
        )
        priced = Place.objects.create(
            name="Premium Arena",
            address="Jl. Merdeka",
            city="Bandung",
            is_free=False,
            price=250000,
        )
        on_request = Place.objects.create(
            name="VIP Loft",
            address="Jl. Merdeka",
            city="Bandung",
            is_free=False,
        )
        self.assertEqual(free.price_display(), "Free access")
        self.assertEqual(priced.price_display(), "Rp 250.000")
        self.assertEqual(on_request.price_display(), "Pricing on request")

    def test_helpers_for_colors_and_lists(self) -> None:
        place = Place.objects.create(
            name="Color Studio",
            address="Jl. Asia Afrika",
            city="Jakarta",
            is_free=True,
            accent_color="",
            amenities="Sauna, Cold Plunge ,",
            gallery="hero.jpg, detail-1.jpg",
        )
        self.assertEqual(place.primary_color(), "#03B863")
        self.assertEqual(place.amenities_list(), ["Sauna", "Cold Plunge"])
        self.assertEqual(place.gallery_list(), ["hero.jpg", "detail-1.jpg"])

    def test_get_absolute_url_uses_slug(self) -> None:
        place = Place.objects.create(
            name="Navigator Lab",
            address="Jl. Diponegoro",
            city="Surabaya",
            is_free=True,
        )
        url = place.get_absolute_url()
        self.assertEqual(url, reverse("places:detail", kwargs={"slug": place.slug}))

    def test_google_maps_url_requires_coordinates(self) -> None:
        without_coords = Place.objects.create(
            name="No Coordinates",
            address="Jl. Malioboro",
            city="Yogyakarta",
            is_free=True,
        )
        self.assertIsNone(without_coords.google_maps_url())

        with_coords = Place.objects.create(
            name="With Coordinates",
            address="Jl. Malioboro",
            city="Yogyakarta",
            is_free=True,
            latitude=Decimal("-7.793121"),
            longitude=Decimal("110.365776"),
        )
        self.assertEqual(
            with_coords.google_maps_url(),
            "https://www.google.com/maps/search/?api=1&query=-7.793121,110.365776",
        )

    def test_queryset_helpers_chainable(self) -> None:
        amenity_place = Place.objects.create(
            name="Functional Zone",
            address="Jl. Asia Afrika",
            city="Jakarta",
            facility_type=Place.FacilityType.GYM,
            amenities=["Rig", "Rowers"],
            highlight_score=5,
            is_free=False,
            price=150000,
        )
        Place.objects.create(
            name="Yoga Hive",
            address="Jl. Asia Afrika",
            city="Bandung",
            facility_type=Place.FacilityType.STUDIO,
            amenities=["Yoga"],
            highlight_score=1,
            is_free=True,
        )
        results = (
            Place.objects.search("Functional")
            .by_type(Place.FacilityType.GYM)
            .filter(city__icontains="Jakarta")
        )
        self.assertQuerySetEqual(results, [amenity_place], transform=lambda x: x)
        filtered = results.filter(amenities__icontains="Rig")
        self.assertEqual(filtered.count(), 1)

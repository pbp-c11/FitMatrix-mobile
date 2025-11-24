from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable

from django.db.models import F, FloatField, QuerySet, Value
from django.db.models.functions import Coalesce

from .models import Place


@dataclass(frozen=True)
class FacilityFilter:
    key: str
    label: str
    description: str
    accent: str



PRICE_FILTERS = {
    "free": {"label": "Free Access", "predicate": lambda qs: qs.filter(is_free=True)},
    "budget": {
        "label": "Under 100K",
        "predicate": lambda qs: qs.filter(is_free=False, price__lte=100000),
    },
    "mid": {
        "label": "100K - 250K",
        "predicate": lambda qs: qs.filter(is_free=False, price__gte=100000, price__lte=250000),
    },
    "premium": {
        "label": "250K+",
        "predicate": lambda qs: qs.filter(is_free=False, price__gte=250000),
    },
}




def price_filter_options() -> tuple[tuple[str, str], ...]:
    return tuple((key, info["label"]) for key, info in PRICE_FILTERS.items())


def recommended_places(limit: int = 6) -> QuerySet[Place]:
    base = (
        Place.objects.recommendable()
        .annotate(
            weighted_score=Coalesce(
                F("highlight_score") * 1.2
                + Coalesce(F("rating_avg"), Value(0.0), output_field=FloatField()) * 0.5
                + F("likes") * 0.05,
                Value(0.0),
                output_field=FloatField(),
            ),
        )
        .order_by("-weighted_score", "-highlight_score", "-rating_avg", "-likes", "name")
    )
    if limit:
        return base[:limit]
    return base


def spotlight_places(limit: int = 3) -> QuerySet[Place]:
    return Place.objects.active().order_by("-rating_avg", "-likes", "name")[:limit]


def newest_places(limit: int = 6) -> QuerySet[Place]:
    return Place.objects.active().order_by("-created_at")[:limit]


def apply_price_filter(qs: QuerySet[Place], key: str | None) -> QuerySet[Place]:
    if not key:
        return qs
    definition = PRICE_FILTERS.get(key.lower())
    if not definition:
        return qs
    return definition["predicate"](qs)


def search_places(
    *,
    query: str | None = None,
    facility_type: str | None = None,
    city: str | None = None,
    price_key: str | None = None,
    amenities: Iterable[str] | None = None,
) -> QuerySet[Place]:
    qs = Place.objects.active()
    qs = qs.search(query)
    qs = qs.by_type(facility_type)
    qs = apply_price_filter(qs, price_key)
    if city:
        qs = qs.filter(city__icontains=city)
    if amenities:
        for amenity in amenities:
            qs = qs.filter(amenities__icontains=amenity)
    return qs.order_by("-highlight_score", "-rating_avg", "name")

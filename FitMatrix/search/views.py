from __future__ import annotations

from collections.abc import Iterable

from django.http import HttpRequest, HttpResponse, JsonResponse
from django.shortcuts import render
from django.template.loader import render_to_string
from django.views.decorators.http import require_GET

from places.services import (
    price_filter_options,
    recommended_places,
    search_places,
    spotlight_places,
)


def _request_amenities(request: HttpRequest) -> list[str]:
    amenities: Iterable[str] = request.GET.getlist("amenities")
    if not amenities:
        raw = request.GET.get("amenities")
        if raw:
            amenities = [item.strip() for item in raw.split(",")]
    return [item for item in amenities if item]


@require_GET
def results_view(request: HttpRequest) -> HttpResponse:
    query = request.GET.get("q", "").strip()
    facility_type = request.GET.get("type") or request.GET.get("facility_type")
    city = request.GET.get("city", "").strip()
    price_key = request.GET.get("price")
    amenities = _request_amenities(request)
    sort = request.GET.get("sort")

    places = search_places(
        query=query or None,
        facility_type=facility_type,
        city=city or None,
        price_key=price_key,
        amenities=amenities or None,
    )
    if sort == "newest":
        places = places.order_by("-created_at")
    elif sort == "rating":
        places = places.order_by("-rating_avg", "-likes")

    context = {
        "places": places,
        "query": query,
        "selected_type": (facility_type or "ALL").upper(),
        "selected_price": price_key or "",
        "price_filters": price_filter_options(),
        "city": city,
        "selected_amenities": amenities,
        "spotlights": spotlight_places(limit=3),
        "sort": sort or "",
        "recommended": recommended_places(limit=6),
    }

    if request.headers.get("x-requested-with") == "XMLHttpRequest":
        html = render_to_string("search/_cards.html", context, request=request)
        return JsonResponse({"html": html, "count": places.count()})

    return render(request, "search/results.html", context)

from django.shortcuts import render
from django.db.models import Count, Avg
from places.models import Place

from django.shortcuts import render
from django.db.models import Count, Avg
from places.models import Place

def home_view(request):
    summary = {
        "place_count": Place.objects.filter(is_active=True).count(),
        "studio_count": Place.objects.filter(
            is_active=True, facility_type=Place.FacilityType.STUDIO
        ).count(),
        "trainer_count": Place.objects.filter(
            is_active=True,
            facility_type__in=[Place.FacilityType.GYM, Place.FacilityType.STUDIO],
        ).count(),
    }

    # 6 tempat rating tertinggi (tanpa lihat jumlah review)
    spotlights = (
        Place.objects.filter(is_active=True)
        .annotate(
            rating_avg_calc=Avg("reviews__rating"),
            rate_count=Count("reviews", distinct=True),
        )
        .order_by("-rating_avg_calc", "-rate_count", "-created_at")[:6]
    )

    newest_places = Place.objects.filter(is_active=True).order_by("-created_at")[:6]

    context = {
        "summary": summary,
        "spotlights": spotlights,   # template kamu pakai ini
        "newest_places": newest_places,
    }
    return render(request, "home.html", context)
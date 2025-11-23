from django.shortcuts import render
from django.db.models import Count, Avg
from places.models import Place

def home_view(request):
    # Ringkas: summary (boleh tetap punyamu)
    summary = {
        "place_count": Place.objects.filter(is_active=True).count(),
        "studio_count": Place.objects.filter(is_active=True, facility_type=Place.FacilityType.STUDIO).count(),
        "trainer_count": Place.objects.filter(is_active=True, facility_type__in=[Place.FacilityType.GYM, Place.FacilityType.STUDIO]).count(),
    }

    # === TRENDING: rating terbanyak & tinggi; minimal 10 ulasan ===
    # Ganti 'reviews' di Count/Avg sesuai related_name Review->Place kamu (umumnya 'reviews')
    trending_places = (
        Place.objects.filter(is_active=True)
        .annotate(
            rate_count=Count("reviews", distinct=True),
            rating_avg_calc=Avg("reviews__rating"),
        )
        .filter(rate_count__gte=10)
        .order_by("-rating_avg_calc", "-rate_count")[:6]
    )

    # === NEWEST: berdasarkan created_at terbaru ===
    newest_places = Place.objects.filter(is_active=True).order_by("-created_at")[:6]

    # === SPOTLIGHT (kalau mau tampil di home) ===
    spotlights = (
        Place.objects.filter(is_active=True, highlight_score__gte=1)
        .order_by("-highlight_score", "-created_at")[:3]
    )

    context = {
        "summary": summary,
        "trending_places": trending_places,
        "newest_places": newest_places,
        "spotlights": spotlights,  # kalau dipakai di home.html
    }
    return render(request, "home.html", context)

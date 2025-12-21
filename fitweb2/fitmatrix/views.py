from django.shortcuts import render
from django.db.models import Count, Avg, Q
from django.utils import timezone
from places.models import Place
from scheduling.models import Trainer

def home_view(request):
    today = timezone.now().date()
    
    # Count active trainers with proper date filtering
    trainer_count = Trainer.objects.filter(
        is_active=True
    ).filter(
        Q(start_date__isnull=True) | Q(start_date__lte=today),
        Q(end_date__isnull=True) | Q(end_date__gte=today),
    ).count()
    
    summary = {
        "place_count": Place.objects.filter(is_active=True).count(),
        "studio_count": Place.objects.filter(is_active=True, facility_type=Place.FacilityType.STUDIO).count(),
        "trainer_count": trainer_count,
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

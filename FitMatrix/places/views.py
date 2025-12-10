from django.shortcuts import render, get_object_or_404, redirect
from .models import Place
from reviews.models import Review


# Halaman daftar tempat
def place_list(request):
    places = Place.objects.all()
    return render(request, "places/list.html", {"places": places})


# Halaman detail tempat
def place_detail(request, slug):
    place = get_object_or_404(Place, slug=slug)
    reviews = Review.objects.filter(place=place).order_by("-created_at")
    return render(request, "places/detail.html", {"place": place, "reviews": reviews})


from django.conf import settings
from django.http import HttpResponse, JsonResponse
from .models import Place

def places_json(request):
    def resolve_image(path):
        if not path:
            return None
        if path.startswith("http"):
            return path
        path = path.lstrip("/")
        return request.build_absolute_uri(f"/static/{path}")


    data = []
    for p in Place.objects.all():
        data.append({
            "id": p.id,
            "name": p.name,
            "slug": p.slug,
            "tagline": p.tagline,
            "summary": p.summary,
            "tags": p.tags,
            "address": p.address,
            "city": p.city,
            "latitude": float(p.latitude) if p.latitude is not None else None,
            "longitude": float(p.longitude) if p.longitude is not None else None,
            "facility_type": p.facility_type,
            "amenities": p.amenities_list(),
            "highlight_score": p.highlight_score,
            "accent_color": p.accent_color,
            "hero_image": resolve_image(p.hero_image),
            "gallery": [
                img for img in (resolve_image(g) for g in p.gallery_list()) if img
            ],
            "is_free": p.is_free,
            "price": float(p.price) if p.price is not None else None,
            "rating_avg": p.rating_avg,
            "likes": p.likes,
            "is_active": p.is_active,
            "created_at": p.created_at.isoformat(),
            "maps_url": p.google_maps_url(),
        })
    return JsonResponse(data, safe=False)

def proxy_image(request):
    import requests
    from django.http import HttpResponse

    raw_url = request.GET.get("url")
    if not raw_url:
        return HttpResponse("No URL provided", status=400)

    # Jangan double-encode
    raw_url = raw_url.strip()

    # Kalau relative, build absolute
    if raw_url.startswith("/"):
        raw_url = request.build_absolute_uri(raw_url)

    try:
        # Izinkan fetch ke localhost
        r = requests.get(raw_url, timeout=5, verify=False)
        r.raise_for_status()
    except Exception as e:
        return HttpResponse(f"Failed to fetch: {raw_url}\nError: {e}", status=404)

    content_type = r.headers.get("Content-Type", "image/jpeg")
    return HttpResponse(r.content, content_type=content_type)

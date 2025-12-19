from __future__ import annotations

from django.http import HttpResponse, JsonResponse
from django.shortcuts import get_object_or_404, redirect, render
from django.views.decorators.http import require_GET

import requests

from reviews.models import Review

from .models import Place

# Halaman daftar tempat
def place_list(request):
    places = Place.objects.all()
    return render(request, "places/list.html", {"places": places})

# Halaman detail tempat
def place_detail(request, slug):
    place = get_object_or_404(Place, slug=slug)
    reviews = Review.objects.filter(place=place).order_by("-created_at")
    return render(request, "places/detail.html", {"place": place, "reviews": reviews})


@require_GET
def reviews_partial(request, slug):
    place = get_object_or_404(Place, slug=slug)
    reviews = Review.objects.filter(place=place).order_by("-created_at")
    return render(request, "places/_reviews.html", {"place": place, "reviews": reviews})


def place_review_create(request, slug):
    if request.method != "POST":
        return JsonResponse(
            {"success": False, "error": "Invalid request method."},
            status=400,
        )

    place = get_object_or_404(Place, slug=slug)
    ajax = request.headers.get("x-requested-with") == "XMLHttpRequest"

    if not request.user.is_authenticated:
        return JsonResponse(
            {"success": False, "error": "You must be logged in."},
            status=403,
        )

    body = (request.POST.get("body") or "").strip()
    rating_raw = (request.POST.get("rating") or "").strip()

    if not body or not rating_raw:
        if ajax:
            return JsonResponse(
                {"success": False, "error": "Please fill in all fields."},
                status=400,
            )
        return redirect("places:detail", slug=place.slug)

    try:
        rating = int(rating_raw)
    except (TypeError, ValueError):
        return JsonResponse(
            {"success": False, "error": "Invalid rating value."},
            status=400,
        )

    if rating < 1 or rating > 5:
        return JsonResponse(
            {"success": False, "error": "Invalid rating value."},
            status=400,
        )

    Review.objects.create(place=place, user=request.user, rating=rating, body=body)
    if ajax:
        return JsonResponse({"success": True})
    return redirect("places:detail", slug=place.slug)


def proxy_image(request):
    image_url = request.GET.get('url')
    if not image_url:
        return HttpResponse('No URL provided', status=400)

    try:
        # Fetch image from external source
        response = requests.get(image_url, timeout=10)
        response.raise_for_status()

        # Return the image with proper content type
        return HttpResponse(
            response.content,
            content_type=response.headers.get('Content-Type', 'image/jpeg')
        )
    except requests.RequestException as e:
        return HttpResponse(f'Error fetching image: {str(e)}', status=500)

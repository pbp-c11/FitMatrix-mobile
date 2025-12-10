from django.shortcuts import render, get_object_or_404, redirect
from django.http import HttpResponse  # Corrected import
from .models import Place
from reviews.models import Review
import requests

# Halaman daftar tempat
def place_list(request):
    places = Place.objects.all()
    return render(request, "places/list.html", {"places": places})

# Halaman detail tempat
def place_detail(request, slug):
    place = get_object_or_404(Place, slug=slug)
    reviews = Review.objects.filter(place=place).order_by("-created_at")
    return render(request, "places/detail.html", {"place": place, "reviews": reviews})

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
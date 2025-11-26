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


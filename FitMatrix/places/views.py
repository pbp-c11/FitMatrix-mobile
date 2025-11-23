from django.shortcuts import render, get_object_or_404, redirect
from django.http import JsonResponse
from django.template.loader import render_to_string
from django.db.models import Avg
from .models import Place, Review


# Halaman daftar tempat
def place_list(request):
    places = Place.objects.all()
    return render(request, "places/list.html", {"places": places})


# Halaman detail tempat
def place_detail(request, slug):
    place = get_object_or_404(Place, slug=slug)
    reviews = Review.objects.filter(place=place).order_by("-created_at")
    return render(request, "places/detail.html", {"place": place, "reviews": reviews})


# Partial untuk reviews (AJAX / fragment)
def place_reviews_partial(request, slug):
    place = get_object_or_404(Place, slug=slug)
    reviews = Review.objects.filter(place=place).order_by("-created_at")
    return render(request, "places/_reviews.html", {"place": place, "reviews": reviews})


# Buat review baru (FULL FIX)
def place_review_create(request, slug):
    place = get_object_or_404(Place, slug=slug)

    if request.method == "POST":
        body = request.POST.get("body", "").strip()
        rating = request.POST.get("rating")

        # Validasi
        if not body or not rating:
            return JsonResponse({"success": False, "error": "Please fill in all fields."}, status=400)

        try:
            rating = int(rating)
        except ValueError:
            return JsonResponse({"success": False, "error": "Invalid rating value."}, status=400)

        if not request.user.is_authenticated:
            return JsonResponse({"success": False, "error": "You must be logged in."}, status=403)

        # Simpan ke database
        review = Review.objects.create(
            place=place,
            user=request.user,
            body=body,
            rating=rating,
        )

        avg_rating = place.reviews.aggregate(avg=Avg("rating"))["avg"] or 0
        place.rating_avg = avg_rating
        place.save(update_fields=["rating_avg"])

        # Jika request dari AJAX
        if request.headers.get("x-requested-with") == "XMLHttpRequest":
            review_html = render_to_string("places/_single_review.html", {"review": review})
            return JsonResponse({"success": True, "html": review_html})

        # Fallback normal redirect
        return redirect("places:detail", slug=place.slug)

    return JsonResponse({"success": False, "error": "Invalid request method."}, status=400)


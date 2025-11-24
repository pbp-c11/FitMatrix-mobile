from django.contrib.auth.decorators import login_required
from django.shortcuts import render

from .models import Review


@login_required
def review_list(request):
    reviews = Review.objects.filter(user=request.user)
    return render(request, "reviews/list.html", {"reviews": reviews})

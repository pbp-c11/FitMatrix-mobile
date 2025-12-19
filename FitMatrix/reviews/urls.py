from django.urls import path

from .views import review_list, place_review_create, place_reviews_partial

app_name = "reviews"

urlpatterns = [
    path("", review_list, name="list"),
    path("<slug:slug>/reviews/", place_reviews_partial, name="reviews_partial"),
    path("<slug:slug>/reviews/new/", place_review_create, name="place_review_create"),
]

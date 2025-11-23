from django.urls import path
from . import views

app_name = "places"

urlpatterns = [
    path("", views.place_list, name="list"),
    path("<slug:slug>/", views.place_detail, name="detail"),
    path("<slug:slug>/reviews/", views.place_reviews_partial, name="reviews_partial"),
    path("<slug:slug>/reviews/new/", views.place_review_create, name="place_review_create"),
]
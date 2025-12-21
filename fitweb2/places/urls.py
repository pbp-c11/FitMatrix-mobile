from django.urls import path
from . import views

app_name = "places"

urlpatterns = [
    path("", views.place_list, name="list"),
    path("<slug:slug>/reviews/", views.reviews_partial, name="reviews_partial"),
    path("<slug:slug>/reviews/create/", views.place_review_create, name="place_review_create"),
    path("<slug:slug>/", views.place_detail, name="detail"),
]

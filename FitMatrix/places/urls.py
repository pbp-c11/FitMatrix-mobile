from django.urls import path
from . import views

app_name = "places"

urlpatterns = [
    path("", views.place_list, name="list"),
    path("proxy-image/", views.proxy_image, name="proxy_image"),
    path("json/", views.places_json, name="places_json"),
    path("<slug:slug>/", views.place_detail, name="detail"),
]
from __future__ import annotations

from django.urls import path

from .views import list_view, toggle_view

app_name = "wishlist"

urlpatterns = [
    path("", list_view, name="list"),
    path("toggle/<str:kind>/<int:pk>/", toggle_view, name="toggle"),
]

from __future__ import annotations

from django.urls import path

from .views import results_view

app_name = "search"

urlpatterns = [
    path("", results_view, name="results"),
]

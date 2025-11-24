from django.urls import path

from .views import review_list

app_name = "reviews"

urlpatterns = [
    path("", review_list, name="list"),
]

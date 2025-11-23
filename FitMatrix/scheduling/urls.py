from django.urls import path

from .views import (
    booking_cancel,
    booking_create,
    booking_manage,
    booking_reschedule,
    trainer_detail,
    trainer_list,
    upcoming_sessions,
)

app_name = "scheduling"

urlpatterns = [
    path("", upcoming_sessions, name="sessions"),
    path("trainers/", trainer_list, name="trainers"),
    path("trainers/<int:pk>/", trainer_detail, name="trainer-detail"),
    path("slots/<int:pk>/book/", booking_create, name="booking-create"),
    path("bookings/", booking_manage, name="booking-manage"),
    path("bookings/<int:pk>/cancel/", booking_cancel, name="booking-cancel"),
    path("bookings/<int:pk>/reschedule/", booking_reschedule, name="booking-reschedule"),
]

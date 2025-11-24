from django.contrib import admin

from .models import Booking, SessionSlot, Trainer


@admin.register(Trainer)
class TrainerAdmin(admin.ModelAdmin):
    list_display = ("name", "specialties", "price_per_session", "likes", "rating_avg", "is_active")
    search_fields = ("name", "specialties")
    list_filter = ("is_active",)


@admin.register(SessionSlot)
class SessionSlotAdmin(admin.ModelAdmin):
    list_display = ("trainer", "place", "start", "end", "capacity", "is_active")
    list_filter = ("trainer", "place", "is_active")
    search_fields = ("trainer__name", "place__name")


@admin.register(Booking)
class BookingAdmin(admin.ModelAdmin):
    list_display = ("user", "slot", "status", "created_at")
    list_filter = ("status", "slot__trainer")
    search_fields = ("user__username",)

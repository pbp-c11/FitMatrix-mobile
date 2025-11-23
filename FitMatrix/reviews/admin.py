from django.contrib import admin

from .models import Review


@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):
    list_display = ("user", "trainer", "rating", "is_visible", "created_at")
    list_filter = ("is_visible", "rating")
    search_fields = ("user__username", "trainer__name")

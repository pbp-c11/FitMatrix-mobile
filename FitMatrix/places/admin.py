from django.contrib import admin

from .models import Place


@admin.register(Place)
class PlaceAdmin(admin.ModelAdmin):
    list_display = (
        "name",
        "city",
        "facility_type",
        "is_free",
        "price",
        "latitude",
        "longitude",
        "highlight_score",
        "is_active",
    )
    list_filter = ("facility_type", "city", "is_free", "is_active")
    search_fields = ("name", "city", "summary", "tags")
    readonly_fields = ("created_at",)
    fieldsets = (
        (
            None,
            {
                "fields": (
                    "name",
                    "slug",
                    "tagline",
                    "summary",
                    "facility_type",
                    "tags",
                )
            },
        ),
        (
            "Location & Pricing",
            {
                "fields": (
                    "address",
                    "city",
                    "latitude",
                    "longitude",
                    "is_free",
                    "price",
                )
            },
        ),
        (
            "Experience",
            {
                "fields": (
                    "amenities",
                    "gallery",
                    "hero_image",
                    "accent_color",
                    "highlight_score",
                )
            },
        ),
        (
            "Meta",
            {
                "fields": (
                    "rating_avg",
                    "likes",
                    "is_active",
                    "created_at",
                )
            },
        ),
    )
    prepopulated_fields = {"slug": ("name",)}

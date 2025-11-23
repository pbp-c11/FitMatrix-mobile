from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as DjangoUserAdmin

from .models import ActivityLog, CollectionItem, User, WishlistCollection, WishlistItem


@admin.register(User)
class UserAdmin(DjangoUserAdmin):
    fieldsets = DjangoUserAdmin.fieldsets + (
        (
            "Profile",
            {
                "fields": ("display_name", "role", "avatar"),
            },
        ),
    )
    list_display = ("username", "email", "display_name", "role", "is_staff")
    list_filter = ("role", "is_staff")


@admin.register(ActivityLog)
class ActivityLogAdmin(admin.ModelAdmin):
    list_display = ("user", "type", "created_at")
    list_filter = ("type", "created_at")
    search_fields = ("user__username", "user__email")


@admin.register(WishlistItem)
class WishlistItemAdmin(admin.ModelAdmin):
    list_display = ("user", "place", "trainer", "created_at")
    list_filter = ("created_at",)
    search_fields = ("user__username", "place__name", "trainer__name")


@admin.register(WishlistCollection)
class WishlistCollectionAdmin(admin.ModelAdmin):
    list_display = ("name", "user", "created_at")
    search_fields = ("name", "user__username")
    list_filter = ("created_at",)


@admin.register(CollectionItem)
class CollectionItemAdmin(admin.ModelAdmin):
    list_display = ("collection", "place", "added_at")
    search_fields = ("collection__name", "place__name")
    list_filter = ("added_at",)

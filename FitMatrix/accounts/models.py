from __future__ import annotations

from typing import Any

from django.conf import settings
from django.contrib.auth.models import AbstractUser
from django.core.exceptions import ValidationError
from django.db import models
from django.utils.translation import gettext_lazy as _


class User(AbstractUser):
    email = models.EmailField(_("email address"), unique=True)
    class Roles(models.TextChoices):
        ADMIN = "ADMIN", "Admin"
        USER = "USER", "User"

    role = models.CharField(
        max_length=16,
        choices=Roles.choices,
        default=Roles.USER,
    )
    display_name = models.CharField(max_length=100, blank=True)
    avatar = models.ImageField(upload_to="avatars/", blank=True, null=True)

    def clean(self) -> None:
        super().clean()
        if self.email:
            self.email = self.email.strip().lower()
            conflict = (
                type(self)
                .objects.exclude(pk=self.pk)
                .filter(email__iexact=self.email)
                .exists()
            )
            if conflict:
                raise ValidationError({"email": _("Email address must be unique.")})

    def save(self, *args: Any, **kwargs: Any) -> None:
        if self.email:
            self.email = self.email.strip().lower()
        if not self.display_name:
            full_name = self.get_full_name().strip()
            self.display_name = full_name or self.username
        if self.role == self.Roles.ADMIN:
            self.is_staff = True
        elif not self.is_superuser:
            self.is_staff = False
        self.full_clean()
        super().save(*args, **kwargs)

    @property
    def is_admin(self) -> bool:
        return self.role == self.Roles.ADMIN

    def __str__(self) -> str:
        return self.display_name or self.username


class ActivityLog(models.Model):
    class Types(models.TextChoices):
        LOGIN = "LOGIN", "Login"
        LOGOUT = "LOGOUT", "Logout"
        PROFILE_UPDATED = "PROFILE_UPDATED", "Profile Updated"
        BOOKING_CREATED = "BOOKING_CREATED", "Booking Created"
        BOOKING_CANCELLED = "BOOKING_CANCELLED", "Booking Cancelled"
        REVIEW_POSTED = "REVIEW_POSTED", "Review Posted"
        WISHLIST_ADDED = "WISHLIST_ADDED", "Wishlist Added"
        WISHLIST_REMOVED = "WISHLIST_REMOVED", "Wishlist Removed"
        PASSWORD_CHANGED = "PASSWORD_CHANGED", "Password Changed"

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    type = models.CharField(max_length=32, choices=Types.choices)
    meta = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return f"{self.user} -> {self.get_type_display()}"


class WishlistItem(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    place = models.ForeignKey(
        "places.Place",
        on_delete=models.CASCADE,
        null=True,
        blank=True,
    )
    trainer = models.ForeignKey(
        "scheduling.Trainer",
        on_delete=models.CASCADE,
        null=True,
        blank=True,
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["user", "place"],
                name="unique_user_place_wishlist",
            ),
            models.UniqueConstraint(
                fields=["user", "trainer"],
                name="unique_user_trainer_wishlist",
            ),
        ]
        ordering = ["-created_at"]

    def clean(self) -> None:
        super().clean()
        has_place = self.place is not None
        has_trainer = self.trainer is not None
        if has_place == has_trainer:
            raise ValidationError(
                _("Select either a place or a trainer for a wishlist item."),
            )

    def save(self, *args: Any, **kwargs: Any) -> None:
        self.full_clean()
        super().save(*args, **kwargs)

    def __str__(self) -> str:
        target = self.place or self.trainer
        return f"Wishlist({self.user} -> {target})"


class WishlistCollection(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="wishlist_collections")
    name = models.CharField(max_length=120)
    description = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("user", "name")
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return f"{self.name} ({self.user})"


class CollectionItem(models.Model):
    collection = models.ForeignKey(WishlistCollection, on_delete=models.CASCADE, related_name="items")
    place = models.ForeignKey("places.Place", on_delete=models.CASCADE, related_name="collection_items")
    added_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("collection", "place")
        ordering = ["-added_at"]

    def __str__(self) -> str:
        return f"{self.collection} -> {self.place}"

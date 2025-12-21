from __future__ import annotations

from typing import Any

from django.conf import settings
from django.core.exceptions import ValidationError
from django.db import models
from django.utils import timezone


class Trainer(models.Model):
    name = models.CharField(max_length=150)
    specialties = models.CharField(max_length=255)
    bio = models.TextField(blank=True)
    price_per_session = models.DecimalField(max_digits=8, decimal_places=2, default=0)
    likes = models.PositiveIntegerField(default=0)
    calendly_url = models.URLField(blank=True)
    rating_avg = models.FloatField(default=0)
    is_active = models.BooleanField(default=True)
    # Scheduling fields
    place = models.ForeignKey(
        "places.Place",
        related_name="trainers",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
    )
    start_date = models.DateField(null=True, blank=True)
    end_date = models.DateField(null=True, blank=True)

    class Meta:
        ordering = ["name"]

    @property
    def is_available(self) -> bool:
        """Check if trainer is available based on start/end dates."""
        if not self.is_active:
            return False
        today = timezone.now().date()
        if self.start_date and today < self.start_date:
            return False
        if self.end_date and today > self.end_date:
            return False
        return True

    def __str__(self) -> str:
        return self.name


class SessionSlot(models.Model):
    trainer = models.ForeignKey(Trainer, related_name="slots", on_delete=models.CASCADE)
    place = models.ForeignKey("places.Place", related_name="slots", on_delete=models.CASCADE)
    start = models.DateTimeField()
    end = models.DateTimeField()
    capacity = models.PositiveIntegerField()
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["start"]

    def clean(self) -> None:
        super().clean()
        if self.end <= self.start:
            raise ValidationError({"end": "End time must be after start time."})
        if self.capacity < 1:
            raise ValidationError({"capacity": "Capacity must be at least 1."})

    def seats_left(self) -> int:
        booked = self.bookings.filter(status=Booking.Status.BOOKED).count()
        return max(self.capacity - booked, 0)

    def __str__(self) -> str:
        start_local = timezone.localtime(self.start)
        return f"{self.trainer} @ {self.place} ({start_local:%d %b %Y %H:%M})"


class Booking(models.Model):
    class Status(models.TextChoices):
        BOOKED = "BOOKED", "Booked"
        CANCELLED = "CANCELLED", "Cancelled"
        COMPLETED = "COMPLETED", "Completed"

    user = models.ForeignKey(settings.AUTH_USER_MODEL, related_name="bookings", on_delete=models.CASCADE)
    slot = models.ForeignKey(SessionSlot, related_name="bookings", on_delete=models.CASCADE)
    status = models.CharField(max_length=16, choices=Status.choices, default=Status.BOOKED)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ("user", "slot")
        ordering = ["-created_at"]

    def clean(self) -> None:
        super().clean()
        if self.slot and self.status == self.Status.BOOKED:
            qs = Booking.objects.filter(slot=self.slot, status=self.Status.BOOKED)
            if self.pk:
                qs = qs.exclude(pk=self.pk)
            if qs.count() >= self.slot.capacity:
                raise ValidationError({"slot": "This session is already fully booked."})

    def save(self, *args: Any, **kwargs: Any) -> None:
        self.full_clean()
        super().save(*args, **kwargs)

    def cancel(self, by_admin: bool = False) -> None:
        if self.status == self.Status.CANCELLED:
            return
        self.status = self.Status.CANCELLED
        setattr(self, "_cancelled_by_admin", by_admin)
        self.save(update_fields=["status", "updated_at"])

    def __str__(self) -> str:
        return f"Booking({self.user} -> {self.slot})"

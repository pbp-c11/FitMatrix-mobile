from __future__ import annotations

from typing import Any

from django.conf import settings
from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models


class Review(models.Model):
    booking = models.OneToOneField("scheduling.Booking", on_delete=models.CASCADE, related_name="review")
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="reviews")
    trainer = models.ForeignKey("scheduling.Trainer", on_delete=models.CASCADE, related_name="reviews")
    rating = models.IntegerField(validators=[MinValueValidator(1), MaxValueValidator(5)])
    comment = models.TextField()
    is_visible = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def save(self, *args: Any, **kwargs: Any) -> None:
        super().save(*args, **kwargs)
        from .signals import update_trainer_rating  # local import to avoid recursion

        update_trainer_rating(self.trainer)

    def delete(self, *args: Any, **kwargs: Any) -> tuple[int, dict[str, int]]:
        trainer = self.trainer
        result = super().delete(*args, **kwargs)
        from .signals import update_trainer_rating

        update_trainer_rating(trainer)
        return result

    def __str__(self) -> str:
        return f"Review({self.user} -> {self.trainer})"

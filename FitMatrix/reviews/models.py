from __future__ import annotations

from typing import Any

from django.conf import settings
from django.db import models


class Review(models.Model):
    place = models.ForeignKey("places.Place", on_delete=models.CASCADE, related_name="reviews")
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="place_reviews",
        related_query_name="place_review", 
    )
    rating = models.PositiveSmallIntegerField()
    body = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [
            models.Index(fields=["place", "created_at"]),
            models.Index(fields=["rating"]),
        ]

    def __str__(self):
        return f"{self.place} - {self.user} ({self.rating})"


class ReviewLike(models.Model):
    review = models.ForeignKey(Review, on_delete=models.CASCADE, related_name="likes")
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="place_review_likes",
        related_query_name="place_review_like",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("review", "user")
        indexes = [models.Index(fields=["review"])]

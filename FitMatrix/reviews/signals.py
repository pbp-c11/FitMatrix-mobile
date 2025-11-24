from __future__ import annotations

from django.db.models import Avg
from django.db.models.signals import post_save
from django.dispatch import receiver

from .models import Review


def update_trainer_rating(trainer) -> None:
    if trainer is None:
        return
    avg = (
        trainer.reviews.filter(is_visible=True).aggregate(avg=Avg("rating"))["avg"]
        or 0
    )
    trainer.rating_avg = round(float(avg), 2)
    trainer.save(update_fields=["rating_avg"])


@receiver(post_save, sender=Review)
def refresh_trainer_rating(sender, instance: Review, **_: object) -> None:  # noqa: ARG001
    update_trainer_rating(instance.trainer)

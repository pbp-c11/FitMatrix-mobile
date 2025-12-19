from django.db.models import Avg
from django.db.models.signals import post_delete, post_save
from django.dispatch import receiver

from .models import Review, TrainerReview


def update_place_rating(place) -> None:
    if place is None:
        return
    avg = place.reviews.aggregate(avg=Avg("rating"))["avg"] or 0
    place.rating_avg = round(float(avg), 2)
    place.save(update_fields=["rating_avg"])


@receiver(post_save, sender=Review)
def refresh_place_rating(sender, instance: Review, **kwargs):
    update_place_rating(instance.place)


@receiver(post_delete, sender=Review)
def refresh_place_rating_on_delete(sender, instance: Review, **kwargs):
    update_place_rating(instance.place)


def update_trainer_rating(trainer) -> None:
    if trainer is None:
        return
    avg = trainer.reviews.filter(is_visible=True).aggregate(avg=Avg("rating"))["avg"] or 0
    trainer.rating_avg = round(float(avg), 2)
    trainer.save(update_fields=["rating_avg"])


@receiver(post_save, sender=TrainerReview)
def refresh_trainer_rating(sender, instance: TrainerReview, **kwargs):
    update_trainer_rating(instance.trainer)


@receiver(post_delete, sender=TrainerReview)
def refresh_trainer_rating_on_delete(sender, instance: TrainerReview, **kwargs):
    update_trainer_rating(instance.trainer)

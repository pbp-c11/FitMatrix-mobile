from django.db.models import Avg
from django.db.models.signals import post_save
from django.dispatch import receiver

from .models import Review


def update_place_rating(place) -> None:
    if place is None:
        return
    avg = place.reviews.aggregate(avg=Avg("rating"))["avg"] or 0
    place.rating_avg = round(float(avg), 2)
    place.save(update_fields=["rating_avg"])


@receiver(post_save, sender=Review)
def refresh_place_rating(sender, instance: Review, **kwargs):
    update_place_rating(instance.place)

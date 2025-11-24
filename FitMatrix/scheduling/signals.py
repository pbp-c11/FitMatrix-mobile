from __future__ import annotations

from django.db.models.signals import post_delete, post_save, pre_save
from django.dispatch import receiver

from accounts.models import ActivityLog

from .models import Booking


@receiver(pre_save, sender=Booking)
def store_previous_status(sender, instance: Booking, **_: object) -> None:  # noqa: ARG001
    if instance.pk:
        try:
            instance._previous_status = sender.objects.get(pk=instance.pk).status  # type: ignore[attr-defined]
        except sender.DoesNotExist:
            instance._previous_status = None  # type: ignore[attr-defined]
    else:
        instance._previous_status = None  # type: ignore[attr-defined]


@receiver(post_save, sender=Booking)
def booking_activity_log(sender, instance: Booking, created: bool, **_: object) -> None:  # noqa: ARG001
    if created and instance.status == Booking.Status.BOOKED:
        ActivityLog.objects.create(
            user=instance.user,
            type=ActivityLog.Types.BOOKING_CREATED,
            meta={"booking_id": instance.pk, "slot": instance.slot_id},
        )
    else:
        previous_status = getattr(instance, "_previous_status", None)
        if (
            previous_status == Booking.Status.BOOKED
            and instance.status == Booking.Status.CANCELLED
        ):
            ActivityLog.objects.create(
                user=instance.user,
                type=ActivityLog.Types.BOOKING_CANCELLED,
                meta={
                    "booking_id": instance.pk,
                    "slot": instance.slot_id,
                    "by_admin": getattr(instance, "_cancelled_by_admin", False),
                },
            )


@receiver(post_delete, sender=Booking)
def booking_delete_log(sender, instance: Booking, **_: object) -> None:  # noqa: ARG001
    if instance.status == Booking.Status.BOOKED:
        ActivityLog.objects.create(
            user=instance.user,
            type=ActivityLog.Types.BOOKING_CANCELLED,
            meta={"booking_id": instance.pk, "slot": instance.slot_id, "deleted": True},
        )

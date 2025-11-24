from __future__ import annotations

import os

from django.db.models.signals import post_delete, pre_save
from django.dispatch import receiver

from .models import User


def _delete_avatar_file(path: str | None) -> None:
    if not path:
        return
    if os.path.isfile(path):
        try:
            os.remove(path)
        except OSError:
            pass


@receiver(pre_save, sender=User)
def auto_delete_old_avatar(sender, instance: User, **_: object) -> None:  # noqa: ARG001
    if not instance.pk:
        return
    try:
        old_avatar = sender.objects.get(pk=instance.pk).avatar
    except sender.DoesNotExist:
        return
    new_avatar = instance.avatar
    if old_avatar and old_avatar != new_avatar:
        _delete_avatar_file(old_avatar.path if hasattr(old_avatar, "path") else None)


@receiver(post_delete, sender=User)
def auto_delete_avatar_on_delete(sender, instance: User, **_: object) -> None:  # noqa: ARG001
    if instance.avatar:
        _delete_avatar_file(
            instance.avatar.path if hasattr(instance.avatar, "path") else None,
        )

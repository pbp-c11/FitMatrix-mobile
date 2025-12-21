# scheduling/services.py
from __future__ import annotations

from datetime import datetime, timedelta, time

from django.utils import timezone

from .models import SessionSlot, Trainer

DEFAULT_TIMES = [time(10, 0), time(14, 0), time(18, 0)]
DEFAULT_CAPACITY = 5


def generate_slots_for_trainer(trainer: Trainer, *, replace_future: bool = True) -> int:
    if not trainer.is_active:
        return 0
    if not trainer.place or not trainer.start_date or not trainer.end_date:
        return 0

    now = timezone.now()

    # biar update trainer (date/place) gak bikin slot numpuk
    if replace_future:
        SessionSlot.objects.filter(trainer=trainer, start__gte=now).delete()

    created = 0
    day = trainer.start_date

    while day <= trainer.end_date:
        for t in DEFAULT_TIMES:
            start_dt = timezone.make_aware(datetime.combine(day, t))
            end_dt = start_dt + timedelta(hours=1)

            # skip slot yang udah lewat
            if start_dt < now:
                continue

            SessionSlot.objects.get_or_create(
                trainer=trainer,
                place=trainer.place,
                start=start_dt,
                end=end_dt,
                defaults={"capacity": DEFAULT_CAPACITY, "is_active": True},
            )
            created += 1

        day += timedelta(days=1)

    return created

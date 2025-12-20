from __future__ import annotations

import csv
import os
import random
import shutil
from datetime import timedelta
from decimal import Decimal
from pathlib import Path

from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from django.core.management.base import BaseCommand, CommandError
from django.utils import timezone
from django.utils.text import slugify

from accounts.models import ActivityLog, WishlistItem  # User comes from get_user_model()
from places.models import Place
from reviews.models import Review
from scheduling.models import Booking, SessionSlot, Trainer


class Command(BaseCommand):
    help = "Seed the database with demo data for FitMatrix"

    def handle(self, *args, **options):
        random.seed(42)
        self.stdout.write("Seeding demo data...")

        User = get_user_model()
        admin_email = os.environ.get("DEMO_ADMIN_EMAIL", "admin@fitmatrix.test")
        admin_pass = os.environ.get("DEMO_ADMIN_PASSWORD", "Admin123!")

        # ---- Admin user (create with password hashed) ------------------------
        admin = User.objects.filter(username="admin").first()
        if admin is None:
            # If your User uses email as USERNAME_FIELD, this still works;
            # we're explicitly setting username and email.
            admin = User.objects.create_user(
                username="admin",
                email=admin_email,
                password=admin_pass,
            )
            created = True
        else:
            created = False
            if not admin.has_usable_password():
                admin.set_password(admin_pass)

        # Role + flags for your custom dashboards and Django admin
        if hasattr(User, "Roles"):
            admin.role = User.Roles.ADMIN
        else:
            # Fallback if role is a CharField with choices
            setattr(admin, "role", "ADMIN")

        admin.is_staff = True
        admin.is_superuser = True
        # Nice-to-have display name if your model has it
        if hasattr(admin, "display_name"):
            admin.display_name = "FitMatrix Admin"
        admin.save()

        msg_status = "created" if created else "updated"
        self.stdout.write(f"- Admin account {msg_status} ({admin_email} / {admin_pass})")

        # ---- Member accounts -------------------------------------------------
        user_names = [
            ("budi", "Budi Santoso"),
            ("sri", "Sri Wahyuni"),
            ("andika", "Andika Pratama"),
            ("ayu", "Ayu Lestari"),
            ("rudi", "Rudi Hartono"),
            ("intan", "Intan Permata"),
            ("dimas", "Dimas Saputra"),
            ("melati", "Melati Cahya"),
        ]

        users = []
        for username, display_name in user_names:
            user = User.objects.filter(username=username).first()
            if user is None:
                user = User.objects.create_user(
                    username=username,
                    email=f"{username}@fitmatrix.test",
                    password="User12345!",  # ensure non-blank + hashed
                )
            # Optional profile fields
            if hasattr(user, "display_name") and not getattr(user, "display_name", None):
                user.display_name = display_name
            user.save()
            users.append(user)

        self.stdout.write(f"- Seeded {len(users)} member accounts")

        # ---- Trainers --------------------------------------------------------
        trainers_info = [
            ("Raka Mahendra", "Strength"),
            ("Siti Rahma", "Cardio"),
            ("Yoga Prabowo", "Yoga"),
            ("Dewi Laras", "Pilates"),
            ("Fajar Wibowo", "Calisthenics"),
            ("Lia Kartika", "Mobility"),
        ]
        trainers = []
        for name, specialties in trainers_info:
            trainer, _ = Trainer.objects.get_or_create(
                name=name,
                defaults={"specialties": specialties, "bio": f"Certified in {specialties}."},
            )
            trainers.append(trainer)
        self.stdout.write("- Trainers prepared")

        places = list(Place.objects.all())  # atau kosongkan total: places = []
        self.stdout.write(f"- Skipped place seeding (manual-only mode)")


        # ---- Session slots ---------------------------------------------------
        SessionSlot.objects.all().delete()
        slots = []
        base_time = timezone.now() + timedelta(days=1)
        for day in range(10):
            for idx in range(3):
                trainer = random.choice(trainers)
                place = random.choice(places)
                start = base_time + timedelta(days=day, hours=idx * 3)
                end = start + timedelta(hours=1)
                slot = SessionSlot.objects.create(
                    trainer=trainer,
                    place=place,
                    start=start,
                    end=end,
                    capacity=random.randint(3, 8),
                    is_active=True,
                )
                slots.append(slot)
        self.stdout.write(f"- Generated {len(slots)} session slots")

        # ---- Bookings + Reviews + Activity logs ------------------------------
        Booking.objects.all().delete()
        ActivityLog.objects.all().delete()

        reviews_created = 0
        for user in users:
            for slot in random.sample(slots, k=min(3, len(slots))):
                try:
                    booking = Booking.objects.create(user=user, slot=slot)
                except ValidationError:
                    continue
                if random.random() > 0.5:
                    booking.status = Booking.Status.COMPLETED
                    booking.save(update_fields=["status"])

                    rating = random.randint(3, 5)

                    Review.objects.create(
                        user=user,
                        place=booking.slot.place,
                        rating=rating,
                        body="Great session!",
                    )

                    reviews_created += 1    
        self.stdout.write(f"- Created sample bookings and {reviews_created} reviews")

        # ---- Wishlists -------------------------------------------------------
        WishlistItem.objects.all().delete()
        for user in users:
            for place in random.sample(places, k=min(2, len(places))):
                WishlistItem.objects.get_or_create(user=user, place=place)
            trainer = random.choice(trainers)
            WishlistItem.objects.get_or_create(user=user, trainer=trainer)
        self.stdout.write("- Wishlist samples added")

        self.stdout.write(self.style.SUCCESS("Demo data seeded successfully."))
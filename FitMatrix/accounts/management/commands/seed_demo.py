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

        places, dataset_label = self.sync_places_from_csv()
        self.stdout.write(f"- Synced {len(places)} places from {dataset_label}")

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
                    Review.objects.get_or_create(
                        booking=booking,
                        user=user,
                        trainer=slot.trainer,
                        defaults={"rating": rating, "comment": "Great session!"},
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

    def sync_places_from_csv(self, base_dir: Path | None = None) -> tuple[list[Place], str]:
        base_dir = base_dir or Path(__file__).resolve().parents[3]
        dataset_dir, csv_path, images_dir = self.resolve_places_seed_paths(base_dir)

        static_places_dir = base_dir / "static" / "img" / "places"
        static_places_dir.mkdir(parents=True, exist_ok=True)

        image_sources = {path.name: path for path in images_dir.iterdir() if path.is_file()}
        copied_images: set[str] = set()

        def ensure_image(filename: str) -> str:
            name = (filename or "").strip()
            if not name:
                return ""
            if name not in image_sources:
                raise CommandError(
                    f"Image '{name}' referenced in {csv_path.name} was not found in {images_dir}."
                )
            destination = static_places_dir / name
            if name not in copied_images or not destination.exists():
                shutil.copy2(image_sources[name], destination)
                copied_images.add(name)
            return f"img/places/{name}"

        def parse_list(raw: str | None) -> list[str]:
            if not raw:
                return []
            return [item.strip() for item in raw.split("|") if item.strip()]

        def parse_bool(raw: str | None) -> bool:
            return str(raw or "").strip().lower() in {"1", "true", "yes", "y"}

        def parse_decimal(raw: str | None) -> Decimal | None:
            value = str(raw or "").strip()
            if not value:
                return None
            return Decimal(value)

        def parse_float(raw: str | None) -> float:
            value = str(raw or "").strip()
            return float(value) if value else 0.0

        places: list[Place] = []
        seen_slugs: set[str] = set()

        with csv_path.open(newline="", encoding="utf-8") as handle:
            reader = csv.DictReader(handle)
            for row in reader:
                name = (row.get("name") or "").strip()
                if not name:
                    continue
                slug = (row.get("slug") or slugify(name)).strip()
                if not slug:
                    raise CommandError("Each place row requires a slug or name to derive one.")

                facility_type = (row.get("facility_type") or Place.FacilityType.GYM).upper()
                if facility_type not in Place.FacilityType.values:
                    raise CommandError(
                        f"Unknown facility_type '{facility_type}' for place '{name}'."
                    )

                hero_image = ensure_image(row.get("hero_image", ""))
                gallery_images = [
                    path
                    for path in (
                        ensure_image(filename)
                        for filename in parse_list(row.get("gallery"))
                    )
                    if path
                ]

                defaults = {
                    "name": name,
                    "tagline": (row.get("tagline") or "").strip(),
                    "summary": (row.get("summary") or "").strip(),
                    "tags": (row.get("tags") or "").strip(),
                    "address": (row.get("address") or "").strip(),
                    "city": (row.get("city") or "").strip(),
                    "latitude": parse_decimal(row.get("latitude")),
                    "longitude": parse_decimal(row.get("longitude")),
                    "facility_type": facility_type,
                    "amenities": parse_list(row.get("amenities")),
                    "highlight_score": int((row.get("highlight_score") or 0) or 0),
                    "accent_color": (row.get("accent_color") or "").strip(),
                    "hero_image": hero_image,
                    "gallery": gallery_images,
                    "is_free": parse_bool(row.get("is_free")),
                    "price": parse_decimal(row.get("price")),
                    "rating_avg": parse_float(row.get("rating_avg")),
                    "likes": int((row.get("likes") or 0) or 0),
                    "is_active": parse_bool(row.get("is_active", "true")),
                    "slug": slug,
                }

                place, _ = Place.objects.update_or_create(slug=slug, defaults=defaults)
                places.append(place)
                seen_slugs.add(slug)

        if not places:
            raise CommandError("No places were loaded from the CSV; ensure it has at least one row.")

        Place.objects.exclude(slug__in=seen_slugs).delete()
        dataset_label = csv_path.relative_to(base_dir).as_posix()
        return places, dataset_label

    def resolve_places_seed_paths(
        self, base_dir: Path
    ) -> tuple[Path, Path, Path]:
        candidates = [
            base_dir / "data" / "places" / "to_be_seeded",
            base_dir / "data" / "places" / "to be seeded",
            base_dir / "data" / "places",
        ]
        for dataset_dir in candidates:
            csv_path = dataset_dir / "places.csv"
            images_dir = dataset_dir / "images"
            if csv_path.exists() and images_dir.exists():
                return dataset_dir, csv_path, images_dir

        raise CommandError(
            "Place seed files not found. Add places.csv and an images/ directory under data/places/to_be_seeded."
        )

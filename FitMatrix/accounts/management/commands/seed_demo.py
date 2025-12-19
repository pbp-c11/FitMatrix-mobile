from __future__ import annotations

import csv
import os
import random
import shutil
from datetime import timedelta
from decimal import Decimal, InvalidOperation
from pathlib import Path
from typing import Any

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

    def resolve_places_seed_paths(self, base_dir: Path) -> tuple[str, Path, Path]:
        candidates = [
            base_dir / "data" / "places" / "to_be_seeded",
            base_dir / "data" / "places" / "seed_csv_demo",
            base_dir / "data" / "places",
        ]

        for folder in candidates:
            csv_path = folder / "places.csv"
            images_dir = folder / "images"
            if csv_path.exists() and images_dir.exists():
                return csv_path.relative_to(base_dir).as_posix(), csv_path, images_dir

        raise CommandError("No places CSV dataset found under data/places/.")

    def sync_places_from_csv(self, base_dir: Path | None = None) -> tuple[list[Place], str]:
        base_dir = base_dir or Path(__file__).resolve().parents[3]
        dataset_label, csv_path, images_dir = self.resolve_places_seed_paths(base_dir)

        static_img_dir = base_dir / "static" / "img" / "places"
        static_img_dir.mkdir(parents=True, exist_ok=True)

        created: list[Place] = []
        with csv_path.open("r", encoding="utf-8", newline="") as handle:
            reader = csv.DictReader(handle)
            for raw_row in reader:
                row = {k: (v.strip() if isinstance(v, str) else v) for k, v in raw_row.items()}
                place = self._upsert_place_from_row(
                    row=row,
                    images_dir=images_dir,
                    static_img_dir=static_img_dir,
                )
                created.append(place)
        return created, dataset_label

    def _upsert_place_from_row(
        self,
        *,
        row: dict[str, Any],
        images_dir: Path,
        static_img_dir: Path,
    ) -> Place:
        def parse_bool(value: Any) -> bool:
            if value is None:
                return False
            if isinstance(value, bool):
                return value
            text = str(value).strip().lower()
            return text in {"1", "true", "yes", "y", "on"}

        def parse_int(value: Any, default: int = 0) -> int:
            try:
                return int(str(value).strip())
            except (TypeError, ValueError):
                return default

        def parse_float(value: Any, default: float = 0) -> float:
            try:
                return float(str(value).strip())
            except (TypeError, ValueError):
                return default

        def parse_decimal(value: Any) -> Decimal | None:
            if value is None:
                return None
            text = str(value).strip()
            if not text:
                return None
            try:
                return Decimal(text)
            except (InvalidOperation, ValueError):
                return None

        def split_pipe(value: Any) -> list[str]:
            if value is None:
                return []
            text = str(value).strip()
            if not text:
                return []
            return [part.strip() for part in text.split("|") if part.strip()]

        def normalize_slug(value: Any, name: str) -> str:
            slug = str(value or "").strip()
            return slug or slugify(name) or "place"

        def normalize_facility_type(value: Any) -> str:
            raw = str(value or "").strip().upper()
            allowed = {choice for choice, _ in Place.FacilityType.choices}
            return raw if raw in allowed else Place.FacilityType.GYM

        def static_image_path(filename: str) -> str:
            filename = filename.strip().lstrip("/").replace("\\", "/")
            return f"img/places/{filename.split('/')[-1]}"

        def copy_static_image(filename: str) -> str:
            filename = filename.strip()
            if not filename or "://" in filename:
                return filename
            src = images_dir / filename
            if not src.exists():
                raise CommandError(f"Missing place image file: {src}")
            dst = static_img_dir / filename
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
            return static_image_path(filename)

        name = str(row.get("name") or "").strip()
        if not name:
            raise CommandError("places.csv row is missing 'name'")

        slug = normalize_slug(row.get("slug"), name)
        facility_type = normalize_facility_type(row.get("facility_type"))

        is_free = parse_bool(row.get("is_free"))
        price = None if is_free else parse_decimal(row.get("price"))

        hero_image_raw = str(row.get("hero_image") or "").strip()
        hero_image = copy_static_image(hero_image_raw) if hero_image_raw else ""

        gallery_raw = split_pipe(row.get("gallery"))
        gallery: list[str] = []
        for entry in gallery_raw:
            try:
                gallery.append(copy_static_image(entry))
            except CommandError:
                gallery.append(entry)

        defaults = {
            "name": name,
            "tagline": str(row.get("tagline") or "").strip(),
            "summary": str(row.get("summary") or "").strip(),
            "tags": str(row.get("tags") or "").strip(),
            "address": str(row.get("address") or "").strip(),
            "city": str(row.get("city") or "").strip(),
            "latitude": row.get("latitude") or None,
            "longitude": row.get("longitude") or None,
            "facility_type": facility_type,
            "amenities": split_pipe(row.get("amenities")),
            "highlight_score": parse_int(row.get("highlight_score"), 0),
            "accent_color": str(row.get("accent_color") or "").strip(),
            "hero_image": hero_image,
            "gallery": gallery,
            "is_free": is_free,
            "price": price,
            "rating_avg": parse_float(row.get("rating_avg"), 0),
            "likes": parse_int(row.get("likes"), 0),
            "is_active": parse_bool(row.get("is_active")) if row.get("is_active") is not None else True,
        }

        if not defaults["address"]:
            raise CommandError(f"places.csv row '{slug}' is missing 'address'")
        if not defaults["city"]:
            raise CommandError(f"places.csv row '{slug}' is missing 'city'")

        place, _ = Place.objects.update_or_create(slug=slug, defaults=defaults)
        return place

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

        places = list(Place.objects.all())
        if places:
            self.stdout.write("- Skipped place seeding (manual-only mode)")
        else:
            try:
                base_dir = Path(__file__).resolve().parents[3]
                places, dataset_label = self.sync_places_from_csv(base_dir=base_dir)
                self.stdout.write(f"- Seeded {len(places)} places from {dataset_label}")
            except CommandError as err:
                self.stdout.write(f"- No CSV dataset found ({err}); creating minimal demo places...")
                demo_places = [
                    {
                        "name": "FitMatrix Demo Gym",
                        "address": "Jl. Sudirman No. 1",
                        "city": "Jakarta",
                        "facility_type": Place.FacilityType.GYM,
                        "is_free": False,
                        "price": Decimal("100000.00"),
                        "highlight_score": 5,
                    },
                    {
                        "name": "FitMatrix Demo Studio",
                        "address": "Jl. Thamrin No. 10",
                        "city": "Jakarta",
                        "facility_type": Place.FacilityType.STUDIO,
                        "is_free": False,
                        "price": Decimal("75000.00"),
                        "highlight_score": 4,
                    },
                    {
                        "name": "FitMatrix Demo Park",
                        "address": "Jl. Asia Afrika",
                        "city": "Bandung",
                        "facility_type": Place.FacilityType.OUTDOOR,
                        "is_free": True,
                        "price": None,
                        "highlight_score": 3,
                    },
                ]
                for data in demo_places:
                    Place.objects.get_or_create(
                        name=data["name"],
                        defaults=data,
                    )
                places = list(Place.objects.all())


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

    

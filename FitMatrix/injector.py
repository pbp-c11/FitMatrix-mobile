from __future__ import annotations

import argparse
import csv
from dataclasses import dataclass
from decimal import Decimal, InvalidOperation
from pathlib import Path
from typing import Optional

import os
import sys
import shutil


# Ensure Django is set up
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "fitmatrix.settings")
import django  # type: ignore  # noqa: E402

django.setup()

from django.utils.text import slugify  # noqa: E402
from places.models import Place  # noqa: E402


DEFAULT_CSV = Path("data to be injected") / "subset_all.csv"


@dataclass
class RowData:
    name: str
    address: str
    lat: Optional[Decimal]
    lng: Optional[Decimal]
    types: str
    osm_link: str
    image_link: str
    osm_type: str
    osm_id: str


def to_decimal(value: str | None) -> Optional[Decimal]:
    if value is None:
        return None
    value = value.strip()
    if value == "":
        return None
    try:
        return Decimal(value)
    except InvalidOperation:
        return None


def detect_city(address: str, default_city: str) -> str:
    text = (address or "").lower()
    for city in ("jakarta", "bogor", "depok", "tangerang", "bekasi"):
        if city in text:
            # Normalize capitalization (first letter uppercase, rest lowercase where applicable)
            return " ".join(s.capitalize() for s in city.split())
    if "dki jakarta" in text:
        return "Jakarta"
    return default_city


def parse_types_to_facility(types: str) -> str:
    t = (types or "").lower()
    # Strong signals first
    if "swimming_pool" in t or "sport:swimming" in t:
        return Place.FacilityType.SWIM
    if "pitch" in t or "stadium" in t:
        return Place.FacilityType.COURT
    if any(s in t for s in ("sport:tennis", "sport:basketball", "sport:futsal", "sport:soccer")):
        return Place.FacilityType.COURT
    if "outdoor" in t:
        return Place.FacilityType.OUTDOOR
    if "wellness" in t:
        return Place.FacilityType.WELLNESS
    if "sports_centre" in t or "sport:multi" in t:
        return Place.FacilityType.GYM
    return Place.FacilityType.GYM


def build_tags(types: str) -> str:
    # Convert 'leisure:stadium, sport:soccer' -> 'stadium,soccer'
    result: list[str] = []
    for part in (types or "").split(","):
        part = part.strip()
        if ":" in part:
            result.append(part.split(":", 1)[1].strip())
        elif part:
            result.append(part)
    # Deduplicate while preserving order
    seen = set()
    unique = []
    for item in result:
        if item and item not in seen:
            seen.add(item)
            unique.append(item)
    return ",".join(unique)


def find_images_for_types(base_dir: Path, types: str) -> list[Path]:
    """Return a list of image Paths for the given OSM types.

    It looks under 'data to be injected/images/leisure-<x>_sport-<y>' and
    returns all image files sorted by name.
    """
    leisure = None
    sport = None
    for part in (types or "").split(","):
        p = part.strip()
        if p.startswith("leisure:"):
            leisure = p.split(":", 1)[1]
        elif p.startswith("sport:"):
            sport = p.split(":", 1)[1]
    if not (leisure and sport):
        return []
    folder = f"leisure-{leisure}_sport-{sport}"
    candidate_dir = base_dir / folder
    if not (candidate_dir.exists() and candidate_dir.is_dir()):
        return []
    images: list[Path] = []
    for child in sorted(candidate_dir.iterdir()):
        if child.suffix.lower() in {".jpg", ".jpeg", ".png", ".webp", ".svg"}:
            images.append(child)
    return images


def ensure_copied_to_static(src: Path, *, slug: str, static_places_dir: Path) -> str:
    """Copy a source image into static/img/places and return the relative path.

    The returned value is suitable for Django's `{% static %}` usage, e.g. 'img/places/foo.jpg'.
    """
    if not src.exists() or not src.is_file():
        return ""
    static_places_dir.mkdir(parents=True, exist_ok=True)
    # Prefix with slug to reduce name collisions and keep deterministic mapping
    target_name = f"{slug}-{src.name}"
    target = static_places_dir / target_name
    if not target.exists():
        shutil.copy2(src, target)
    return f"img/places/{target_name}"


def upsert_place(
    row: RowData, *, default_city: str, image_base: Path, dry_run: bool = False
) -> tuple[str, Place | None]:
    name = (row.name or "").strip()
    if not name:
        return ("skipped: missing name", None)

    city = detect_city(row.address or "", default_city)
    facility_type = parse_types_to_facility(row.types)
    tags = build_tags(row.types)

    slug = slugify(name) or None

    # Prepare images
    hero_image = (row.image_link or "").strip()
    gallery_images: list[str] = []
    static_places_dir = Path("static") / "img" / "places"

    if hero_image and "://" in hero_image:
        # External URL, leave as-is and skip local gallery
        pass
    else:
        # Find candidate local images and copy them under static/img/places
        candidates = find_images_for_types(image_base, row.types)
        if candidates and slug:
            mapped: list[str] = []
            for p in candidates[:3]:
                # Build the would-be relative path
                rel_path = f"img/places/{slug}-{p.name}"
                mapped.append(rel_path)
                if not dry_run:
                    ensure_copied_to_static(p, slug=slug, static_places_dir=static_places_dir)
            if mapped:
                hero_image = mapped[0]
                gallery_images = mapped[1:]

    # Try to find an existing place by slug or by name+address+city
    existing: Optional[Place] = None
    if slug:
        existing = Place.objects.filter(slug=slug).first()
    if not existing:
        existing = (
            Place.objects.filter(name=name, address=row.address or "", city=city).first()
        )

    data = dict(
        tagline="",
        # Avoid placing OSM link in description/summary.
        summary="",
        tags=tags,
        address=row.address or "",
        city=city,
        latitude=row.lat,
        longitude=row.lng,
        facility_type=facility_type,
        amenities=[],
        hero_image=hero_image,
        gallery=gallery_images,
        is_free=True,
        price=None,
        is_active=True,
    )

    action = "updated" if existing else "created"
    if dry_run:
        return (f"{action} (dry-run): {name}", existing)

    if existing:
        for k, v in data.items():
            setattr(existing, k, v)
        existing.save()
        return (f"updated: {name}", existing)
    else:
        place = Place(name=name, **data)
        place.save()
        return (f"created: {name}", place)


def read_rows(csv_path: Path) -> list[RowData]:
    rows: list[RowData] = []
    with csv_path.open(newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for i, raw in enumerate(reader, start=1):
            rows.append(
                RowData(
                    name=(raw.get("name") or "").strip(),
                    address=(raw.get("address") or "").strip(),
                    lat=to_decimal(raw.get("lat")),
                    lng=to_decimal(raw.get("lng")),
                    types=(raw.get("types") or "").strip(),
                    osm_link=(raw.get("osm_link") or "").strip(),
                    image_link=(raw.get("image_link") or "").strip(),
                    osm_type=(raw.get("osm_type") or "").strip(),
                    osm_id=(raw.get("osm_id") or "").strip(),
                )
            )
    return rows


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Inject places from CSV into the database (editable via Django admin)."
    )
    parser.add_argument(
        "--csv",
        type=str,
        default=str(DEFAULT_CSV),
        help="Path to CSV file (default: data to be injected/subset_all.csv)",
    )
    parser.add_argument(
        "--default-city",
        type=str,
        default="Jakarta",
        help="City to use when it cannot be detected from the address.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Parse and show actions without writing to the database.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=0,
        help="Only process the first N rows (0 = all).",
    )

    args = parser.parse_args(argv)
    csv_path = Path(args.csv)
    if not csv_path.exists():
        print(f"CSV not found: {csv_path}")
        return 1

    image_base = Path("data to be injected") / "images"

    rows = read_rows(csv_path)
    if args.limit and args.limit > 0:
        rows = rows[: args.limit]

    created = 0
    updated = 0
    skipped = 0
    for row in rows:
        msg, _place = upsert_place(
            row,
            default_city=args.default_city,
            image_base=image_base,
            dry_run=args.dry_run,
        )
        print(msg)
        if msg.startswith("created"):
            created += 1
        elif msg.startswith("updated"):
            updated += 1
        else:
            skipped += 1

    mode = "DRY-RUN" if args.dry_run else "APPLIED"
    print("-" * 40)
    print(f"{mode} summary -> created: {created}, updated: {updated}, skipped: {skipped}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

from __future__ import annotations

from pathlib import Path
from tempfile import TemporaryDirectory

from django.test import TestCase

from accounts.management.commands.seed_demo import Command
from places.models import Place


class SeedDemoCommandTests(TestCase):
    def test_resolve_places_seed_paths_prefers_to_be_seeded(self) -> None:
        command = Command()
        with TemporaryDirectory() as tmpdir:
            base_dir = Path(tmpdir)

            fallback_dir = base_dir / "data" / "places"
            fallback_images = fallback_dir / "images"
            fallback_images.mkdir(parents=True)
            (fallback_images / "fallback.svg").write_text("<svg></svg>")
            (fallback_dir / "places.csv").write_text("name,slug\n")

            preferred_dir = base_dir / "data" / "places" / "to_be_seeded"
            preferred_images = preferred_dir / "images"
            preferred_images.mkdir(parents=True)
            (preferred_images / "preferred.svg").write_text("<svg></svg>")
            (preferred_dir / "places.csv").write_text("name,slug\n")

            _, csv_path, images_dir = command.resolve_places_seed_paths(base_dir)

            self.assertEqual(csv_path, preferred_dir / "places.csv")
            self.assertEqual(images_dir, preferred_images)

    def test_sync_places_from_csv_uses_seed_folder(self) -> None:
        command = Command()
        Place.objects.all().delete()

        with TemporaryDirectory() as tmpdir:
            base_dir = Path(tmpdir)
            dataset_dir = base_dir / "data" / "places" / "to_be_seeded"
            images_dir = dataset_dir / "images"
            images_dir.mkdir(parents=True)

            hero_image = images_dir / "test.svg"
            hero_image.write_text("<svg xmlns=\"http://www.w3.org/2000/svg\"></svg>")

            csv_path = dataset_dir / "places.csv"
            header = (
                "name,slug,tagline,summary,tags,address,city,latitude,longitude,facility_type,"
                "amenities,highlight_score,accent_color,hero_image,gallery,is_free,price,rating_avg,likes,is_active\n"
            )
            row = (
                '"Test Place",test-place,"Power circuits","Detailed summary","strength,conditioning",'
                '"Jl. Sudirman 1","Jakarta",-6.2,106.8,GYM,"Rig|Rope",7,#123456,test.svg,"test.svg|test.svg",FALSE,150000,4.5,10,TRUE\n'
            )
            csv_path.write_text(header + row)

            places, dataset_label = command.sync_places_from_csv(base_dir=base_dir)

            self.assertEqual(dataset_label, "data/places/to_be_seeded/places.csv")
            self.assertEqual(len(places), 1)

            place = Place.objects.get(slug="test-place")
            self.assertEqual(place.name, "Test Place")
            self.assertEqual(place.hero_image, "img/places/test.svg")
            self.assertEqual(place.amenities, ["Rig", "Rope"])

            copied = base_dir / "static" / "img" / "places" / "test.svg"
            self.assertTrue(copied.exists())

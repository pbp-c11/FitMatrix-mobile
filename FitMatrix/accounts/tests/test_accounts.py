from __future__ import annotations

import io
import json

from django.contrib.auth import get_user_model
from django.core.cache import cache
from django.core.exceptions import ValidationError
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import Client, TestCase
from django.urls import reverse

from accounts.models import ActivityLog, WishlistCollection, WishlistItem
from places.models import Place

User = get_user_model()


class AccountsTests(TestCase):
    def setUp(self) -> None:
        self.client = Client()
        self.password = "Pass12345!"
        self.user = User.objects.create_user(
            username="regular",
            password=self.password,
            email="regular@example.com",
        )

    def test_email_uniqueness_validation(self) -> None:
        duplicate = User(username="other", email="regular@example.com")
        with self.assertRaises(ValidationError):
            duplicate.full_clean()

    def test_login_success_and_activity_logged(self) -> None:
        response = self.client.post(
            reverse("accounts:login"),
            {"identifier": self.user.username, "password": self.password},
            follow=True,
        )
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.context["user"].is_authenticated)
        self.assertTrue(
            ActivityLog.objects.filter(
                user=self.user, type=ActivityLog.Types.LOGIN
            ).exists()
        )

    def test_login_throttled_after_multiple_failures(self) -> None:
        cache.clear()
        url = reverse("accounts:login")
        for _ in range(5):
            response = self.client.post(url, {"identifier": self.user.username, "password": "wrong"})
        self.assertContains(response, "Invalid credentials", status_code=200)
        key = f"login_attempts:{self.user.username}:{'127.0.0.1'}"
        self.assertGreaterEqual(cache.get(key, 0), 5)

    def test_profile_update_with_avatar(self) -> None:
        self.client.login(username=self.user.username, password=self.password)
        image = io.BytesIO()
        from PIL import Image

        Image.new("RGB", (100, 100), color="red").save(image, format="JPEG")
        image.seek(0)
        upload = SimpleUploadedFile("avatar.jpg", image.read(), content_type="image/jpeg")
        response = self.client.post(
            reverse("accounts:profile-edit"),
            {"display_name": "Updated", "email": "regular@example.com", "avatar": upload},
            follow=True,
        )
        self.assertEqual(response.status_code, 200)
        self.user.refresh_from_db()
        self.assertEqual(self.user.display_name, "Updated")
        self.assertTrue(self.user.avatar.name)

    def test_wishlist_validation_and_toggle(self) -> None:
        item = WishlistItem(user=self.user)
        with self.assertRaises(ValidationError):
            item.full_clean()
        place = Place.objects.create(
            name="Studio",
            address="Jl. Sudirman",
            city="Jakarta",
            is_free=True,
        )
        self.client.login(username=self.user.username, password=self.password)
        response = self.client.post(
            reverse("wishlist:toggle", args=("place", place.id)),
            HTTP_X_REQUESTED_WITH="XMLHttpRequest",
        )
        self.assertJSONEqual(response.content, {"status": "added"})
        self.assertTrue(WishlistItem.objects.filter(user=self.user, place=place).exists())
        response = self.client.post(
            reverse("wishlist:toggle", args=("place", place.id)),
            HTTP_X_REQUESTED_WITH="XMLHttpRequest",
        )
        self.assertJSONEqual(response.content, {"status": "removed"})

    def test_create_collection_and_add_place(self) -> None:
        place = Place.objects.create(
            name="Ride Lab",
            address="Jl. Senopati",
            city="Jakarta",
            is_free=True,
        )
        self.client.login(username=self.user.username, password=self.password)
        payload = {
            "name": "Morning Crew",
            "description": "Cycling spots",
            "place_id": place.id,
        }
        response = self.client.post(
            reverse("accounts:create-collection"),
            data=json.dumps(payload),
            content_type="application/json",
            HTTP_X_REQUESTED_WITH="XMLHttpRequest",
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["status"], "added")
        collection = WishlistCollection.objects.get(user=self.user, name="Morning Crew")
        self.assertEqual(collection.items.count(), 1)
        self.assertTrue(WishlistItem.objects.filter(user=self.user, place=place).exists())

    def test_admin_permission_required(self) -> None:
        self.client.login(username=self.user.username, password=self.password)
        response = self.client.get(reverse("admin-console"))
        self.assertEqual(response.status_code, 302)
        admin_user = User.objects.create_user(
            username="admin",
            password="AdminPass123!",
            email="admin@example.com",
            role=User.Roles.ADMIN,
        )
        self.client.logout()
        self.client.login(username="admin", password="AdminPass123!")
        response = self.client.get(reverse("admin-console"))
        self.assertEqual(response.status_code, 200)

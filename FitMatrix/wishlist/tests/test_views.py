from __future__ import annotations

from django.contrib.auth import get_user_model
from django.test import Client, TestCase
from django.urls import reverse

from accounts.models import ActivityLog, WishlistItem
from places.models import Place
from scheduling.models import Trainer

User = get_user_model()


class WishlistViewTests(TestCase):
    def setUp(self) -> None:
        self.client = Client()
        self.user = User.objects.create_user(
            username="collector",
            email="collector@example.com",
            password="StrongPass123",
        )
        self.client.force_login(self.user)
        self.place = Place.objects.create(
            name="Lift Lab",
            address="Jl. Pahlawan",
            city="Jakarta",
            is_free=True,
        )
        self.trainer = Trainer.objects.create(
            name="Coach Prime",
            specialties="Strength",
            bio="",
        )

    def test_toggle_place_creates_and_removes_item_with_logs(self) -> None:
        url = reverse("wishlist:toggle", args=("place", self.place.pk))
        response = self.client.post(url, HTTP_X_REQUESTED_WITH="XMLHttpRequest")
        self.assertJSONEqual(response.content, {"status": "added"})
        self.assertTrue(WishlistItem.objects.filter(user=self.user, place=self.place).exists())
        log = ActivityLog.objects.filter(
            user=self.user, type=ActivityLog.Types.WISHLIST_ADDED
        ).latest("created_at")
        self.assertEqual(log.meta, {"kind": "place", "id": self.place.pk})

        response = self.client.post(url, HTTP_X_REQUESTED_WITH="XMLHttpRequest")
        self.assertJSONEqual(response.content, {"status": "removed"})
        self.assertFalse(WishlistItem.objects.filter(user=self.user, place=self.place).exists())
        removal_log = ActivityLog.objects.filter(
            user=self.user, type=ActivityLog.Types.WISHLIST_REMOVED
        ).latest("created_at")
        self.assertEqual(removal_log.meta["kind"], "place")

    def test_toggle_trainer_path(self) -> None:
        url = reverse("wishlist:toggle", args=("trainer", self.trainer.pk))
        response = self.client.post(url, HTTP_X_REQUESTED_WITH="XMLHttpRequest")
        self.assertJSONEqual(response.content, {"status": "added"})
        self.assertTrue(WishlistItem.objects.filter(user=self.user, trainer=self.trainer).exists())
        log = ActivityLog.objects.filter(
            user=self.user, type=ActivityLog.Types.WISHLIST_ADDED
        ).latest("created_at")
        self.assertEqual(log.meta, {"kind": "trainer", "id": self.trainer.pk})

    def test_invalid_kind_returns_error(self) -> None:
        response = self.client.post(
            reverse("wishlist:toggle", args=("unknown", self.place.pk)),
            HTTP_X_REQUESTED_WITH="XMLHttpRequest",
        )
        self.assertEqual(response.status_code, 400)
        self.assertIn("error", response.json())

    def test_list_view_returns_paginated_items(self) -> None:
        WishlistItem.objects.create(user=self.user, place=self.place)
        response = self.client.get(reverse("wishlist:list"))
        self.assertEqual(response.status_code, 200)
        page_obj = response.context["page_obj"]
        self.assertEqual(page_obj.paginator.count, 1)
        self.assertEqual(list(page_obj.object_list)[0].place, self.place)

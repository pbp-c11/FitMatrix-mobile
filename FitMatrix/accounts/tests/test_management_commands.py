from __future__ import annotations

from io import StringIO

from django.contrib.auth import get_user_model
from django.core.management import CommandError, call_command
from django.test import TestCase


class CreateAdminCommandTests(TestCase):
    def setUp(self) -> None:
        self.User = get_user_model()

    def test_creates_admin_user_with_attributes(self) -> None:
        out = StringIO()
        call_command(
            "create_admin",
            username="boss",
            email="Boss@Example.com",
            password="StrongPass123!",
            display_name="Boss Man",
            stdout=out,
        )
        user = self.User.objects.get(username="boss")
        self.assertEqual(user.email, "boss@example.com")
        self.assertEqual(user.display_name, "Boss Man")
        self.assertTrue(user.is_staff)
        self.assertTrue(user.is_superuser)
        self.assertTrue(user.check_password("StrongPass123!"))
        self.assertEqual(user.role, self.User.Roles.ADMIN)
        self.assertIn("Admin user created: boss", out.getvalue())

    def test_updates_existing_admin(self) -> None:
        user = self.User.objects.create_user(
            username="boss",
            email="old@example.com",
            password="OldPass123!",
            display_name="Old Boss",
        )
        out = StringIO()
        call_command(
            "create_admin",
            username="boss",
            email="newboss@example.com",
            password="NewPass123!",
            display_name="New Boss",
            stdout=out,
        )
        user.refresh_from_db()
        self.assertEqual(user.email, "newboss@example.com")
        self.assertEqual(user.display_name, "New Boss")
        self.assertTrue(user.check_password("NewPass123!"))
        self.assertIn("Admin user updated: boss", out.getvalue())

    def test_blank_username_not_allowed(self) -> None:
        with self.assertRaisesMessage(CommandError, "Username cannot be empty."):
            call_command(
                "create_admin",
                username=" ",
                password="Whatever123!",
            )

    def test_password_required_for_non_interactive(self) -> None:
        with self.assertRaisesMessage(
            CommandError,
            "Password is required. Provide --password or FITMATRIX_ADMIN_PASSWORD.",
        ):
            call_command("create_admin", username="no-password")

    def test_duplicate_email_raises_error(self) -> None:
        self.User.objects.create_user(
            username="existing",
            email="duplicate@example.com",
            password="StrongPass123!",
        )
        with self.assertRaisesMessage(
            CommandError,
            "Another user already uses that email address.",
        ):
            call_command(
                "create_admin",
                username="boss",
                email="duplicate@example.com",
                password="StrongPass123!",
            )

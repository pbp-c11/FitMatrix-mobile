from __future__ import annotations

import os

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand, CommandError


class Command(BaseCommand):
    help = "Create or update an administrator with full dashboard access."

    def add_arguments(self, parser):
        parser.add_argument("--username", default="admin", help="Username for the admin account.")
        parser.add_argument("--email", default=None, help="Email address for the admin user.")
        parser.add_argument("--password", default=None, help="Password for the admin user.")
        parser.add_argument(
            "--display-name",
            dest="display_name",
            default=None,
            help="Optional display name shown in the dashboard.",
        )

    def handle(self, *args, **options):
        username: str = options["username"].strip()
        if not username:
            raise CommandError("Username cannot be empty.")

        password = options.get("password") or os.environ.get("FITMATRIX_ADMIN_PASSWORD")
        if not password:
            raise CommandError("Password is required. Provide --password or FITMATRIX_ADMIN_PASSWORD.")

        User = get_user_model()
        email_option = options.get("email")
        email = (email_option or f"{username}@example.com").strip().lower()
        display_name_option = options.get("display_name")
        display_name = display_name_option.strip() if display_name_option else username

        try:
            user = User.objects.get(username=username)
            created = False
        except User.DoesNotExist:
            user = User(username=username, email=email, display_name=display_name)
            created = True
        except User.MultipleObjectsReturned as exc:  # pragma: no cover - sanity guard
            raise CommandError("Multiple users found with that username.") from exc

        conflict = (
            User.objects.exclude(pk=user.pk)
            .filter(email__iexact=email)
            .exists()
        )
        if conflict:
            raise CommandError("Another user already uses that email address.")

        user.email = email
        user.display_name = display_name
        user.role = user.Roles.ADMIN  # type: ignore[assignment]
        user.is_staff = True
        user.is_superuser = True
        user.set_password(password)
        user.save()

        action = "created" if created else "updated"
        self.stdout.write(self.style.SUCCESS(f"Admin user {action}: {user.username}"))

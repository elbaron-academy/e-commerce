"""
Creates or updates a superuser that signs in with an email address.

    python manage.py ensure_admin --email admin@example.com --password 'S3cure!pass'
    ADMIN_PASSWORD='S3cure!pass' python manage.py ensure_admin --email admin@example.com
"""

import os

from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from django.core.management.base import BaseCommand, CommandError

from apps.accounts.models import User
from apps.core.text import normalize_phone

PLACEHOLDER_PHONE_PREFIX = "0100000"


class Command(BaseCommand):
    help = "Creates or updates an admin account that signs in with email + password."

    def add_arguments(self, parser):
        parser.add_argument("--email", required=True)
        parser.add_argument("--password", help="Or set ADMIN_PASSWORD in the environment")
        parser.add_argument("--phone", help="Optional. A placeholder is used if empty (staff can't use OTP login).")
        parser.add_argument("--name", default="Admin")

    def handle(self, *args, email, password, phone, name, **options):
        email = email.strip().lower()
        password = password or os.environ.get("ADMIN_PASSWORD")
        if not password:
            raise CommandError("Give --password or set ADMIN_PASSWORD.")

        user = User.objects.filter(email__iexact=email, is_staff=True).first()
        created = user is None
        if created:
            user = User(email=email, name=name, phone=normalize_phone(phone) if phone else self._placeholder_phone())
        elif phone:
            user.phone = normalize_phone(phone)
        user.is_staff = user.is_superuser = user.is_active = True
        user.set_password(password)
        user.full_clean(exclude=["password"])
        user.save()

        try:
            validate_password(password, user)
        except ValidationError as exc:
            self.stderr.write(self.style.WARNING("Weak password: " + " ".join(exc.messages) + " Change it soon."))
        self.stdout.write(
            self.style.SUCCESS(
                f"{'Created' if created else 'Updated'} admin {email} (sign in at /admin/ with this email)"
            )
        )

    @staticmethod
    def _placeholder_phone() -> str:
        for n in range(10_000):
            candidate = f"{PLACEHOLDER_PHONE_PREFIX}{n:04d}"
            if not User.objects.filter(phone=candidate).exists():
                return candidate
        raise CommandError("No free placeholder phone; pass --phone.")

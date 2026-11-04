from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.core.validators import RegexValidator
from django.db import models
from django.utils import timezone

from apps.core.models import TimeStampedModel
from apps.core.text import normalize_phone

PHONE_REGEX = r"^01[0125]\d{8}$"
phone_validator = RegexValidator(PHONE_REGEX, "Enter a valid Egyptian mobile number (01xxxxxxxxx).")


class UserManager(BaseUserManager):
    use_in_migrations = True

    def create_user(self, phone, password=None, **extra):
        user = self.model(phone=normalize_phone(phone), **extra)
        if password:
            user.set_password(password)
        else:
            user.set_unusable_password()
        user.full_clean(exclude=["password"])
        user.save(using=self._db)
        return user

    def create_superuser(self, phone, password=None, **extra):
        extra.update(is_staff=True, is_superuser=True)
        return self.create_user(phone, password, **extra)


class User(AbstractBaseUser, PermissionsMixin):
    """Customers sign in with phone + OTP. Staff use phone + password."""

    class Language(models.TextChoices):
        AR = "ar", "العربية"
        EN = "en", "English"

    phone = models.CharField(max_length=11, unique=True, validators=[phone_validator])
    name = models.CharField(max_length=80, blank=True)
    email = models.EmailField(blank=True)
    language = models.CharField(max_length=2, choices=Language.choices, default=Language.AR)
    is_staff = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    notes = models.TextField(blank=True, help_text="Internal notes, visible to staff only")
    date_joined = models.DateTimeField(default=timezone.now)

    objects = UserManager()

    USERNAME_FIELD = "phone"
    REQUIRED_FIELDS = []

    class Meta:
        ordering = ["-date_joined"]

    def __str__(self):
        return f"{self.name or 'Customer'} ({self.phone})"


class OTPCode(models.Model):
    """One-time login code. Only a hash of the code is stored."""

    phone = models.CharField(max_length=11, db_index=True)
    code_hash = models.CharField(max_length=64)
    purpose = models.CharField(max_length=20, default="login")
    attempts = models.PositiveSmallIntegerField(default=0)
    expires_at = models.DateTimeField()
    consumed_at = models.DateTimeField(null=True, blank=True)
    ip = models.GenericIPAddressField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "OTP code"

    def __str__(self):
        return f"{self.phone} · {self.purpose}"


class Address(TimeStampedModel):
    """Customer delivery address (BE-405). One default per customer."""

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="addresses")
    label = models.CharField(max_length=40, blank=True)
    zone = models.ForeignKey("shipping.Zone", on_delete=models.PROTECT, related_name="addresses")
    area = models.CharField(max_length=80)
    street = models.CharField(max_length=120)
    building = models.CharField(max_length=20)
    floor = models.CharField(max_length=10, blank=True)
    apartment = models.CharField(max_length=10, blank=True)
    notes = models.CharField(max_length=200, blank=True)
    lat = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    lng = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    is_default = models.BooleanField(default=False)

    class Meta:
        ordering = ["-is_default", "-created_at"]
        verbose_name_plural = "addresses"
        constraints = [
            models.UniqueConstraint(
                fields=["user"], condition=models.Q(is_default=True), name="one_default_address_per_user"
            ),
        ]

    def __str__(self):
        return f"{self.street} {self.building}, {self.area}"

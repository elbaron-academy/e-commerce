from decimal import Decimal

from django.conf import settings
from django.core.validators import MinValueValidator
from django.db import models

from apps.core.models import TimeStampedModel


class Coupon(TimeStampedModel):
    """Promo code (BE-404). One coupon per order."""

    class Type(models.TextChoices):
        PERCENT = "percent", "Percentage off"
        FIXED = "fixed", "Fixed amount off"
        FREE_DELIVERY = "free_delivery", "Free delivery"

    code = models.CharField(max_length=30, unique=True)
    description = models.CharField(max_length=200, blank=True)
    type = models.CharField(max_length=20, choices=Type.choices)
    value = models.DecimalField(
        max_digits=10, decimal_places=2, default=Decimal("0"), validators=[MinValueValidator(Decimal("0"))]
    )
    min_subtotal = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal("0"))
    max_discount = models.DecimalField(
        max_digits=10, decimal_places=2, null=True, blank=True, help_text="Cap for percentage coupons"
    )
    starts_at = models.DateTimeField(null=True, blank=True)
    ends_at = models.DateTimeField(null=True, blank=True)
    usage_limit = models.PositiveIntegerField(null=True, blank=True, help_text="Total uses; empty = unlimited")
    per_customer_limit = models.PositiveIntegerField(
        null=True, blank=True, default=1, help_text="Uses per customer; empty = unlimited"
    )
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return self.code

    def save(self, *args, **kwargs):
        self.code = self.code.strip().upper()
        super().save(*args, **kwargs)


class CouponRedemption(TimeStampedModel):
    coupon = models.ForeignKey(Coupon, on_delete=models.PROTECT, related_name="redemptions")
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="coupon_redemptions")
    order = models.OneToOneField("orders.Order", on_delete=models.CASCADE, related_name="coupon_redemption")
    discount = models.DecimalField(max_digits=10, decimal_places=2)

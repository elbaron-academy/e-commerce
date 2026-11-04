from decimal import Decimal

from django.db import models

from apps.core.models import TimeStampedModel


class Zone(TimeStampedModel):
    """Delivery area (governorate) with its delivery fee (BE-406)."""

    code = models.SlugField(unique=True)
    name_ar = models.CharField(max_length=80)
    name_en = models.CharField(max_length=80)
    fee = models.DecimalField(max_digits=10, decimal_places=2)
    is_active = models.BooleanField(default=True)
    sort_order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ["sort_order", "id"]

    def __str__(self):
        return self.name_en


class DeliveryWindow(TimeStampedModel):
    """A daily delivery time window with a maximum number of orders."""

    start_time = models.TimeField()
    end_time = models.TimeField()
    capacity = models.PositiveIntegerField(default=20, help_text="Max orders per day in this window")
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["start_time"]

    def __str__(self):
        return f"{self.start_time:%H:%M}-{self.end_time:%H:%M}"


class StoreSettings(models.Model):
    """Store-wide rules (single row). Edit from the admin dashboard."""

    free_delivery_threshold = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal("500"))
    min_order = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal("100"))
    cod_limit = models.DecimalField(
        max_digits=10, decimal_places=2, default=Decimal("3000"), help_text="Max total for cash on delivery"
    )
    default_zone = models.ForeignKey(Zone, null=True, blank=True, on_delete=models.SET_NULL, related_name="+")
    slot_days = models.PositiveSmallIntegerField(default=3, help_text="How many days of slots to offer")
    slot_lead_hours = models.PositiveSmallIntegerField(
        default=2, help_text="Earliest slot starts this many hours from now"
    )
    express_enabled = models.BooleanField(default=True)
    express_start_hour = models.PositiveSmallIntegerField(default=8)
    express_end_hour = models.PositiveSmallIntegerField(default=22)
    pickup_enabled = models.BooleanField(default=True)
    pickup_name_ar = models.CharField(max_length=120, default="روكت مول، الدور الأرضي")
    pickup_name_en = models.CharField(max_length=120, default="Rocket Mall, ground floor")
    pickup_address_ar = models.CharField(max_length=200, default="استلم طلبك من مكتب الاستلام جنب البوابة الرئيسية")
    pickup_address_en = models.CharField(
        max_length=200, default="Collect your order at the pickup desk by the main gate"
    )
    pickup_hours_ar = models.CharField(max_length=120, default="يوميًا من 9 الصبح لـ 11 بالليل")
    pickup_hours_en = models.CharField(max_length=120, default="Daily, 9 AM to 11 PM")

    class Meta:
        verbose_name = "store settings"
        verbose_name_plural = "store settings"

    def __str__(self):
        return "Store settings"

    def save(self, *args, **kwargs):
        self.pk = 1
        super().save(*args, **kwargs)

    @classmethod
    def load(cls) -> "StoreSettings":
        obj, _ = cls.objects.get_or_create(pk=1)
        return obj

    def resolve_zone(self, code: str | None) -> Zone | None:
        zones = Zone.objects.filter(is_active=True)
        return (code and zones.filter(code=code).first()) or self.default_zone or zones.first()

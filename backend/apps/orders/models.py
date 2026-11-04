from django.conf import settings
from django.db import models

from apps.core.models import TimeStampedModel


class Order(TimeStampedModel):
    class Status(models.TextChoices):
        PENDING_PAYMENT = "pending_payment", "Awaiting payment"
        PLACED = "placed", "Placed"
        CONFIRMED = "confirmed", "Confirmed"
        PREPARING = "preparing", "Preparing"
        OUT_FOR_DELIVERY = "out_for_delivery", "Out for delivery"
        READY_FOR_PICKUP = "ready_for_pickup", "Ready for pickup"
        DELIVERED = "delivered", "Delivered"
        CANCELLED = "cancelled", "Cancelled"

    class Method(models.TextChoices):
        DELIVERY = "delivery", "Home delivery"
        PICKUP = "pickup", "Pickup at Rocket Mall"

    class PaymentMethod(models.TextChoices):
        COD = "cod", "Cash on delivery"
        CARD = "card", "Card"
        WALLET = "wallet", "Mobile wallet"

    class PaymentStatus(models.TextChoices):
        PENDING = "pending", "Pending"
        PAID = "paid", "Paid"
        FAILED = "failed", "Failed"
        COD = "cod", "Pay on delivery"
        REFUNDED = "refunded", "Refunded"

    # Allowed status changes (BE-601). Anything else is rejected.
    TRANSITIONS = {
        Status.PENDING_PAYMENT: {Status.PLACED, Status.CANCELLED},
        Status.PLACED: {Status.CONFIRMED, Status.CANCELLED},
        Status.CONFIRMED: {Status.PREPARING, Status.CANCELLED},
        Status.PREPARING: {Status.OUT_FOR_DELIVERY, Status.READY_FOR_PICKUP, Status.CANCELLED},
        Status.OUT_FOR_DELIVERY: {Status.DELIVERED},
        Status.READY_FOR_PICKUP: {Status.DELIVERED, Status.CANCELLED},
        Status.DELIVERED: set(),
        Status.CANCELLED: set(),
    }
    DELIVERY_STEPS = [Status.PLACED, Status.CONFIRMED, Status.PREPARING, Status.OUT_FOR_DELIVERY, Status.DELIVERED]
    PICKUP_STEPS = [Status.PLACED, Status.CONFIRMED, Status.PREPARING, Status.READY_FOR_PICKUP, Status.DELIVERED]

    number = models.CharField(max_length=20, unique=True, null=True, blank=True)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="orders")
    status = models.CharField(max_length=20, choices=Status.choices, db_index=True)
    method = models.CharField(max_length=10, choices=Method.choices)
    payment_method = models.CharField(max_length=10, choices=PaymentMethod.choices)
    payment_status = models.CharField(max_length=10, choices=PaymentStatus.choices)
    subtotal = models.DecimalField(max_digits=12, decimal_places=2)
    coupon_discount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    delivery_fee = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    total = models.DecimalField(max_digits=12, decimal_places=2)
    coupon = models.ForeignKey(
        "promotions.Coupon", null=True, blank=True, on_delete=models.SET_NULL, related_name="orders"
    )
    coupon_code = models.CharField(max_length=30, blank=True)
    notes = models.CharField(max_length=300, blank=True)
    language = models.CharField(max_length=2, default="ar")
    # Snapshot of the address at order time (BE-501), so later edits don't change old orders.
    zone_code = models.CharField(max_length=50, blank=True)
    address = models.JSONField(null=True, blank=True)
    slot_date = models.DateField(null=True, blank=True, db_index=True)
    slot_start = models.TimeField(null=True, blank=True)
    slot_end = models.TimeField(null=True, blank=True)
    is_express = models.BooleanField(default=False)
    placed_at = models.DateTimeField(null=True, blank=True)
    reserved_until = models.DateTimeField(
        null=True, blank=True, db_index=True, help_text="Stock is held until this time while awaiting payment"
    )
    cancelled_at = models.DateTimeField(null=True, blank=True)
    delivered_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [models.Index(fields=["status", "created_at"])]

    def __str__(self):
        return self.number or f"Order #{self.pk}"

    @property
    def steps(self) -> list[str]:
        return self.PICKUP_STEPS if self.method == self.Method.PICKUP else self.DELIVERY_STEPS

    def allowed_transitions(self) -> set[str]:
        allowed = set(self.TRANSITIONS.get(self.status, set()))
        if self.method == self.Method.PICKUP:
            allowed.discard(self.Status.OUT_FOR_DELIVERY)
        else:
            allowed.discard(self.Status.READY_FOR_PICKUP)
        return allowed


class OrderItem(models.Model):
    """Product, price and quantity as they were when the order was placed."""

    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name="items")
    variant = models.ForeignKey("catalog.Variant", null=True, on_delete=models.SET_NULL, related_name="order_items")
    product = models.ForeignKey("catalog.Product", null=True, on_delete=models.SET_NULL, related_name="order_items")
    sku = models.CharField(max_length=40)
    product_slug = models.CharField(max_length=200)
    name_ar = models.CharField(max_length=200)
    name_en = models.CharField(max_length=200)
    variant_label_ar = models.CharField(max_length=60)
    variant_label_en = models.CharField(max_length=60)
    emoji = models.CharField(max_length=8, blank=True)
    color = models.CharField(max_length=7, blank=True)
    image_url = models.CharField(max_length=500, blank=True)
    sold_by_weight = models.BooleanField(default=False)
    qty = models.DecimalField(max_digits=10, decimal_places=3)
    unit_price = models.DecimalField(max_digits=10, decimal_places=2)
    original_unit_price = models.DecimalField(max_digits=10, decimal_places=2)
    line_total = models.DecimalField(max_digits=12, decimal_places=2)

    class Meta:
        ordering = ["id"]

    def __str__(self):
        return f"{self.sku} × {self.qty}"


class OrderStatusHistory(models.Model):
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name="history")
    status = models.CharField(max_length=20, choices=Order.Status.choices)
    note = models.CharField(max_length=300, blank=True)
    actor = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL, related_name="+"
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created_at", "id"]
        verbose_name_plural = "order status history"

    def __str__(self):
        return f"{self.order} → {self.status}"

from django.db import models

from apps.core.models import TimeStampedModel


class Payment(TimeStampedModel):
    class Status(models.TextChoices):
        PENDING = "pending"
        SUCCEEDED = "succeeded"
        FAILED = "failed"
        EXPIRED = "expired"
        REFUNDED = "refunded"

    order = models.ForeignKey("orders.Order", on_delete=models.PROTECT, related_name="payments")
    provider = models.CharField(max_length=30)
    method = models.CharField(max_length=10)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    currency = models.CharField(max_length=3, default="EGP")
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.PENDING, db_index=True)
    reference = models.CharField(max_length=64, unique=True, help_text="Our ID sent to the gateway")
    provider_transaction_id = models.CharField(max_length=100, blank=True)
    redirect_url = models.CharField(max_length=500, blank=True)
    needs_refund = models.BooleanField(default=False, help_text="Paid after the order was cancelled")
    payload = models.JSONField(default=dict, blank=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.provider} {self.reference} ({self.status})"


class WebhookEvent(TimeStampedModel):
    """Every gateway callback, stored once (idempotency key = provider + event_id)."""

    provider = models.CharField(max_length=30)
    event_id = models.CharField(max_length=100)
    payload = models.JSONField(default=dict)
    processed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        constraints = [models.UniqueConstraint(fields=["provider", "event_id"], name="unique_webhook_event")]

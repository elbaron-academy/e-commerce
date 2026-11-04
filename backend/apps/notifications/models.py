from django.conf import settings
from django.db import models

from apps.core.models import TimeStampedModel


class NotificationLog(TimeStampedModel):
    """Every message we send (AD-501), with its status."""

    class Channel(models.TextChoices):
        SMS = "sms"
        EMAIL = "email"
        PUSH = "push"

    class Status(models.TextChoices):
        QUEUED = "queued"
        SENT = "sent"
        FAILED = "failed"
        SKIPPED = "skipped"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL, related_name="notifications"
    )
    channel = models.CharField(max_length=10, choices=Channel.choices)
    event = models.CharField(max_length=40, db_index=True)
    recipient = models.CharField(max_length=200)
    subject = models.CharField(max_length=200, blank=True)
    body = models.TextField()
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.QUEUED, db_index=True)
    error = models.TextField(blank=True)

    class Meta:
        ordering = ["-created_at"]

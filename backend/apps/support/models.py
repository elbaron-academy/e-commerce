"""Support chat between a customer and the store's staff.

The customer sees one continuous chat. Behind it, messages are grouped into
conversations (tickets): a customer has at most one open conversation, staff
close it when the issue is solved, and the customer's next message opens a new one.
"""

import uuid

from django.conf import settings
from django.db import models
from django.db.models import Q

from apps.core.models import TimeStampedModel


def image_path(instance, filename: str) -> str:
    # Random names: chat photos are only reachable by whoever has the link.
    return f"support/{uuid.uuid4().hex}.jpg"


class Conversation(TimeStampedModel):
    class Status(models.TextChoices):
        OPEN = "open", "Open"
        CLOSED = "closed", "Closed"

    customer = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="conversations")
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.OPEN, db_index=True)
    assigned_to = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="assigned_conversations",
        limit_choices_to={"is_staff": True},
    )
    last_message = models.ForeignKey("Message", null=True, blank=True, on_delete=models.SET_NULL, related_name="+")
    last_message_at = models.DateTimeField(null=True, blank=True, db_index=True)
    # Read receipts: the id of the last message each side has seen.
    customer_last_read = models.PositiveBigIntegerField(default=0)
    staff_last_read = models.PositiveBigIntegerField(default=0)
    # Id of the last staff message the customer was reminded about by SMS.
    customer_reminded_upto = models.PositiveBigIntegerField(default=0)
    closed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-last_message_at", "-id"]
        constraints = [
            models.UniqueConstraint(
                fields=["customer"], condition=Q(status="open"), name="support_one_open_conversation_per_customer"
            )
        ]

    def __str__(self):
        return f"#{self.pk} {self.customer}"


class Message(models.Model):
    class Kind(models.TextChoices):
        TEXT = "text", "Message"
        # Shown as a line in the chat, e.g. "support ended this conversation".
        EVENT = "event", "Event"

    class Event(models.TextChoices):
        CLOSED = "closed", "Conversation closed"

    conversation = models.ForeignKey(Conversation, on_delete=models.CASCADE, related_name="messages")
    kind = models.CharField(max_length=10, choices=Kind.choices, default=Kind.TEXT)
    event = models.CharField(max_length=20, choices=Event.choices, blank=True)
    sender = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL, related_name="+"
    )
    from_staff = models.BooleanField(default=False)
    body = models.TextField(max_length=2000, blank=True)
    image = models.ImageField(
        upload_to=image_path, null=True, blank=True, width_field="image_width", height_field="image_height"
    )
    image_width = models.PositiveIntegerField(null=True, blank=True)
    image_height = models.PositiveIntegerField(null=True, blank=True)
    order = models.ForeignKey(
        "orders.Order", null=True, blank=True, on_delete=models.SET_NULL, related_name="support_messages"
    )
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        ordering = ["id"]
        indexes = [models.Index(fields=["conversation", "id"])]

    def __str__(self):
        return self.body[:60] or self.event or "photo"

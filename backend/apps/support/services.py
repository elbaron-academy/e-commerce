"""Chat rules: sending, closing, read receipts, unread counts and reply reminders."""

from datetime import timedelta

from django.conf import settings
from django.db import IntegrityError, transaction
from django.db.models import F, Max
from django.utils import timezone

from apps.core.exceptions import ApiError
from apps.core.i18n import t

from .images import process_image
from .models import Conversation, Message

# How many messages a chat screen loads at once.
PAGE_SIZE = 30


def _clean(body: str | None, image) -> str:
    body = (body or "").strip()
    if not body and not image:
        raise ApiError(t("اكتب رسالة أو ابعت صورة.", "Write a message or send a photo."), field="body")
    return body


def _add(conversation: Conversation, **fields) -> Message:
    message = Message.objects.create(conversation=conversation, **fields)
    conversation.last_message = message
    conversation.last_message_at = message.created_at
    update = ["last_message", "last_message_at", "updated_at"]
    # Your own message counts as read.
    if message.from_staff:
        conversation.staff_last_read = message.pk
        update.append("staff_last_read")
    else:
        conversation.customer_last_read = message.pk
        update.append("customer_last_read")
    conversation.save(update_fields=update)
    return message


def send_customer_message(customer, *, body="", image=None, order=None, inbox_url="") -> Message:
    """Adds the customer's message to their open conversation, or starts a new one."""
    body = _clean(body, image)
    photo = process_image(image) if image else None
    for attempt in range(2):
        try:
            with transaction.atomic():
                conversation = Conversation.objects.filter(customer=customer, status=Conversation.Status.OPEN).first()
                created = conversation is None
                if created:
                    conversation = Conversation.objects.create(customer=customer)
                message = _add(conversation, sender=customer, body=body, image=photo, order=order)
            break
        except IntegrityError:
            # Two first messages at the same moment: the other one opened the conversation.
            if attempt:
                raise
    if created:
        alert_staff(conversation, message, inbox_url)
    return message


def send_staff_message(conversation: Conversation, staff, *, body="", image=None, order=None) -> Message:
    body = _clean(body, image)
    if conversation.status != Conversation.Status.OPEN:
        raise ApiError(
            t("المحادثة دي اتقفلت.", "This conversation is closed."), status_code=409, code="conversation_closed"
        )
    photo = process_image(image) if image else None
    with transaction.atomic():
        message = _add(conversation, sender=staff, from_staff=True, body=body, image=photo, order=order)
        if conversation.assigned_to_id is None:
            conversation.assigned_to = staff
            conversation.save(update_fields=["assigned_to"])
    return message


def close_conversation(conversation: Conversation, staff) -> Conversation:
    if conversation.status == Conversation.Status.CLOSED:
        return conversation
    with transaction.atomic():
        _add(conversation, kind=Message.Kind.EVENT, event=Message.Event.CLOSED, sender=staff, from_staff=True, body="")
        conversation.status = Conversation.Status.CLOSED
        conversation.closed_at = timezone.now()
        conversation.save(update_fields=["status", "closed_at", "updated_at"])
    return conversation


def reopen_conversation(conversation: Conversation) -> Conversation:
    if conversation.status == Conversation.Status.OPEN:
        return conversation
    others = Conversation.objects.filter(customer_id=conversation.customer_id, status=Conversation.Status.OPEN)
    if others.exists():
        raise ApiError(
            t("العميل عنده محادثة مفتوحة تانية.", "The customer already has another open conversation."),
            status_code=409,
            code="customer_has_open_conversation",
        )
    conversation.status = Conversation.Status.OPEN
    conversation.closed_at = None
    conversation.save(update_fields=["status", "closed_at", "updated_at"])
    return conversation


# ---- Reading ----


def customer_messages(customer):
    return Message.objects.filter(conversation__customer=customer).select_related("order", "sender")


def page(queryset, *, after=None, before=None) -> tuple[list[Message], bool]:
    """New messages after `after`, older ones before `before`, or the latest page.

    Returns the messages oldest first and whether older ones exist.
    """
    if after is not None:
        return list(queryset.filter(id__gt=after).order_by("id")[:200]), False
    if before is not None:
        queryset = queryset.filter(id__lt=before)
    latest = list(queryset.order_by("-id")[: PAGE_SIZE + 1])
    has_older = len(latest) > PAGE_SIZE
    return latest[:PAGE_SIZE][::-1], has_older


def mark_read_by_customer(customer, upto: int | None = None) -> None:
    latest = customer_messages(customer).aggregate(m=Max("id"))["m"] or 0
    upto = min(upto, latest) if upto else latest
    Conversation.objects.filter(customer=customer, customer_last_read__lt=upto).update(customer_last_read=upto)


def mark_read_by_staff(conversation: Conversation, upto: int | None = None) -> None:
    latest = conversation.messages.aggregate(m=Max("id"))["m"] or 0
    upto = min(upto, latest) if upto else latest
    Conversation.objects.filter(pk=conversation.pk, staff_last_read__lt=upto).update(staff_last_read=upto)


def customer_unread(customer) -> int:
    return Message.objects.filter(
        conversation__customer=customer,
        from_staff=True,
        kind=Message.Kind.TEXT,
        id__gt=F("conversation__customer_last_read"),
    ).count()


def staff_unread_filter():
    """Open conversations whose last message is the customer's and nobody on staff has read it."""
    return {
        "status": Conversation.Status.OPEN,
        "last_message__from_staff": False,
        "last_message_id__gt": F("staff_last_read"),
    }


# ---- Notifications ----


def alert_staff(conversation: Conversation, message: Message, inbox_url: str = "") -> None:
    """Emails STAFF_ALERT_EMAILS when a customer starts a new conversation."""
    if not settings.STAFF_ALERT_EMAILS:
        return
    from apps.notifications.services import notify

    customer = conversation.customer
    context = {
        "customer": customer.name or customer.phone,
        "phone": customer.phone,
        "message": message.body or "📷",
        "url": f"{inbox_url}#{conversation.pk}" if inbox_url else "",
    }

    def send():
        for email in settings.STAFF_ALERT_EMAILS:
            notify("support_new", email=email, lang="en", context=context, channels=("email",))

    transaction.on_commit(send)


def remind_unread_replies(now=None) -> int:
    """Texts customers who haven't read a staff reply after SUPPORT_REPLY_REMINDER_MINUTES.

    One reminder per batch of replies; replies older than a day are left alone.
    """
    minutes = settings.SUPPORT_REPLY_REMINDER_MINUTES
    if not minutes:
        return 0
    from apps.notifications.services import notify

    now = now or timezone.now()
    pending = (
        Message.objects.filter(
            from_staff=True,
            kind=Message.Kind.TEXT,
            created_at__lte=now - timedelta(minutes=minutes),
            created_at__gte=now - timedelta(days=1),
            id__gt=F("conversation__customer_last_read"),
        )
        .filter(id__gt=F("conversation__customer_reminded_upto"))
        .values("conversation")
        .annotate(upto=Max("id"))
    )
    count = 0
    for row in pending:
        conversation = Conversation.objects.select_related("customer").get(pk=row["conversation"])
        customer = conversation.customer
        prefix = "" if customer.language == "ar" else "/en"
        notify(
            "support_reply",
            user=customer,
            context={"url": f"{settings.STOREFRONT_URL}{prefix}/chat"},
            channels=("sms", "push"),
        )
        Conversation.objects.filter(pk=conversation.pk).update(customer_reminded_upto=row["upto"])
        count += 1
    return count

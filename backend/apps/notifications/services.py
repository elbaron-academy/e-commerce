import logging

from django.conf import settings
from django.core.mail import send_mail
from django.utils.module_loading import import_string

from .models import NotificationLog
from .templates import render

logger = logging.getLogger(__name__)


def notify(
    event: str,
    *,
    user=None,
    phone: str | None = None,
    email: str | None = None,
    lang: str | None = None,
    context: dict | None = None,
    channels=("sms",),
) -> list[int]:
    """Queues a message on each channel. Never raises: a failed SMS must not break checkout."""
    context = context or {}
    lang = lang or getattr(user, "language", None) or "ar"
    ids = []
    for channel in channels:
        try:
            content = render(event, channel, lang, context)
            if not content:
                continue
            recipient = {
                "sms": phone or getattr(user, "phone", ""),
                "email": email or getattr(user, "email", ""),
                "push": str(getattr(user, "pk", "")),
            }[channel]
            if not recipient:
                continue
            log = NotificationLog.objects.create(
                user=user,
                channel=channel,
                event=event,
                recipient=recipient,
                subject=content.get("subject", ""),
                body=content["body"],
            )
            ids.append(log.pk)
            from .tasks import deliver_notification

            deliver_notification.delay(log.pk)
        except Exception:
            logger.exception("Could not queue %s notification for %s", channel, event)
    return ids


def deliver(log: NotificationLog) -> None:
    try:
        if log.channel == NotificationLog.Channel.SMS:
            import_string(settings.SMS_BACKEND)().send(log.recipient, log.body)
            log.status = NotificationLog.Status.SENT
        elif log.channel == NotificationLog.Channel.EMAIL:
            send_mail(log.subject, log.body, settings.DEFAULT_FROM_EMAIL, [log.recipient])
            log.status = NotificationLog.Status.SENT
        else:
            sent = import_string(settings.PUSH_BACKEND)().send(log.user, log.subject, log.body)
            log.status = NotificationLog.Status.SENT if sent else NotificationLog.Status.SKIPPED
    except Exception as exc:
        logger.exception("Notification %s failed", log.pk)
        log.status = NotificationLog.Status.FAILED
        log.error = str(exc)[:2000]
    log.save(update_fields=["status", "error", "updated_at"])

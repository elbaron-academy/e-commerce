from celery import shared_task


@shared_task(autoretry_for=(ConnectionError,), retry_backoff=True, max_retries=3)
def deliver_notification(log_id: int) -> None:
    from .models import NotificationLog
    from .services import deliver

    log = NotificationLog.objects.filter(pk=log_id).first()
    if log and log.status == NotificationLog.Status.QUEUED:
        deliver(log)

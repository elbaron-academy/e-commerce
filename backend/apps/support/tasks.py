from celery import shared_task


@shared_task
def remind_unread_replies() -> int:
    from .services import remind_unread_replies as remind

    return remind()

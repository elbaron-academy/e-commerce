from celery import shared_task
from django.conf import settings
from django.db.models import F


@shared_task
def release_expired_reservations() -> int:
    from .services import release_expired_reservations as release

    return release()


@shared_task
def check_low_stock(variant_ids: list[int]) -> int:
    """Emails staff when items drop to their low-stock threshold (BE-207)."""
    from apps.catalog.models import Variant
    from apps.notifications.services import notify

    low = list(
        Variant.objects.filter(pk__in=variant_ids, is_active=True, stock__lte=F("low_stock_threshold")).select_related(
            "product"
        )
    )
    if low and settings.STAFF_ALERT_EMAILS:
        lines = "\n".join(f"- {v.sku} {v.product.name_en} ({v.label_en}): {v.stock:g} left" for v in low)
        for email in settings.STAFF_ALERT_EMAILS:
            notify(
                "low_stock", email=email, lang="en", context={"count": len(low), "lines": lines}, channels=("email",)
            )
    return len(low)

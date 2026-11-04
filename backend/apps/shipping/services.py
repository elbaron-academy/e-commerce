"""Delivery slots: daily windows minus full or too-soon ones, in Cairo time."""

from datetime import datetime, timedelta

from django.db.models import Count
from django.utils import timezone

from .models import DeliveryWindow, StoreSettings


def _slot_id(date, start) -> str:
    return f"{date.isoformat()}_{start:%H%M}"


def delivery_slots(at: datetime | None = None) -> list[dict]:
    from apps.orders.models import Order

    rules = StoreSettings.load()
    now = timezone.localtime(at or timezone.now())
    today = now.date()
    windows = list(DeliveryWindow.objects.filter(is_active=True))
    booked = {
        (row["slot_date"], row["slot_start"]): row["n"]
        for row in Order.objects.filter(
            slot_date__gte=today, slot_date__lt=today + timedelta(days=rules.slot_days), is_express=False
        )
        .exclude(status=Order.Status.CANCELLED)
        .values("slot_date", "slot_start")
        .annotate(n=Count("id"))
    }

    days = []
    for offset in range(rules.slot_days):
        date = today + timedelta(days=offset)
        slots = []
        if offset == 0 and rules.express_enabled and rules.express_start_hour <= now.hour < rules.express_end_hour:
            slots.append(
                {"id": "express", "date": date.isoformat(), "start": "", "end": "", "available": True, "express": True}
            )
        for window in windows:
            starts = timezone.make_aware(datetime.combine(date, window.start_time))
            too_soon = starts < now + timedelta(hours=rules.slot_lead_hours)
            full = booked.get((date, window.start_time), 0) >= window.capacity
            slots.append(
                {
                    "id": _slot_id(date, window.start_time),
                    "date": date.isoformat(),
                    "start": f"{window.start_time:%H:%M}",
                    "end": f"{window.end_time:%H:%M}",
                    "available": not (too_soon or full),
                    "express": False,
                }
            )
        if any(s["available"] for s in slots):
            days.append({"date": date.isoformat(), "slots": slots})
    return days


def resolve_slot(slot_id: str) -> dict | None:
    for day in delivery_slots():
        for slot in day["slots"]:
            if slot["id"] == slot_id:
                return slot
    return None

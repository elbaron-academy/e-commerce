"""Checkout (BE-502), stock reservation (BE-503) and the order status machine (BE-601)."""

import logging
from datetime import datetime, timedelta

from django.conf import settings
from django.db import transaction
from django.db.models import F
from django.utils import timezone
from rest_framework import status as http

from apps.catalog.models import Product, Variant
from apps.core.exceptions import ApiError
from apps.core.i18n import current_lang, t, tr
from apps.promotions.models import CouponRedemption
from apps.shipping.services import resolve_slot

from .models import Order, OrderItem, OrderStatusHistory
from .pricing import build_quote

logger = logging.getLogger(__name__)

# Customers get a message for these changes.
NOTIFY_STATUSES = {
    Order.Status.PLACED,
    Order.Status.CONFIRMED,
    Order.Status.OUT_FOR_DELIVERY,
    Order.Status.READY_FOR_PICKUP,
    Order.Status.DELIVERED,
    Order.Status.CANCELLED,
}


def _address_snapshot(address) -> dict:
    return {
        "id": address.pk,
        "label": address.label,
        "zone": address.zone.code,
        "zone_name_ar": address.zone.name_ar,
        "zone_name_en": address.zone.name_en,
        "area": address.area,
        "street": address.street,
        "building": address.building,
        "floor": address.floor,
        "apartment": address.apartment,
        "notes": address.notes,
        "lat": float(address.lat) if address.lat is not None else None,
        "lng": float(address.lng) if address.lng is not None else None,
    }


def place_order(
    *,
    user,
    items,
    method,
    payment_method,
    address_id=None,
    slot_id=None,
    coupon_code=None,
    notes="",
    serializer_context=None,
):
    """Creates the order in one transaction and reserves stock. Returns (order, payment_url)."""
    context = serializer_context or {}
    with transaction.atomic():
        address = None
        if method == Order.Method.DELIVERY:
            address = user.addresses.select_related("zone").filter(pk=address_id, zone__is_active=True).first()
            if not address:
                raise ApiError(
                    t("اختار عنوان التوصيل.", "Choose a delivery address."), field="address_id", code="address_required"
                )
        slot = resolve_slot(slot_id) if slot_id else None
        if not slot or not slot["available"] or (slot["express"] and method == Order.Method.PICKUP):
            raise ApiError(
                t("اختار ميعاد متاح.", "Choose an available time slot."), field="slot_id", code="slot_unavailable"
            )

        quote = build_quote(
            items,
            coupon_code=coupon_code,
            zone_code=address.zone.code if address else None,
            method=method,
            user=user,
            lock=True,
        )
        if not quote.can_checkout or quote.qty_reduced:
            message = quote.warnings[0]["message"] if quote.warnings else t("راجع السلة.", "Please review your cart.")
            raise ApiError(
                message, status_code=http.HTTP_409_CONFLICT, code="cart_changed", quote=quote.to_dict(context)
            )
        if coupon_code and not (quote.coupon and quote.coupon.valid):
            raise ApiError(
                quote.coupon.message if quote.coupon else "Invalid coupon", field="coupon", code="coupon_invalid"
            )
        if payment_method == Order.PaymentMethod.COD and not quote.cod_available:
            limit = f"{quote.rules.cod_limit:.0f}"
            raise ApiError(
                t(f"الدفع كاش متاح للطلبات لحد {limit} ج.م", f"Cash on delivery is available up to EGP {limit}."),
                code="cod_limit",
            )

        now = timezone.now()
        online = payment_method != Order.PaymentMethod.COD
        coupon = quote.coupon.coupon if quote.coupon and quote.coupon.valid else None
        order = Order.objects.create(
            user=user,
            status=Order.Status.PENDING_PAYMENT if online else Order.Status.PLACED,
            method=method,
            payment_method=payment_method,
            payment_status=Order.PaymentStatus.PENDING if online else Order.PaymentStatus.COD,
            subtotal=quote.subtotal,
            coupon_discount=quote.coupon.discount if coupon else 0,
            delivery_fee=quote.delivery_fee,
            total=quote.total,
            coupon=coupon,
            coupon_code=coupon.code if coupon else "",
            notes=(notes or "")[:300],
            language=current_lang(),
            zone_code=address.zone.code if address else "",
            address=_address_snapshot(address) if address else None,
            slot_date=datetime.fromisoformat(slot["date"]).date(),
            slot_start=None if slot["express"] else datetime.strptime(slot["start"], "%H:%M").time(),
            slot_end=None if slot["express"] else datetime.strptime(slot["end"], "%H:%M").time(),
            is_express=slot["express"],
            placed_at=None if online else now,
            reserved_until=now + timedelta(minutes=settings.STOCK_RESERVATION_MINUTES) if online else None,
        )
        order.number = f"RK-{order.pk:06d}"
        order.save(update_fields=["number"])

        request = context.get("request")
        order_items = []
        for line in quote.lines:
            product = line.variant.product
            images = list(product.images.all()[:1])
            image_url = images[0].image.url if images else ""
            if image_url.startswith("/") and request:
                image_url = request.build_absolute_uri(image_url)
            order_items.append(
                OrderItem(
                    order=order,
                    variant=line.variant,
                    product=product,
                    sku=line.variant.sku,
                    product_slug=product.slug,
                    name_ar=product.name_ar,
                    name_en=product.name_en,
                    variant_label_ar=line.variant.label_ar,
                    variant_label_en=line.variant.label_en,
                    emoji=product.emoji or product.category.root.emoji,
                    color=product.category.root.color,
                    image_url=image_url,
                    sold_by_weight=product.sold_by_weight,
                    qty=line.qty,
                    unit_price=line.unit_price,
                    original_unit_price=line.original_unit_price,
                    line_total=line.line_total,
                )
            )
            # Reserve stock. The condition protects against a concurrent checkout.
            updated = Variant.objects.filter(pk=line.variant.pk, stock__gte=line.qty).update(
                stock=F("stock") - line.qty
            )
            if not updated:
                raise ApiError(
                    t("المنتج ده خلص حالًا. راجع السلة.", "An item just sold out. Please review your cart."),
                    status_code=http.HTTP_409_CONFLICT,
                    code="out_of_stock",
                )
        OrderItem.objects.bulk_create(order_items)

        if coupon:
            CouponRedemption.objects.create(coupon=coupon, user=user, order=order, discount=order.coupon_discount)
        OrderStatusHistory.objects.create(order=order, status=order.status, actor=user)

        payment_url = None
        if online:
            from apps.payments.services import start_payment

            payment_url = start_payment(order)

        variant_ids = [line.variant.pk for line in quote.lines]
        transaction.on_commit(lambda: _after_order_created(order.pk, variant_ids))
    return order, payment_url


def _after_order_created(order_id: int, variant_ids: list[int]) -> None:
    from .tasks import check_low_stock

    order = Order.objects.select_related("user").get(pk=order_id)
    if order.status == Order.Status.PLACED:
        notify_status(order)
    check_low_stock.delay(variant_ids)


def _restock(order: Order) -> None:
    for item in order.items.exclude(variant=None):
        Variant.objects.filter(pk=item.variant_id).update(stock=F("stock") + item.qty)


def transition(order: Order, to: str, *, actor=None, note: str = "") -> Order:
    """Moves an order to a new status, with side effects and history."""
    with transaction.atomic():
        order = Order.objects.select_for_update().get(pk=order.pk)
        if to not in order.allowed_transitions():
            raise ApiError(
                f"Can't change order {order.number} from '{order.status}' to '{to}'.",
                status_code=http.HTTP_409_CONFLICT,
                code="invalid_transition",
                allowed=sorted(order.allowed_transitions()),
            )
        now = timezone.now()
        order.status = to
        if to == Order.Status.PLACED:
            order.placed_at = order.placed_at or now
            order.reserved_until = None
        elif to == Order.Status.CANCELLED:
            order.cancelled_at = now
            order.reserved_until = None
            _restock(order)
            CouponRedemption.objects.filter(order=order).delete()
        elif to == Order.Status.DELIVERED:
            order.delivered_at = now
            if order.payment_status == Order.PaymentStatus.COD:
                order.payment_status = Order.PaymentStatus.PAID
            for item in order.items.exclude(product=None):
                Product.objects.filter(pk=item.product_id).update(sold_count=F("sold_count") + 1)
        order.save()
        OrderStatusHistory.objects.create(order=order, status=to, actor=actor, note=note[:300])
        if to in NOTIFY_STATUSES:
            transaction.on_commit(lambda: notify_status(order))
    return order


def notify_status(order: Order) -> None:
    from apps.notifications.services import notify

    status_label = {
        "ar": {
            "placed": "اتأكد",
            "confirmed": "اتقبل",
            "out_for_delivery": "خرج مع المندوب",
            "ready_for_pickup": "جاهز للاستلام",
            "delivered": "اتسلم",
            "cancelled": "اتلغى",
        },
        "en": {
            "placed": "is confirmed",
            "confirmed": "was accepted",
            "out_for_delivery": "is out for delivery",
            "ready_for_pickup": "is ready for pickup",
            "delivered": "was delivered",
            "cancelled": "was cancelled",
        },
    }[order.language if order.language in ("ar", "en") else "ar"].get(order.status, order.status)
    notify(
        "order_placed" if order.status == Order.Status.PLACED else "order_status",
        user=order.user,
        lang=order.language,
        context={
            "number": order.number,
            "total": f"{order.total:.2f}",
            "status": status_label,
            "url": f"{settings.STOREFRONT_URL}{'' if order.language == 'ar' else '/en'}/orders/{order.pk}",
        },
        channels=("sms", "push"),
    )


def release_expired_reservations(now=None) -> int:
    """Cancels unpaid orders whose 15-minute hold has passed and returns their stock."""
    from apps.payments.models import Payment

    now = now or timezone.now()
    expired = Order.objects.filter(status=Order.Status.PENDING_PAYMENT, reserved_until__lt=now)
    count = 0
    for order in expired:
        Payment.objects.filter(order=order, status=Payment.Status.PENDING).update(status=Payment.Status.EXPIRED)
        Order.objects.filter(pk=order.pk).update(payment_status=Order.PaymentStatus.FAILED)
        transition(order, Order.Status.CANCELLED, note="Payment not completed in time")
        count += 1
    if count:
        logger.info("Released %s expired reservations", count)
    return count


def order_timeline(order: Order) -> list[dict]:
    reached: dict[str, datetime] = {}
    for entry in order.history.all():
        reached.setdefault(entry.status, entry.created_at)
    return [{"status": step, "at": reached.get(step), "done": step in reached} for step in order.steps]


def item_display(item: OrderItem) -> dict:
    return {
        "sku": item.sku,
        "slug": item.product_slug,
        "name": tr(item, "name"),
        "variant_label": tr(item, "variant_label"),
        "emoji": item.emoji,
        "color": item.color,
        "image": item.image_url or None,
        "qty": item.qty,
        "unit_price": item.unit_price,
        "line_total": item.line_total,
        "sold_by_weight": item.sold_by_weight,
    }

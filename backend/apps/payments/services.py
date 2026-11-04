import logging
import uuid

from django.db import transaction

from apps.orders.models import Order
from apps.orders.services import transition

from .gateways import get_gateway
from .models import Payment

logger = logging.getLogger(__name__)


def start_payment(order: Order) -> str:
    gateway = get_gateway()
    payment = Payment.objects.create(
        order=order, provider=gateway.name, method=order.payment_method, amount=order.total, reference=uuid.uuid4().hex
    )
    payment.redirect_url = gateway.create_payment(payment)
    payment.save(update_fields=["redirect_url"])
    return payment.redirect_url


def apply_payment_result(
    payment: Payment, *, success: bool, transaction_id: str = "", payload: dict | None = None
) -> Payment:
    """Idempotent: a payment that already has a final status is left alone."""
    with transaction.atomic():
        payment = Payment.objects.select_for_update().select_related("order").get(pk=payment.pk)
        if payment.status != Payment.Status.PENDING and not (success and payment.status == Payment.Status.EXPIRED):
            return payment
        order = payment.order
        payment.provider_transaction_id = transaction_id or payment.provider_transaction_id
        payment.payload = payload or payment.payload
        if success:
            payment.status = Payment.Status.SUCCEEDED
            if order.status == Order.Status.PENDING_PAYMENT:
                Order.objects.filter(pk=order.pk).update(payment_status=Order.PaymentStatus.PAID)
                transition(order, Order.Status.PLACED, note=f"Paid via {payment.provider}")
            else:
                # Paid after the hold expired: keep the money flagged for a refund.
                payment.needs_refund = True
                logger.warning(
                    "Payment %s succeeded for order %s in status %s; flagged for refund",
                    payment.reference,
                    order.number,
                    order.status,
                )
        else:
            payment.status = Payment.Status.FAILED
            if order.status == Order.Status.PENDING_PAYMENT:
                Order.objects.filter(pk=order.pk).update(payment_status=Order.PaymentStatus.FAILED)
                transition(order, Order.Status.CANCELLED, note="Payment failed")
        payment.save()
    return payment

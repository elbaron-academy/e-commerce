import hashlib
import hmac
import json
from datetime import timedelta
from decimal import Decimal

import pytest
from django.core import mail
from django.utils import timezone

from apps.catalog.models import Variant
from apps.notifications.models import NotificationLog
from apps.orders.models import Order
from apps.orders.services import release_expired_reservations, transition
from apps.payments.models import Payment, WebhookEvent
from apps.promotions.models import CouponRedemption

pytestmark = pytest.mark.django_db


def stock(sku):
    return Variant.objects.get(sku=sku).stock


def test_cod_order_reserves_stock_and_notifies(place, customer, django_capture_on_commit_callbacks):
    before = stock("RK-0036-2")
    with django_capture_on_commit_callbacks(execute=True):
        res = place(coupon="ROCKET10")
    assert res.status_code == 201, res.content
    data = res.json()
    order = data["order"]
    assert data["payment_url"] is None
    assert order["number"].startswith("RK-") and order["status"] == "placed" and order["payment_status"] == "cod"
    assert (
        order["subtotal"] == 377
        and order["coupon_discount"] == 37.7
        and order["delivery_fee"] == 30
        and order["total"] == 369.3
    )
    assert order["address"]["zone_name"] == "الجيزة"
    assert order["timeline"][0] == {"status": "placed", "at": order["timeline"][0]["at"], "done": True}
    assert stock("RK-0036-2") == before - 1
    assert CouponRedemption.objects.filter(order_id=order["id"], user=customer).exists()
    assert NotificationLog.objects.filter(event="order_placed", channel="sms", recipient=customer.phone).exists()


def test_low_stock_alert_email(place, django_capture_on_commit_callbacks):
    Variant.objects.filter(sku="RK-0036-2").update(stock=Decimal("6"))
    with django_capture_on_commit_callbacks(execute=True):
        assert place().status_code == 201
    assert len(mail.outbox) == 1
    assert "RK-0036-2" in mail.outbox[0].body and mail.outbox[0].to == ["ops@rocket.test"]


def test_order_list_and_detail_are_private(place, customer_api, api):
    order_id = place().json()["order"]["id"]
    assert customer_api.get("/api/v1/orders/").json()["count"] == 1
    assert customer_api.get(f"/api/v1/orders/{order_id}/").status_code == 200
    from apps.accounts.models import User
    from tests.conftest import client_for

    other = client_for(User.objects.create_user(phone="01277778888"))
    assert other.get(f"/api/v1/orders/{order_id}/").status_code == 404


def test_checkout_rejects_changed_cart(place):
    Variant.objects.filter(sku="RK-0036-2").update(stock=0)
    res = place()
    assert res.status_code == 409
    body = res.json()
    assert body["code"] == "cart_changed" and body["quote"]["can_checkout"] is False


def test_checkout_rejects_reduced_quantity(place):
    res = place(items=[{"sku": "RK-0034-1", "qty": 4}])  # only 3 kg left
    assert res.status_code == 409


def test_checkout_validations(place, customer_api, slot_id):
    assert place(address_id=None).json()["code"] == "address_required"
    assert place(slot_id="2000-01-01_0900").json()["code"] == "slot_unavailable"
    assert place(coupon="NOPE").json()["code"] == "coupon_invalid"
    assert place(method="pickup", address_id=None, slot_id=slot_id(express=True)).json()["code"] == "slot_unavailable"
    big = [{"sku": "RK-0034-1", "qty": 3}, {"sku": "RK-0039-1", "qty": 9}]
    assert place(items=big).json()["code"] == "cod_limit"


def test_pickup_order(place, slot_id):
    res = place(method="pickup", address_id=None)
    assert res.status_code == 201
    order = res.json()["order"]
    assert order["delivery_fee"] == 0 and order["address"] is None
    assert [s["status"] for s in order["timeline"]][3] == "ready_for_pickup"


def test_card_order_waits_for_payment_then_succeeds(place, customer_api):
    res = place(payment_method="card")
    assert res.status_code == 201
    data = res.json()
    order = Order.objects.get(pk=data["order"]["id"])
    assert data["payment_url"] == f"/payment/mock?order={order.pk}"
    assert order.status == "pending_payment" and order.reserved_until > timezone.now()
    confirm = customer_api.post("/api/v1/payments/mock/confirm/", {"order_id": order.pk, "result": "success"})
    assert confirm.status_code == 200
    assert confirm.json()["status"] == "placed" and confirm.json()["payment_status"] == "paid"


def test_failed_payment_cancels_and_restocks(place, customer_api):
    before = stock("RK-0036-2")
    order_id = place(payment_method="wallet", coupon="ROCKET10").json()["order"]["id"]
    assert stock("RK-0036-2") == before - 1
    res = customer_api.post("/api/v1/payments/mock/confirm/", {"order_id": order_id, "result": "failed"})
    assert res.json()["status"] == "cancelled"
    assert stock("RK-0036-2") == before
    assert not CouponRedemption.objects.filter(order_id=order_id).exists()


def test_expired_reservation_is_released(place):
    before = stock("RK-0014-2")
    order_id = place(payment_method="card").json()["order"]["id"]
    Order.objects.filter(pk=order_id).update(reserved_until=timezone.now() - timedelta(seconds=1))
    assert release_expired_reservations() == 1
    order = Order.objects.get(pk=order_id)
    assert order.status == "cancelled" and order.payment_status == "failed"
    assert stock("RK-0014-2") == before
    assert Payment.objects.get(order=order).status == "expired"


def _signed(api, payload):
    body = json.dumps(payload).encode()
    signature = hmac.new(b"test-webhook-secret", body, hashlib.sha256).hexdigest()
    return api.generic(
        "POST",
        "/api/v1/payments/webhook/dummy/",
        body,
        content_type="application/json",
        HTTP_X_ROCKET_SIGNATURE=signature,
    )


def test_webhook_signature_and_idempotency(api, place):
    order_id = place(payment_method="card").json()["order"]["id"]
    payment = Payment.objects.get(order_id=order_id)
    bad = api.generic(
        "POST",
        "/api/v1/payments/webhook/dummy/",
        b"{}",
        content_type="application/json",
        HTTP_X_ROCKET_SIGNATURE="nope",
    )
    assert bad.status_code == 400

    payload = {"event_id": "evt_1", "reference": payment.reference, "status": "paid", "transaction_id": "T-1"}
    assert _signed(api, payload).json() == {"received": True}
    assert _signed(api, payload).json() == {"received": True, "duplicate": True}
    assert WebhookEvent.objects.count() == 1
    payment.refresh_from_db()
    assert payment.status == "succeeded" and payment.provider_transaction_id == "T-1"
    assert Order.objects.get(pk=order_id).status == "placed"
    assert _signed(api, {"event_id": "evt_2", "reference": "missing", "status": "paid"}).status_code == 404
    assert api.post("/api/v1/payments/webhook/unknown/", {}).status_code == 404


def test_payment_after_expiry_is_flagged_for_refund(api, place):
    order_id = place(payment_method="card").json()["order"]["id"]
    Order.objects.filter(pk=order_id).update(reserved_until=timezone.now() - timedelta(seconds=1))
    release_expired_reservations()
    payment = Payment.objects.get(order_id=order_id)
    _signed(api, {"event_id": "late", "reference": payment.reference, "status": "paid"})
    payment.refresh_from_db()
    assert payment.status == "succeeded" and payment.needs_refund is True
    assert Order.objects.get(pk=order_id).status == "cancelled"


def test_status_machine(place, staff):
    order = Order.objects.get(pk=place().json()["order"]["id"])
    with pytest.raises(Exception, match="Can't change"):
        transition(order, "delivered")
    with pytest.raises(Exception, match="Can't change"):
        transition(order, "ready_for_pickup")  # delivery order
    for status in ("confirmed", "preparing", "out_for_delivery", "delivered"):
        order = transition(order, status, actor=staff)
    assert order.payment_status == "paid" and order.delivered_at
    assert order.history.count() == 5
    assert all(step["done"] for step in __import__("apps.orders.services", fromlist=["x"]).order_timeline(order))
    from apps.catalog.models import Product

    assert Product.objects.get(slug="banana").sold_count > 0


def test_cancel_restocks(place):
    before = stock("RK-0001-1")
    order = Order.objects.get(pk=place().json()["order"]["id"])
    assert stock("RK-0001-1") == before - 2
    transition(order, "cancelled", note="Customer called")
    assert stock("RK-0001-1") == before

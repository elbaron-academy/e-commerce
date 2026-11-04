from datetime import timedelta
from decimal import Decimal

import pytest
from django.utils import timezone

from apps.catalog.models import Variant
from apps.orders.pricing import build_quote, normalize_qty
from apps.promotions.models import Coupon, CouponRedemption
from apps.shipping.models import StoreSettings

pytestmark = pytest.mark.django_db
QUOTE = "/api/v1/cart/quote/"


def quote(api, items, **extra):
    res = api.post(QUOTE, {"items": items, **extra}, format="json")
    assert res.status_code == 200, res.content
    return res.json()


def test_normalize_qty():
    assert normalize_qty(Decimal("1.1"), Decimal("0.25"), Decimal("0.5")) == Decimal("1.000")
    assert normalize_qty(Decimal("0.2"), Decimal("0.25"), Decimal("0.5")) == Decimal("0.5")
    assert normalize_qty(Decimal("2.6"), Decimal("1"), Decimal("1")) == Decimal("3")


def test_quote_prices_with_sale_and_savings(api):
    q = quote(api, [{"sku": "RK-0007-1", "qty": 2}, {"sku": "RK-0014-1", "qty": 3}])  # tomato on sale 15 (18), milk 38
    assert q["subtotal"] == 2 * 15 + 3 * 38
    assert q["savings"] == 6
    assert q["delivery_fee"] == 25  # default zone: Cairo
    assert q["total"] == q["subtotal"] + 25
    assert q["can_checkout"] is True
    line = q["lines"][0]
    assert line["product"]["slug"] == "tomato" and line["unit_price"] == 15 and line["original_unit_price"] == 18


def test_weight_items_are_rounded_to_step(api):
    q = quote(api, [{"sku": "RK-0001-1", "qty": 1.1}])
    assert q["lines"][0]["qty"] == 1.0
    assert q["lines"][0]["line_total"] == 32


def test_duplicate_skus_are_merged(api):
    q = quote(api, [{"sku": "RK-0014-1", "qty": 1}, {"sku": "RK-0014-1", "qty": 2}])
    assert len(q["lines"]) == 1 and q["lines"][0]["qty"] == 3


def test_quantity_capped_by_stock_and_per_order_limit(api):
    q = quote(api, [{"sku": "RK-0014-2", "qty": 50}])
    assert q["lines"][0]["qty"] == 20
    assert any(w["code"] == "qty_reduced" for w in q["warnings"])
    shrimp = quote(api, [{"sku": "RK-0034-1", "qty": 4}])  # 3 kg in stock
    assert shrimp["lines"][0]["qty"] == 3


def test_unknown_and_out_of_stock_items_block_checkout(api):
    q = quote(api, [{"sku": "RK-0005-1", "qty": 1}, {"sku": "NOPE", "qty": 1}, {"sku": "RK-0036-2", "qty": 1}])
    assert q["can_checkout"] is False
    assert q["warnings"][0]["code"] == "unavailable"
    avocado = next(line for line in q["lines"] if line["sku"] == "RK-0005-1")
    assert avocado["available"] is False and avocado["line_total"] == 0


def test_price_change_is_flagged(api):
    q = quote(api, [{"sku": "RK-0001-1", "qty": 1, "expected_price": 30}])
    assert q["lines"][0]["price_changed"] is True
    assert any(w["code"] == "price_changed" for w in q["warnings"])


def test_minimum_order(api):
    q = quote(api, [{"sku": "RK-0023-1", "qty": 1}])
    assert q["can_checkout"] is False
    assert q["warnings"][-1]["code"] == "min_order"


def test_free_delivery_threshold_and_zones(api):
    assert quote(api, [{"sku": "RK-0014-2", "qty": 7}])["delivery_fee"] == 0  # 504
    assert quote(api, [{"sku": "RK-0036-2", "qty": 1}], zone="alexandria")["delivery_fee"] == 60
    assert quote(api, [{"sku": "RK-0036-2", "qty": 1}], method="pickup")["delivery_fee"] == 0


def test_cod_limit(api):
    q = quote(api, [{"sku": "RK-0034-1", "qty": 3}, {"sku": "RK-0039-1", "qty": 9}])  # 1650 + 1890
    assert q["cod_available"] is False


def test_percent_coupon_with_cap(api):
    q = quote(api, [{"sku": "RK-0036-2", "qty": 1}, {"sku": "RK-0014-2", "qty": 1}], coupon="rocket10")
    assert q["coupon"]["valid"] is True
    assert q["coupon_discount"] == round((169 + 72) * 0.1, 2)
    big = quote(api, [{"sku": "RK-0039-1", "qty": 10}], coupon="ROCKET10")
    assert big["coupon_discount"] == 100


def test_coupon_minimum_and_invalid_codes(api):
    q = quote(api, [{"sku": "RK-0036-2", "qty": 1}], coupon="SAVE50")
    assert q["coupon"]["valid"] is False and "400" in q["coupon"]["message"]
    assert quote(api, [{"sku": "RK-0036-2", "qty": 1}], coupon="NOPE")["coupon"]["valid"] is False


def test_free_delivery_coupon(api):
    q = quote(api, [{"sku": "RK-0036-2", "qty": 1}], coupon="FREESHIP")
    assert q["coupon"]["valid"] is True and q["delivery_fee"] == 0


def test_coupon_dates_and_limits(api, customer):
    coupon = Coupon.objects.create(
        code="LIMITED", type=Coupon.Type.FIXED, value=20, usage_limit=1, per_customer_limit=1
    )
    assert build_quote([{"sku": "RK-0036-2", "qty": 1}], coupon_code="limited").coupon.valid
    coupon.ends_at = timezone.now() - timedelta(minutes=1)
    coupon.save()
    assert not build_quote([{"sku": "RK-0036-2", "qty": 1}], coupon_code="LIMITED").coupon.valid
    coupon.ends_at = None
    coupon.save()
    from apps.orders.models import Order

    order = Order.objects.create(
        user=customer, status="placed", method="pickup", payment_method="cod", payment_status="cod", subtotal=1, total=1
    )
    CouponRedemption.objects.create(coupon=coupon, user=customer, order=order, discount=20)
    result = build_quote([{"sku": "RK-0036-2", "qty": 1}], coupon_code="LIMITED", user=customer).coupon
    assert not result.valid


def test_store_settings_drive_rules(api):
    rules = StoreSettings.load()
    rules.min_order = Decimal("10")
    rules.save()
    assert quote(api, [{"sku": "RK-0023-1", "qty": 1}])["can_checkout"] is True


def test_quote_validation(api):
    assert api.post(QUOTE, {"items": [{"sku": "RK-0001-1", "qty": 0}]}, format="json").status_code == 400
    assert (
        api.post(QUOTE, {"items": [{"sku": "RK-0001-1", "qty": 1}], "method": "drone"}, format="json").status_code
        == 400
    )


def test_inactive_variant_is_unavailable(api):
    Variant.objects.filter(sku="RK-0036-2").update(is_active=False)
    q = quote(api, [{"sku": "RK-0036-2", "qty": 1}])
    assert q["lines"] == [] and q["can_checkout"] is False

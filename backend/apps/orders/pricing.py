"""
Server-side cart pricing. The cart is kept on the customer's device; every change
is priced here: stock, live sale prices, coupon, delivery fee and order rules.
The same function runs inside checkout (with row locks) so the order matches the quote.
"""

from dataclasses import dataclass, field
from decimal import ROUND_HALF_UP, Decimal

from django.utils import timezone

from apps.catalog.models import Variant
from apps.core.i18n import t, tr
from apps.promotions.services import CouponResult, evaluate_coupon
from apps.shipping.models import StoreSettings, Zone

CENT = Decimal("0.01")
QTY = Decimal("0.001")


def money(value: Decimal) -> Decimal:
    return value.quantize(CENT, ROUND_HALF_UP)


def normalize_qty(qty: Decimal, step: Decimal, minimum: Decimal) -> Decimal:
    """Rounds to the product's step (e.g. 0.25 kg) and enforces the minimum."""
    steps = (qty / step).quantize(Decimal("1"), ROUND_HALF_UP)
    return max(minimum, (steps * step).quantize(QTY))


@dataclass
class PricedLine:
    variant: Variant
    requested_qty: Decimal
    qty: Decimal
    available: bool
    max_qty: Decimal
    unit_price: Decimal
    original_unit_price: Decimal
    line_total: Decimal
    price_changed: bool

    @property
    def product(self):
        return self.variant.product


@dataclass
class Quote:
    lines: list[PricedLine]
    missing_skus: list[str]
    subtotal: Decimal
    savings: Decimal
    coupon: CouponResult | None
    delivery_fee: Decimal
    total: Decimal
    rules: StoreSettings
    zone: Zone | None
    method: str
    warnings: list[dict] = field(default_factory=list)

    @property
    def unavailable(self) -> bool:
        return bool(self.missing_skus) or any(not line.available for line in self.lines)

    @property
    def qty_reduced(self) -> bool:
        return any(line.available and line.qty < line.requested_qty for line in self.lines)

    @property
    def cod_available(self) -> bool:
        return self.total <= self.rules.cod_limit

    @property
    def can_checkout(self) -> bool:
        return bool(self.lines) and not self.unavailable and self.subtotal >= self.rules.min_order

    def to_dict(self, context: dict) -> dict:
        from apps.catalog.selectors import storefront_products
        from apps.catalog.serializers import ProductSummarySerializer

        product_ids = {line.variant.product_id for line in self.lines}
        products = {p.pk: p for p in storefront_products().filter(pk__in=product_ids)}
        lines = []
        for line in self.lines:
            product = products.get(line.variant.product_id, line.variant.product)
            lines.append(
                {
                    "sku": line.variant.sku,
                    "qty": line.qty,
                    "available": line.available,
                    "max_qty": line.max_qty,
                    "unit_price": line.unit_price,
                    "original_unit_price": line.original_unit_price,
                    "line_total": line.line_total,
                    "price_changed": line.price_changed,
                    "variant_label": tr(line.variant, "label"),
                    "product": ProductSummarySerializer(product, context=context).data,
                }
            )
        return {
            "lines": lines,
            "items_count": len(lines),
            "subtotal": self.subtotal,
            "savings": self.savings,
            "coupon_discount": self.coupon.discount if self.coupon and self.coupon.valid else Decimal("0"),
            "delivery_fee": self.delivery_fee,
            "total": self.total,
            "min_order": self.rules.min_order,
            "free_delivery_threshold": self.rules.free_delivery_threshold,
            "remaining_for_free_delivery": max(Decimal("0"), self.rules.free_delivery_threshold - self.subtotal),
            "cod_available": self.cod_available,
            "cod_limit": self.rules.cod_limit,
            "coupon": self.coupon.as_dict() if self.coupon else None,
            "warnings": self.warnings,
            "can_checkout": self.can_checkout,
        }


def build_quote(
    items: list[dict],
    *,
    coupon_code: str | None = None,
    zone_code: str | None = None,
    method: str = "delivery",
    user=None,
    lock: bool = False,
) -> Quote:
    now = timezone.now()
    rules = StoreSettings.load()

    requested: dict[str, dict] = {}
    for item in items:
        entry = requested.setdefault(item["sku"], {"qty": Decimal("0"), "expected_price": item.get("expected_price")})
        entry["qty"] += Decimal(str(item["qty"]))

    variants = Variant.objects.filter(sku__in=requested, is_active=True, product__is_active=True).select_related(
        "product__category__parent__parent", "product__brand"
    )
    if lock:
        variants = variants.select_for_update()
    by_sku = {v.sku: v for v in variants}

    lines, missing = [], []
    for sku, entry in requested.items():
        variant = by_sku.get(sku)
        if not variant:
            missing.append(sku)
            continue
        product = variant.product
        qty = normalize_qty(entry["qty"], product.qty_step, product.min_qty)
        max_qty = variant.max_qty(product)
        available = variant.in_stock and max_qty >= product.min_qty
        final_qty = min(qty, max_qty) if available else qty
        if available and final_qty != qty:
            # Keep within stock but on the product's step.
            final_qty = (final_qty / product.qty_step).to_integral_value(rounding="ROUND_FLOOR") * product.qty_step
        unit = variant.unit_price(now)
        expected = entry["expected_price"]
        lines.append(
            PricedLine(
                variant=variant,
                requested_qty=qty,
                qty=final_qty,
                available=available,
                max_qty=max_qty,
                unit_price=unit,
                original_unit_price=variant.price,
                line_total=money(unit * final_qty) if available else Decimal("0"),
                price_changed=expected is not None and abs(Decimal(str(expected)) - unit) > Decimal("0.001"),
            )
        )

    priced = [line for line in lines if line.available]
    subtotal = money(sum((line.line_total for line in priced), Decimal("0")))
    savings = money(sum(((line.original_unit_price - line.unit_price) * line.qty for line in priced), Decimal("0")))

    coupon = None
    if coupon_code:
        locked = None
        if lock:
            from apps.promotions.models import Coupon

            locked = Coupon.objects.select_for_update().filter(code=coupon_code.strip().upper()).first()
        coupon = evaluate_coupon(coupon_code, subtotal, user, coupon=locked)

    zone = rules.resolve_zone(zone_code) if method == "delivery" else None
    free = subtotal >= rules.free_delivery_threshold or (coupon and coupon.valid and coupon.free_delivery)
    delivery_fee = Decimal("0") if method == "pickup" or free or subtotal == 0 or not zone else zone.fee
    discount = coupon.discount if coupon and coupon.valid else Decimal("0")
    total = money(max(Decimal("0"), subtotal - discount) + delivery_fee)

    quote = Quote(lines, missing, subtotal, savings, coupon, delivery_fee, total, rules, zone, method)
    if quote.unavailable:
        quote.warnings.append(
            {
                "code": "unavailable",
                "message": t(
                    "فيه منتجات مش متوفرة دلوقتي، شيلها عشان تكمل الطلب.",
                    "Some items are out of stock. Remove them to continue.",
                ),
            }
        )
    if quote.qty_reduced:
        quote.warnings.append(
            {
                "code": "qty_reduced",
                "message": t("قللنا كمية بعض المنتجات حسب المتاح.", "We reduced some quantities to what is available."),
            }
        )
    if any(line.price_changed for line in lines):
        quote.warnings.append(
            {
                "code": "price_changed",
                "message": t(
                    "أسعار بعض المنتجات اتغيرت من وقت ما ضفتها.", "Some prices changed since you added the items."
                ),
            }
        )
    if 0 < subtotal < rules.min_order:
        minimum = f"{rules.min_order:.0f}"
        quote.warnings.append(
            {"code": "min_order", "message": t(f"الحد الأدنى للطلب {minimum} ج.م", f"Minimum order is EGP {minimum}")}
        )
    return quote

from dataclasses import dataclass
from decimal import ROUND_HALF_UP, Decimal

from django.utils import timezone

from apps.core.i18n import t

from .models import Coupon

CENT = Decimal("0.01")


@dataclass
class CouponResult:
    code: str
    valid: bool
    message: str
    discount: Decimal = Decimal("0")
    free_delivery: bool = False
    coupon: Coupon | None = None

    def as_dict(self) -> dict:
        return {"code": self.code, "valid": self.valid, "message": self.message}


def evaluate_coupon(code: str, subtotal: Decimal, user=None, *, coupon: Coupon | None = None) -> CouponResult:
    code = (code or "").strip().upper()
    coupon = coupon or Coupon.objects.filter(code=code).first()
    invalid = CouponResult(code, False, t("الكود ده مش صحيح أو انتهى", "This code is invalid or has expired"))
    now = timezone.now()
    if not coupon or not coupon.is_active:
        return invalid
    if (coupon.starts_at and coupon.starts_at > now) or (coupon.ends_at and coupon.ends_at < now):
        return invalid
    if coupon.usage_limit is not None and coupon.redemptions.count() >= coupon.usage_limit:
        return CouponResult(code, False, t("الكود ده خلص", "This code has been fully used"))
    limited = user and user.is_authenticated and coupon.per_customer_limit is not None
    if limited and coupon.redemptions.filter(user=user).count() >= coupon.per_customer_limit:
        return CouponResult(code, False, t("استخدمت الكود ده قبل كده", "You've already used this code"))
    if subtotal < coupon.min_subtotal:
        minimum = f"{coupon.min_subtotal:.0f}"
        return CouponResult(
            code, False, t(f"الكود ده للطلبات فوق {minimum} ج.م", f"This code needs a minimum order of EGP {minimum}")
        )

    if coupon.type == Coupon.Type.FREE_DELIVERY:
        return CouponResult(
            code,
            True,
            t("تم تطبيق الكود: توصيل مجاني", "Code applied: free delivery"),
            free_delivery=True,
            coupon=coupon,
        )
    if coupon.type == Coupon.Type.PERCENT:
        discount = (subtotal * coupon.value / 100).quantize(CENT, ROUND_HALF_UP)
        if coupon.max_discount is not None:
            discount = min(discount, coupon.max_discount)
    else:
        discount = min(coupon.value, subtotal)
    return CouponResult(code, True, t("تم تطبيق الكود", "Code applied"), discount=discount, coupon=coupon)

"""OTP login (BE-102): rate limited per phone, hashed codes, limited attempts."""

import hashlib
import hmac
import secrets
from datetime import timedelta

from django.conf import settings
from django.utils import timezone
from rest_framework import status

from apps.core.exceptions import ApiError
from apps.core.i18n import t

from .models import OTPCode


def _hash(phone: str, code: str) -> str:
    return hmac.new(settings.SECRET_KEY.encode(), f"{phone}:{code}".encode(), hashlib.sha256).hexdigest()


def send_otp(phone: str, *, purpose: str = "login", ip: str | None = None) -> OTPCode:
    now = timezone.now()
    recent = OTPCode.objects.filter(phone=phone, created_at__gte=now - timedelta(hours=1))
    if recent.count() >= settings.OTP_MAX_SENDS_PER_HOUR:
        raise ApiError(
            t("محاولات كتير. جرب تاني بعد ساعة.", "Too many attempts. Try again in an hour."),
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            code="otp_rate_limited",
        )
    last = recent.first()
    if last and (now - last.created_at).total_seconds() < settings.OTP_RESEND_SECONDS:
        wait = settings.OTP_RESEND_SECONDS - int((now - last.created_at).total_seconds())
        raise ApiError(
            t(f"استنى {wait} ثانية قبل ما تطلب كود جديد.", f"Wait {wait}s before requesting a new code."),
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            code="otp_resend_wait",
            retry_after=wait,
        )

    code = settings.OTP_FIXED_CODE or f"{secrets.randbelow(10_000):04d}"
    otp = OTPCode.objects.create(
        phone=phone,
        code_hash=_hash(phone, code),
        purpose=purpose,
        expires_at=now + timedelta(seconds=settings.OTP_TTL_SECONDS),
        ip=ip,
    )

    from apps.notifications.services import notify

    notify("otp", phone=phone, context={"code": code, "domain": settings.OTP_WEBOTP_DOMAIN}, channels=("sms",))
    return otp


def verify_otp(phone: str, code: str, *, purpose: str = "login") -> None:
    invalid = ApiError(t("الكود غلط أو انتهى.", "The code is incorrect or expired."), code="otp_invalid", field="code")
    otp = OTPCode.objects.filter(
        phone=phone, purpose=purpose, consumed_at__isnull=True, expires_at__gt=timezone.now()
    ).first()
    if not otp or otp.attempts >= settings.OTP_MAX_ATTEMPTS:
        raise invalid
    otp.attempts += 1
    if not hmac.compare_digest(otp.code_hash, _hash(phone, code or "")):
        otp.save(update_fields=["attempts"])
        raise invalid
    otp.consumed_at = timezone.now()
    otp.save(update_fields=["attempts", "consumed_at"])

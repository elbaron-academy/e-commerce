from datetime import timedelta

import pytest
from django.utils import timezone

from apps.accounts.models import OTPCode, User
from apps.notifications.models import NotificationLog
from tests.conftest import client_for

pytestmark = pytest.mark.django_db
SEND = "/api/v1/auth/otp/send/"
VERIFY = "/api/v1/auth/otp/verify/"


def test_send_otp_validates_phone(api):
    res = api.post(SEND, {"phone": "0123"})
    assert res.status_code == 400
    assert res.json()["field"] == "phone"


def test_send_and_verify_creates_customer(api):
    res = api.post(SEND, {"phone": "+20 111 222 3333"})
    assert res.status_code == 200
    assert res.json() == {"sent": True, "expires_in": 120, "resend_in": 60}
    sms = NotificationLog.objects.get(event="otp")
    assert sms.recipient == "01112223333"
    assert "1234" in sms.body and sms.body.endswith("#1234")

    res = api.post(VERIFY, {"phone": "01112223333", "code": "١٢٣٤"})
    assert res.status_code == 200
    data = res.json()
    assert data["is_new"] is True and data["user"]["phone"] == "01112223333"
    me = api.get("/api/v1/me/", HTTP_AUTHORIZATION=f"Bearer {data['access']}")
    assert me.status_code == 200


def test_code_is_single_use(api):
    api.post(SEND, {"phone": "01112223333"})
    assert api.post(VERIFY, {"phone": "01112223333", "code": "1234"}).status_code == 200
    assert api.post(VERIFY, {"phone": "01112223333", "code": "1234"}).status_code == 400


def test_wrong_code_and_attempt_limit(api):
    api.post(SEND, {"phone": "01112223333"})
    for _ in range(5):
        res = api.post(VERIFY, {"phone": "01112223333", "code": "0000"})
        assert res.status_code == 400 and res.json()["code"] == "otp_invalid"
    # Even the right code fails once attempts are used up.
    assert api.post(VERIFY, {"phone": "01112223333", "code": "1234"}).status_code == 400


def test_expired_code(api):
    api.post(SEND, {"phone": "01112223333"})
    OTPCode.objects.update(expires_at=timezone.now() - timedelta(seconds=1))
    assert api.post(VERIFY, {"phone": "01112223333", "code": "1234"}).status_code == 400


def test_resend_wait_and_hourly_limit(api):
    assert api.post(SEND, {"phone": "01112223333"}).status_code == 200
    res = api.post(SEND, {"phone": "01112223333"})
    assert res.status_code == 429 and res.json()["code"] == "otp_resend_wait"
    for _ in range(4):
        OTPCode.objects.update(created_at=timezone.now() - timedelta(minutes=2))
        api.post(SEND, {"phone": "01112223333"})
    OTPCode.objects.update(created_at=timezone.now() - timedelta(minutes=2))
    res = api.post(SEND, {"phone": "01112223333"})
    assert res.status_code == 429 and res.json()["code"] == "otp_rate_limited"


def test_returning_customer_is_not_new(api, customer):
    api.post(SEND, {"phone": customer.phone})
    assert api.post(VERIFY, {"phone": customer.phone, "code": "1234"}).json()["is_new"] is False


def test_disabled_customer_cannot_sign_in(api, customer):
    customer.is_active = False
    customer.save()
    api.post(SEND, {"phone": customer.phone})
    assert api.post(VERIFY, {"phone": customer.phone, "code": "1234"}).status_code == 403


def test_profile_update(customer_api, customer):
    res = customer_api.patch("/api/v1/me/", {"name": "Mona Ali", "email": "mona@example.com", "language": "en"})
    assert res.status_code == 200
    customer.refresh_from_db()
    assert (customer.name, customer.email, customer.language) == ("Mona Ali", "mona@example.com", "en")
    assert customer_api.patch("/api/v1/me/", {"language": "fr"}).status_code == 400


def test_change_phone_needs_otp(api, customer_api, customer):
    api.post(SEND, {"phone": "01233334444"})
    res = customer_api.post("/api/v1/me/phone/", {"phone": "01233334444", "code": "1234"})
    assert res.status_code == 200
    customer.refresh_from_db()
    assert customer.phone == "01233334444"
    other = User.objects.create_user(phone="01244445555")
    assert customer_api.post("/api/v1/me/phone/", {"phone": other.phone, "code": "1234"}).status_code == 400


def test_token_refresh(api, customer):
    from rest_framework_simplejwt.tokens import RefreshToken

    res = api.post("/api/v1/auth/token/refresh/", {"refresh": str(RefreshToken.for_user(customer))})
    assert res.status_code == 200 and "access" in res.json()


def test_staff_login(api, staff, customer):
    assert api.post("/api/v1/admin/auth/login/", {"phone": staff.phone, "password": "Str0ng-pass!"}).status_code == 200
    assert api.post("/api/v1/admin/auth/login/", {"phone": staff.phone, "password": "wrong"}).status_code == 401
    customer.set_password("Customer-pass1")
    customer.save()
    assert (
        api.post("/api/v1/admin/auth/login/", {"phone": customer.phone, "password": "Customer-pass1"}).status_code
        == 401
    )


def test_addresses_default_rules(customer_api, customer):
    first = customer_api.post(
        "/api/v1/addresses/", {"zone": "cairo", "area": "Nasr City", "street": "Abbas", "building": "5"}
    ).json()
    second = customer_api.post(
        "/api/v1/addresses/",
        {"zone": "giza", "area": "Dokki", "street": "Tahrir", "building": "9", "lat": 30.04, "lng": 31.2},
    ).json()
    assert first["is_default"] is True and second["is_default"] is False
    assert second["zone_name"] == "الجيزة" and second["lat"] == 30.04

    customer_api.patch(f"/api/v1/addresses/{second['id']}/", {"is_default": True})
    listed = customer_api.get("/api/v1/addresses/").json()
    assert [a["id"] for a in listed if a["is_default"]] == [second["id"]]

    customer_api.delete(f"/api/v1/addresses/{second['id']}/")
    assert customer_api.get("/api/v1/addresses/").json()[0]["is_default"] is True

    stranger = client_for(User.objects.create_user(phone="01266667777"))
    assert stranger.delete(f"/api/v1/addresses/{first['id']}/").status_code == 404
    assert (
        customer_api.post(
            "/api/v1/addresses/", {"zone": "mars", "area": "x", "street": "y", "building": "1"}
        ).status_code
        == 400
    )


def test_endpoints_require_auth(api):
    for path in ("/api/v1/me/", "/api/v1/addresses/", "/api/v1/orders/"):
        assert api.get(path).status_code == 401


def test_otp_cannot_open_staff_accounts(api, staff):
    api.post(SEND, {"phone": staff.phone})
    res = api.post(VERIFY, {"phone": staff.phone, "code": "1234"})
    assert res.status_code == 403 and res.json()["code"] == "staff_account"


def test_ensure_admin_and_email_login(api, client):
    from django.core.management import call_command

    call_command("ensure_admin", email="Admin@GM.com", password="admin", verbosity=0)
    admin = User.objects.get(email="admin@gm.com")
    assert admin.is_superuser and admin.is_staff and admin.phone.startswith("0100000")

    # Staff API login with email
    res = api.post("/api/v1/admin/auth/login/", {"login": "admin@gm.com", "password": "admin"})
    assert res.status_code == 200 and res.json()["user"]["phone"] == admin.phone
    assert api.post("/api/v1/admin/auth/login/", {"login": "admin@gm.com", "password": "nope"}).status_code == 401

    # Django admin login page with email
    page = client.post("/admin/login/?next=/admin/", {"username": "admin@gm.com", "password": "admin"})
    assert page.status_code == 302 and page.url == "/admin/"

    # Running it again updates the same account
    call_command("ensure_admin", email="admin@gm.com", password="New-Pass-2026!", verbosity=0)
    assert User.objects.filter(email="admin@gm.com").count() == 1
    admin.refresh_from_db()
    assert admin.check_password("New-Pass-2026!")


def test_email_login_ignores_customers(api, customer):
    customer.email = "mona@example.com"
    customer.set_password("Customer-pass1")
    customer.save()
    assert (
        api.post("/api/v1/admin/auth/login/", {"login": "mona@example.com", "password": "Customer-pass1"}).status_code
        == 401
    )


def test_gunicorn_defaults():
    from config import gunicorn

    assert (gunicorn.workers, gunicorn.threads, gunicorn.bind) == (1, 1, "127.0.0.1:8077")

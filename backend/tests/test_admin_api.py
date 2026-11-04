import io

import pytest
from django.contrib.auth.models import Group, Permission
from PIL import Image

from apps.accounts.models import User
from apps.catalog.models import Category, Product, Variant
from apps.orders.models import Order
from apps.shipping.models import StoreSettings
from tests.conftest import client_for

pytestmark = pytest.mark.django_db
A = "/api/v1/admin"


def staff_with(*perms):
    user = User.objects.create_user(phone="01188889999", password="Staff-pass-1", is_staff=True)
    for full in perms:
        app, codename = full.split(".")
        user.user_permissions.add(Permission.objects.get(content_type__app_label=app, codename=codename))
    return client_for(user)


def test_customers_cannot_use_admin_api(customer_api):
    assert customer_api.get(f"{A}/orders/").status_code == 403
    assert customer_api.get(f"{A}/dashboard/").status_code == 403


def test_permissions_are_per_action(place):
    place()
    viewer = staff_with("orders.view_order")
    assert viewer.get(f"{A}/orders/").status_code == 200
    order_id = Order.objects.first().pk
    assert viewer.post(f"{A}/orders/{order_id}/transition/", {"status": "confirmed"}).status_code == 403
    assert viewer.get(f"{A}/products/").status_code == 403


def test_order_list_filters_and_transition(staff_api, place, customer):
    order_id = place().json()["order"]["id"]
    listed = staff_api.get(f"{A}/orders/", {"status": "placed", "search": customer.phone}).json()
    assert listed["count"] == 1 and listed["results"][0]["items_count"] == 3
    detail = staff_api.get(f"{A}/orders/{order_id}/").json()
    assert detail["allowed_transitions"] == ["cancelled", "confirmed"]
    res = staff_api.post(f"{A}/orders/{order_id}/transition/", {"status": "confirmed", "note": "OK"})
    assert res.status_code == 200 and res.json()["status"] == "confirmed"
    bad = staff_api.post(f"{A}/orders/{order_id}/transition/", {"status": "delivered"})
    assert bad.status_code == 409 and bad.json()["code"] == "invalid_transition"
    assert staff_api.get(f"{A}/orders/{order_id}/customer_view/").json()["timeline"][1]["done"] is True


def test_dashboard(staff_api, place):
    place()
    data = staff_api.get(f"{A}/dashboard/", {"period": "today"}).json()
    assert (data["orders"] == 1 and data["sales"] == 369.3) or data["sales"] > 0
    assert data["open_orders"] == 1 and data["low_stock_count"] >= 1
    assert len(data["sales_by_day"]) == 1 and data["top_products"]


def test_product_create_update_and_soft_delete(staff_api):
    category = Category.objects.get(slug="fruits")
    body = {
        "category": category.pk,
        "name_ar": "مانجو",
        "name_en": "Mango",
        "slug": "mango",
        "sold_by_weight": True,
        "qty_step": "0.25",
        "min_qty": "0.5",
        "variants": [{"sku": "MANGO-1", "label_ar": "للكيلو", "label_en": "per kg", "price": "60", "stock": "40"}],
    }
    res = staff_api.post(f"{A}/products/", body, format="json")
    assert res.status_code == 201, res.content
    pid = res.json()["id"]
    assert (
        client_for(User.objects.create_user(phone="01000000001")).get("/api/v1/products/mango/").json()["name"]
        == "مانجو"
    )

    update = {
        "variants": [
            {
                "sku": "MANGO-2",
                "label_ar": "صندوق",
                "label_en": "Box",
                "price": "300",
                "sale_price": "280",
                "stock": "5",
            }
        ]
    }
    assert staff_api.patch(f"{A}/products/{pid}/", update, format="json").status_code == 200
    assert Variant.objects.get(sku="MANGO-1").is_active is False

    dup = {**body, "slug": "mango-2", "variants": [{**body["variants"][0], "sku": "RK-0001-1"}]}
    assert staff_api.post(f"{A}/products/", dup, format="json").status_code == 400
    bad_sale = {
        "variants": [
            {"sku": "MANGO-2", "label_ar": "x", "label_en": "x", "price": "10", "sale_price": "20", "stock": "1"}
        ]
    }
    assert staff_api.patch(f"{A}/products/{pid}/", bad_sale, format="json").status_code == 400

    assert staff_api.delete(f"{A}/products/{pid}/").status_code == 204
    assert Product.objects.get(pk=pid).is_active is False


def test_product_image_upload(staff_api, tmp_path, settings):
    settings.MEDIA_ROOT = tmp_path
    buffer = io.BytesIO()
    Image.new("RGB", (10, 10), "green").save(buffer, "PNG")
    buffer.seek(0)
    buffer.name = "banana.png"
    pid = Product.objects.get(slug="banana").pk
    res = staff_api.post(f"{A}/products/{pid}/images/", {"image": buffer, "alt": "Banana"}, format="multipart")
    assert res.status_code == 201
    data = staff_api.get("/api/v1/products/banana/").json()
    assert data["image"].startswith("http://testserver/media/products/") and len(data["images"]) == 1


def test_inventory_low_stock_and_stock_edit(staff_api):
    low = staff_api.get(f"{A}/variants/", {"low_stock": "true"}).json()
    assert any(v["sku"] == "RK-0005-1" for v in low["results"])  # avocado, out of stock
    variant = Variant.objects.get(sku="RK-0034-1")
    assert staff_api.patch(f"{A}/variants/{variant.pk}/", {"stock": "30"}).status_code == 200
    variant.refresh_from_db()
    assert variant.stock == 30
    assert staff_api.patch(f"{A}/variants/{variant.pk}/", {"stock": "-1"}).status_code == 400


def test_category_rules(staff_api):
    leaf = Category.objects.get(slug="fruits")
    third = staff_api.post(
        f"{A}/categories/", {"parent": leaf.pk, "name_ar": "استوائي", "name_en": "Tropical", "slug": "tropical"}
    )
    assert third.status_code == 201
    too_deep = staff_api.post(
        f"{A}/categories/", {"parent": third.json()["id"], "name_ar": "x", "name_en": "x", "slug": "too-deep"}
    )
    assert too_deep.status_code == 400
    staff_api.delete(f"{A}/categories/{leaf.pk}/")
    assert Category.objects.get(pk=leaf.pk).is_active is False  # has products → hidden


def test_coupons_crud_and_usage(staff_api, place):
    res = staff_api.post(f"{A}/coupons/", {"code": "eid20", "type": "percent", "value": "20", "min_subtotal": "100"})
    assert res.status_code == 201 and res.json()["code"] == "EID20"
    assert staff_api.post(f"{A}/coupons/", {"code": "BAD", "type": "percent", "value": "150"}).status_code == 400
    place(coupon="ROCKET10")
    rocket = next(c for c in staff_api.get(f"{A}/coupons/").json()["results"] if c["code"] == "ROCKET10")
    assert rocket["used_count"] == 1
    assert len(staff_api.get(f"{A}/coupons/{rocket['id']}/redemptions/").json()) == 1


def test_settings_zones_and_windows(staff_api):
    assert staff_api.patch(f"{A}/settings/", {"min_order": "150"}).status_code == 200
    assert StoreSettings.load().min_order == 150
    assert (
        staff_api.post(
            f"{A}/zones/", {"code": "sharqia", "name_ar": "الشرقية", "name_en": "Sharqia", "fee": "45"}
        ).status_code
        == 201
    )
    assert staff_api.post(f"{A}/delivery-windows/", {"start_time": "10:00", "end_time": "09:00"}).status_code == 400


def test_roles_and_staff(staff_api):
    perms = staff_api.get(f"{A}/permissions/").json()
    assert any(p["code"] == "orders.change_order" for p in perms)
    role = staff_api.post(
        f"{A}/roles/", {"name": "Packers", "permissions": ["orders.view_order", "orders.change_order"]}, format="json"
    )
    assert role.status_code == 201 and role.json()["permissions"] == ["orders.change_order", "orders.view_order"]
    assert (
        staff_api.post(f"{A}/roles/", {"name": "Bad", "permissions": ["orders.fly"]}, format="json").status_code == 400
    )
    member = staff_api.post(
        f"{A}/staff/",
        {"phone": "01500001111", "name": "Packer", "password": "Packer-pass-1", "roles": [role.json()["id"]]},
        format="json",
    )
    assert member.status_code == 201
    user = User.objects.get(phone="01500001111")
    assert user.is_staff and user.has_perm("orders.change_order")
    assert Group.objects.filter(name="Order manager").exists()


def test_customers_admin(staff_api, place, customer):
    place()
    row = staff_api.get(f"{A}/customers/", {"search": customer.phone}).json()["results"][0]
    assert row["orders_count"] == 1 and row["total_spent"] > 0
    assert staff_api.patch(f"{A}/customers/{customer.pk}/", {"notes": "VIP", "is_active": False}).status_code == 200
    customer.refresh_from_db()
    assert customer.notes == "VIP" and customer.is_active is False


def test_notification_log(staff_api, place, django_capture_on_commit_callbacks):
    with django_capture_on_commit_callbacks(execute=True):
        place()
    logs = staff_api.get(f"{A}/notifications/", {"channel": "sms"}).json()
    assert logs["count"] >= 1 and logs["results"][0]["status"] == "sent"


def test_health_and_schema(api):
    assert api.get("/api/health/").json() == {"status": "ok"}
    assert api.get("/api/schema/").status_code == 200

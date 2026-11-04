import pytest
from django.core.cache import cache
from django.core.management import call_command
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from apps.accounts.models import Address, User
from apps.shipping.models import Zone
from apps.shipping.services import delivery_slots


@pytest.fixture(scope="session")
def django_db_setup(django_db_setup, django_db_blocker):
    """Seed the demo catalog once; every test runs in a rolled-back transaction."""
    with django_db_blocker.unblock():
        call_command("seed_demo", verbosity=0)


@pytest.fixture(autouse=True)
def _clear_cache(db):
    cache.clear()
    yield
    cache.clear()


@pytest.fixture
def api():
    return APIClient()


def client_for(user: User) -> APIClient:
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {RefreshToken.for_user(user).access_token}")
    return client


@pytest.fixture
def customer(db):
    return User.objects.create_user(phone="01011112222", name="Mona")


@pytest.fixture
def customer_api(customer):
    return client_for(customer)


@pytest.fixture
def staff(db):
    return User.objects.create_superuser(phone="01099990000", password="Str0ng-pass!")


@pytest.fixture
def staff_api(staff):
    return client_for(staff)


@pytest.fixture
def address(customer):
    return Address.objects.create(
        user=customer,
        zone=Zone.objects.get(code="giza"),
        area="الدقي",
        street="شارع التحرير",
        building="12",
        is_default=True,
    )


@pytest.fixture
def slot_id():
    def pick(express=False):
        for day in delivery_slots():
            for slot in day["slots"]:
                if slot["available"] and slot["express"] == express:
                    return slot["id"]
        raise AssertionError("No available slot")

    return pick


@pytest.fixture
def place(customer_api, address, slot_id):
    """Places an order through the API and returns the response."""

    def _place(items=None, **overrides):
        body = {
            "items": items
            or [{"sku": "RK-0001-1", "qty": 2}, {"sku": "RK-0014-2", "qty": 2}, {"sku": "RK-0036-2", "qty": 1}],
            "method": "delivery",
            "address_id": address.pk,
            "slot_id": slot_id(),
            "payment_method": "cod",
            **overrides,
        }
        return customer_api.post("/api/v1/orders/", body, format="json")

    return _place

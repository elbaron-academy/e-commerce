from django.conf import settings

from .base import PaymentGateway, WebhookResult
from .dummy import DummyGateway

GATEWAYS: dict[str, type[PaymentGateway]] = {DummyGateway.name: DummyGateway}


def get_gateway(name: str | None = None) -> PaymentGateway:
    name = name or settings.PAYMENT_PROVIDER
    try:
        return GATEWAYS[name]()
    except KeyError as exc:
        raise RuntimeError(f"Unknown PAYMENT_PROVIDER '{name}'. Available: {', '.join(GATEWAYS)}") from exc


__all__ = ["GATEWAYS", "PaymentGateway", "WebhookResult", "get_gateway"]

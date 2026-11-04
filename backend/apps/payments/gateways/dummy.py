import json

from django.conf import settings

from .base import PaymentGateway, WebhookResult


class DummyGateway(PaymentGateway):
    """
    Test gateway for development and demos. Sends the customer to the storefront's
    /payment/mock page. Webhooks are JSON signed with HMAC-SHA256 in X-Rocket-Signature:
    {"event_id": "...", "reference": "...", "status": "paid" | "failed"}
    """

    name = "dummy"

    def create_payment(self, payment) -> str:
        return f"/payment/mock?order={payment.order_id}"

    def parse_webhook(self, request) -> WebhookResult:
        self.verify_hmac(settings.PAYMENT_WEBHOOK_SECRET, request.body, request.headers.get("X-Rocket-Signature", ""))
        data = json.loads(request.body or b"{}")
        return WebhookResult(
            event_id=str(data.get("event_id", "")),
            reference=str(data.get("reference", "")),
            success=data.get("status") == "paid",
            transaction_id=str(data.get("transaction_id", "")),
            payload=data,
        )

"""
Payment gateway interface (BE-504). Each provider (Paymob, Fawry, …) implements:

- create_payment: register the payment and return the URL to send the customer to
- parse_webhook: verify the callback signature and say which payment succeeded or failed
"""

import hashlib
import hmac
from abc import ABC, abstractmethod
from dataclasses import dataclass


class InvalidSignature(Exception):
    pass


@dataclass
class WebhookResult:
    event_id: str
    reference: str
    success: bool
    transaction_id: str = ""
    payload: dict | None = None


class PaymentGateway(ABC):
    name: str

    @abstractmethod
    def create_payment(self, payment) -> str: ...

    @abstractmethod
    def parse_webhook(self, request) -> WebhookResult: ...

    @staticmethod
    def verify_hmac(secret: str, body: bytes, signature: str, digest=hashlib.sha256) -> None:
        expected = hmac.new(secret.encode(), body, digest).hexdigest()
        if not signature or not hmac.compare_digest(expected, signature.lower()):
            raise InvalidSignature("Bad webhook signature")

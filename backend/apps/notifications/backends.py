"""Delivery backends. Pick them with SMS_BACKEND / PUSH_BACKEND settings."""

import logging

logger = logging.getLogger("rocket.notifications")


class BaseSMSBackend:
    def send(self, to: str, body: str) -> None:
        raise NotImplementedError


class ConsoleSMSBackend(BaseSMSBackend):
    """Development: prints the SMS to the log. Replace with the chosen SMS provider."""

    def send(self, to: str, body: str) -> None:
        logger.info("SMS to %s:\n%s", to, body)


class LogPushBackend:
    """Placeholder until FCM device tokens are collected (MOB-504)."""

    def send(self, user, title: str, body: str, data: dict | None = None) -> bool:
        logger.info("PUSH to user %s: %s · %s", getattr(user, "pk", None), title, body)
        return False

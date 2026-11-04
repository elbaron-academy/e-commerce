import os

os.environ["SECRET_KEY"] = "test-secret-key-that-is-long-enough-for-hs256"
os.environ["DJANGO_ENV_FILE"] = "/nonexistent"  # never read a developer's .env in tests
os.environ.setdefault("DATABASE_URL", "sqlite://:memory:")

from .base import *  # noqa: F403

DEBUG = False
ALLOWED_HOSTS = ["*"]
PASSWORD_HASHERS = ["django.contrib.auth.hashers.MD5PasswordHasher"]
CACHES = {"default": {"BACKEND": "django.core.cache.backends.locmem.LocMemCache"}}
CELERY_TASK_ALWAYS_EAGER = True
CELERY_TASK_EAGER_PROPAGATES = True
EMAIL_BACKEND = "django.core.mail.backends.locmem.EmailBackend"
OTP_FIXED_CODE = "1234"
PAYMENT_PROVIDER = "dummy"
PAYMENT_WEBHOOK_SECRET = "test-webhook-secret"
STAFF_ALERT_EMAILS = ["ops@rocket.test"]
REST_FRAMEWORK = {**REST_FRAMEWORK, "DEFAULT_THROTTLE_RATES": {"otp": "1000/hour", "login": "1000/minute"}}

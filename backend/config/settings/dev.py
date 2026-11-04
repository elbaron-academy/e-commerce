import os

os.environ.setdefault("SECRET_KEY", "dev-only-insecure-key")
os.environ.setdefault("DEBUG", "true")
os.environ.setdefault("OTP_FIXED_CODE", "1234")

from .base import *  # noqa: F403

ALLOWED_HOSTS = ["*"]

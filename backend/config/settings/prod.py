from .base import *  # noqa: F403
from .base import env

DEBUG = False

# nginx terminates TLS and forwards the original scheme.
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
USE_X_FORWARDED_HOST = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_REFERRER_POLICY = "same-origin"
SECURE_HSTS_SECONDS = env.int("SECURE_HSTS_SECONDS", default=60 * 60 * 24 * 30)
SECURE_HSTS_INCLUDE_SUBDOMAINS = False
SECURE_SSL_REDIRECT = env.bool("SECURE_SSL_REDIRECT", default=False)  # nginx already redirects
SILENCED_SYSTEM_CHECKS = [
    "security.W008",  # SSL redirect is done by nginx
    "security.W005",  # HSTS for all subdomains: other subdomains may not use HTTPS
    "security.W021",  # HSTS preload: opt in later, it is hard to undo
]

STORAGES["staticfiles"] = {"BACKEND": "whitenoise.storage.CompressedManifestStaticFilesStorage"}

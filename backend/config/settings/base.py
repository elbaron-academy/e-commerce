"""
Shared settings. Everything environment-specific comes from environment
variables or a .env file (see .env.example). Pick the environment with
DJANGO_SETTINGS_MODULE=config.settings.{dev,test,prod}.
"""

from datetime import timedelta
from pathlib import Path

import environ

BASE_DIR = Path(__file__).resolve().parents[2]

env = environ.Env()
# DJANGO_ENV_FILE lets servers keep the .env outside the code (e.g. /opt/rocket/.env).
env_file = Path(env.str("DJANGO_ENV_FILE", default=str(BASE_DIR / ".env")))
if env_file.is_file():
    env.read_env(env_file)

SECRET_KEY = env.str("SECRET_KEY")
DEBUG = env.bool("DEBUG", default=False)
ALLOWED_HOSTS = env.list("ALLOWED_HOSTS", default=["localhost", "127.0.0.1"])
CSRF_TRUSTED_ORIGINS = env.list("CSRF_TRUSTED_ORIGINS", default=[])

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    # Third party
    "rest_framework",
    "rest_framework_simplejwt",
    "django_filters",
    "corsheaders",
    "drf_spectacular",
    # Rocket
    "apps.core",
    "apps.accounts",
    "apps.shipping",
    "apps.catalog",
    "apps.promotions",
    "apps.orders",
    "apps.payments",
    "apps.notifications",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.locale.LocaleMiddleware",
    "apps.core.middleware.QueryLanguageMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"
WSGI_APPLICATION = "config.wsgi.application"
AUTH_USER_MODEL = "accounts.User"
AUTHENTICATION_BACKENDS = ["apps.accounts.backends.PhoneOrEmailBackend"]
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

# ---- Database ----
# SQLite by default; set DATABASE_URL=postgres://... to switch.
DATABASES = {"default": env.db("DATABASE_URL", default=f"sqlite:///{BASE_DIR / 'db.sqlite3'}")}
if DATABASES["default"]["ENGINE"] == "django.db.backends.sqlite3":
    DATABASES["default"].setdefault("OPTIONS", {}).update(
        {
            # Take the write lock at the start of each transaction, so two
            # checkouts can't both sell the last item.
            "transaction_mode": "IMMEDIATE",
            "timeout": 20,
            "init_command": "PRAGMA journal_mode=WAL; PRAGMA synchronous=NORMAL; PRAGMA foreign_keys=ON;",
        }
    )
DATABASES["default"]["ATOMIC_REQUESTS"] = False
DATABASES["default"]["CONN_MAX_AGE"] = env.int("DB_CONN_MAX_AGE", default=60)

# ---- Cache ----
# Redis when available, otherwise a file cache shared by all workers on the machine.
REDIS_URL = env.str("REDIS_URL", default="")
if REDIS_URL:
    CACHES = {"default": {"BACKEND": "django.core.cache.backends.redis.RedisCache", "LOCATION": REDIS_URL}}
else:
    CACHES = {
        "default": {
            "BACKEND": "django.core.cache.backends.filebased.FileBasedCache",
            "LOCATION": env.str("CACHE_DIR", default=str(BASE_DIR / ".cache")),
        }
    }

# ---- Celery ----
# Without a broker, tasks run inline (fine for one server; add Redis to scale).
CELERY_BROKER_URL = env.str("CELERY_BROKER_URL", default="")
CELERY_TASK_ALWAYS_EAGER = not CELERY_BROKER_URL
CELERY_TASK_EAGER_PROPAGATES = False
CELERY_TASK_IGNORE_RESULT = True
CELERY_TIMEZONE = "Africa/Cairo"
CELERY_BEAT_SCHEDULE = {
    "release-expired-reservations": {
        "task": "apps.orders.tasks.release_expired_reservations",
        "schedule": 60.0,
    },
}

# ---- Auth ----
AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

# ---- i18n ----
LANGUAGE_CODE = "ar"
LANGUAGES = [("ar", "العربية"), ("en", "English")]
TIME_ZONE = "Africa/Cairo"
USE_I18N = True
USE_TZ = True

# ---- Static & media ----
STATIC_URL = "static/"
STATIC_ROOT = Path(env.str("STATIC_ROOT", default=str(BASE_DIR / "staticfiles")))
MEDIA_URL = env.str("MEDIA_URL", default="/media/")
MEDIA_ROOT = Path(env.str("MEDIA_ROOT", default=str(BASE_DIR / "media")))
# Let Django serve uploads itself (Docker without nginx). nginx serves them on the VM.
SERVE_MEDIA = env.bool("SERVE_MEDIA", default=False)
STORAGES = {
    "default": {"BACKEND": "django.core.files.storage.FileSystemStorage"},
    "staticfiles": {"BACKEND": "django.contrib.staticfiles.storage.StaticFilesStorage"},
}
AWS_STORAGE_BUCKET_NAME = env.str("AWS_STORAGE_BUCKET_NAME", default="")
if AWS_STORAGE_BUCKET_NAME:
    STORAGES["default"] = {"BACKEND": "storages.backends.s3.S3Storage"}
    AWS_S3_REGION_NAME = env.str("AWS_S3_REGION_NAME", default="eu-central-1")
    AWS_S3_CUSTOM_DOMAIN = env.str("AWS_S3_CUSTOM_DOMAIN", default="") or None
    AWS_QUERYSTRING_AUTH = False
    AWS_DEFAULT_ACL = None

# ---- REST framework ----
REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": ["rest_framework_simplejwt.authentication.JWTAuthentication"],
    "DEFAULT_PERMISSION_CLASSES": ["rest_framework.permissions.AllowAny"],
    "DEFAULT_RENDERER_CLASSES": ["rest_framework.renderers.JSONRenderer"],
    "DEFAULT_PARSER_CLASSES": [
        "rest_framework.parsers.JSONParser",
        "rest_framework.parsers.MultiPartParser",
        "rest_framework.parsers.FormParser",
    ],
    "DEFAULT_FILTER_BACKENDS": ["django_filters.rest_framework.DjangoFilterBackend"],
    "DEFAULT_PAGINATION_CLASS": "apps.core.pagination.StandardPagination",
    "DEFAULT_SCHEMA_CLASS": "drf_spectacular.openapi.AutoSchema",
    "EXCEPTION_HANDLER": "apps.core.exceptions.api_exception_handler",
    "COERCE_DECIMAL_TO_STRING": False,
    "DEFAULT_THROTTLE_CLASSES": [],
    "DEFAULT_THROTTLE_RATES": {
        "otp": env.str("OTP_IP_RATE", default="20/hour"),
        "login": "10/minute",
    },
    "TEST_REQUEST_DEFAULT_FORMAT": "json",
    # Proxies in front of Django (nginx = 1), so throttling sees the real client IP.
    "NUM_PROXIES": env.int("NUM_PROXIES", default=None),
}

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=env.int("JWT_ACCESS_MINUTES", default=60 * 24)),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=env.int("JWT_REFRESH_DAYS", default=30)),
    "ROTATE_REFRESH_TOKENS": True,
    "UPDATE_LAST_LOGIN": True,
    "AUTH_HEADER_TYPES": ("Bearer",),
}

SPECTACULAR_SETTINGS = {
    "TITLE": "Rocket Market API",
    "DESCRIPTION": "Backend for the Rocket Market supermarket: storefront, mobile app and admin dashboard.",
    "VERSION": "1.0.0",
    "SERVE_INCLUDE_SCHEMA": False,
    "COMPONENT_SPLIT_REQUEST": True,
    "SCHEMA_PATH_PREFIX": r"/api/v1",
    "ENUM_NAME_OVERRIDES": {
        "OrderStatusEnum": "apps.orders.models.Order.Status",
        "PaymentRecordStatusEnum": "apps.payments.models.Payment.Status",
        "NotificationStatusEnum": "apps.notifications.models.NotificationLog.Status",
    },
}

# ---- CORS (storefront and admin dashboard origins) ----
CORS_ALLOWED_ORIGINS = env.list("CORS_ALLOWED_ORIGINS", default=["http://localhost:3000"])
CORS_URLS_REGEX = r"^/api/.*$"

# ---- Email ----
EMAIL_BACKEND = env.str("EMAIL_BACKEND", default="django.core.mail.backends.console.EmailBackend")
DEFAULT_FROM_EMAIL = env.str("DEFAULT_FROM_EMAIL", default="Rocket Market <no-reply@rocket.local>")
EMAIL_HOST = env.str("EMAIL_HOST", default="localhost")
EMAIL_PORT = env.int("EMAIL_PORT", default=587)
EMAIL_HOST_USER = env.str("EMAIL_HOST_USER", default="")
EMAIL_HOST_PASSWORD = env.str("EMAIL_HOST_PASSWORD", default="")
EMAIL_USE_TLS = env.bool("EMAIL_USE_TLS", default=True)

# ---- Rocket business settings ----
STOREFRONT_URL = env.str("STOREFRONT_URL", default="http://localhost:3000")
# Fixed OTP for demos and tests. Leave empty in production once SMS is live.
OTP_FIXED_CODE = env.str("OTP_FIXED_CODE", default="")
OTP_TTL_SECONDS = 120
OTP_RESEND_SECONDS = 60
OTP_MAX_SENDS_PER_HOUR = 5
OTP_MAX_ATTEMPTS = 5
# Domain in the SMS for WebOTP autofill ("@domain #1234").
OTP_WEBOTP_DOMAIN = env.str("OTP_WEBOTP_DOMAIN", default="localhost")
SMS_BACKEND = env.str("SMS_BACKEND", default="apps.notifications.backends.ConsoleSMSBackend")
PUSH_BACKEND = env.str("PUSH_BACKEND", default="apps.notifications.backends.LogPushBackend")
PAYMENT_PROVIDER = env.str("PAYMENT_PROVIDER", default="dummy")
PAYMENT_WEBHOOK_SECRET = env.str("PAYMENT_WEBHOOK_SECRET", default="change-me")
STOCK_RESERVATION_MINUTES = env.int("STOCK_RESERVATION_MINUTES", default=15)
STAFF_ALERT_EMAILS = env.list("STAFF_ALERT_EMAILS", default=[])

# ---- Logging ----
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {"plain": {"format": "%(asctime)s %(levelname)s %(name)s %(message)s"}},
    "handlers": {"console": {"class": "logging.StreamHandler", "formatter": "plain"}},
    "root": {"handlers": ["console"], "level": env.str("LOG_LEVEL", default="INFO")},
    "loggers": {"django.db.backends": {"level": "WARNING"}},
}

SENTRY_DSN = env.str("SENTRY_DSN", default="")
if SENTRY_DSN:
    import sentry_sdk

    sentry_sdk.init(
        dsn=SENTRY_DSN, traces_sample_rate=env.float("SENTRY_TRACES_RATE", default=0.1), send_default_pii=False
    )

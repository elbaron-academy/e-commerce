"""Gunicorn settings. Override any of them in /opt/rocket/.env (GUNICORN_*)."""

import os

bind = os.environ.get("GUNICORN_BIND", "127.0.0.1:8000")
workers = int(os.environ.get("GUNICORN_WORKERS", "1"))
threads = int(os.environ.get("GUNICORN_THREADS", "1"))
timeout = int(os.environ.get("GUNICORN_TIMEOUT", "60"))
graceful_timeout = 30
max_requests = int(os.environ.get("GUNICORN_MAX_REQUESTS", "1000"))  # recycle workers to limit memory growth
max_requests_jitter = 100
accesslog = "-"
errorlog = "-"
loglevel = os.environ.get("GUNICORN_LOG_LEVEL", "info")

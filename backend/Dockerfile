# Rocket API (Django + gunicorn). SQLite lives in the /data volume.
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    DJANGO_SETTINGS_MODULE=config.settings.prod \
    DATABASE_URL=sqlite:////data/db.sqlite3 \
    CACHE_DIR=/data/cache \
    MEDIA_ROOT=/data/media \
    STATIC_ROOT=/app/staticfiles

WORKDIR /app
RUN useradd --create-home --uid 1000 rocket
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
RUN SECRET_KEY=build-only-not-secret DJANGO_ENV_FILE=/nonexistent python manage.py collectstatic --noinput \
    && mkdir -p /data && chown -R rocket:rocket /data /app
USER rocket
VOLUME ["/data"]
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=5s CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/api/health/')"
CMD ["sh", "-c", "python manage.py migrate --noinput && python manage.py seed_demo --if-empty && gunicorn config.wsgi:application --bind 0.0.0.0:8000 --workers 3 --threads 2 --access-logfile -"]

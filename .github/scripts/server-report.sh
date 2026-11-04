#!/usr/bin/env bash
# Runs on the VM: a short, secret-free status report for the workflow summary.
set -u
APP=/opt/rocket
echo "services: rocket-api $(systemctl is-active rocket-api) · rocket-web $(systemctl is-active rocket-web) · nginx $(systemctl is-active nginx) · jobs timer $(systemctl is-active rocket-jobs.timer) · backup timer $(systemctl is-active rocket-backup.timer)"
master="$(systemctl show -p MainPID --value rocket-api 2>/dev/null || echo 0)"
if [ "${master:-0}" -gt 0 ]; then
  children="$(pgrep -P "$master" | tr '\n' ' ')"
  threads="$(for pid in $children; do ps -o nlwp= -p "$pid"; done | tr -d ' ' | sort -u | tr '\n' ' ')"
  echo "gunicorn: 1 master (pid $master) · workers: $(echo "$children" | wc -w) · threads per worker: ${threads:-?}"
fi
echo "configured: $(grep -E '^GUNICORN_(WORKERS|THREADS)=' "$APP/.env" 2>/dev/null | tr '\n' ' ')"
echo "local checks: API $(curl -s -m 5 -H 'Host: 127.0.0.1' http://127.0.0.1:8077/api/health/ || echo down) · storefront HTTP $(curl -s -o /dev/null -w '%{http_code}' -m 5 http://127.0.0.1:3000/ || echo down)"
echo "ports: $(sudo -n ss -ltnpH 2>/dev/null | awk '$4 ~ /:(3000|8000|8077)$/ {split($6, p, "\""); printf "%s → %s  ", $4, p[2]}')"
if [ "$(systemctl is-active rocket-api)" != active ]; then
  echo "rocket-api log:"
  sudo -n journalctl -u rocket-api -n 15 --no-pager -o cat 2>/dev/null | grep -vE '"(GET|POST|HEAD|PUT|PATCH|DELETE|OPTIONS) '
fi
if [ -L "$APP/backend" ]; then
  echo "releases: backend $(basename "$(dirname "$(readlink -f "$APP/backend")")") · storefront $(basename "$(readlink -f /var/www/html/rocket/current 2>/dev/null)")"
fi
for d in rocket.hossam-ameen.online api.rocket.hossam-ameen.online; do
  if sudo -n test -f "/etc/letsencrypt/live/$d/fullchain.pem" 2>/dev/null; then
    echo "certificate $d: $(sudo -n openssl x509 -enddate -noout -in "/etc/letsencrypt/live/$d/fullchain.pem" | cut -d= -f2)"
  else
    echo "certificate $d: none yet"
  fi
done
if [ -f "$APP/backend/manage.py" ]; then
  counts="$(cd "$APP/backend" && DJANGO_SETTINGS_MODULE=config.settings.prod DJANGO_ENV_FILE="$APP/.env" "$APP/venv/bin/python" manage.py shell --no-imports -c "
from apps.accounts.models import User
from apps.catalog.models import Product
from apps.orders.models import Order
print(f'superusers {User.objects.filter(is_superuser=True).count()} · products {Product.objects.count()} · orders {Order.objects.count()}')" 2>/dev/null)"
  echo "database: ${counts:-unavailable}"
fi
echo "system: $(. /etc/os-release && echo "$PRETTY_NAME") · python $(python3 -V 2>&1 | cut -d' ' -f2) · node $(node -v 2>/dev/null || echo none) · nginx $(/usr/sbin/nginx -v 2>&1 | cut -d/ -f2)"

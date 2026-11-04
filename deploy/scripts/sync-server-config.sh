#!/usr/bin/env bash
# Installs the systemd units and nginx sites from this deploy/ folder. Run as root.
# Used by server-setup.sh and by every deploy, so config changes in git reach the server.
# Uses the full HTTPS sites once certificates exist, otherwise a temporary HTTP config.
set -euo pipefail

DEPLOY_USER="${1:-${DEPLOY_USER:-hossam}}"
WEB_DOMAIN="${WEB_DOMAIN:-rocket.hossam-ameen.online}"
API_DOMAIN="${API_DOMAIN:-api.rocket.hossam-ameen.online}"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Drop IPv6 listen lines on machines where IPv6 is disabled.
site_filter() { if [ -f /proc/net/if_inet6 ]; then cat; else grep -v 'listen \[::\]'; fi; }
put() {  # put <target> <mode>  (content on stdin); prints when the file changed
  local tmp; tmp="$(mktemp)"; cat > "$tmp"
  if ! cmp -s "$tmp" "$1"; then install -m "$2" "$tmp" "$1"; echo "updated $1"; rm -f "$tmp"; return 0; fi
  rm -f "$tmp"; return 1
}

units_changed=0
for unit in "$SRC"/systemd/*; do
  sed "s/__USER__/$DEPLOY_USER/g" "$unit" | put "/etc/systemd/system/$(basename "$unit")" 644 && units_changed=1 || true
done
if [ "$units_changed" = 1 ]; then systemctl daemon-reload; fi

put /etc/nginx/snippets/rocket-ssl.conf 644 < "$SRC/nginx/rocket-ssl.conf" || true
if [ -f "/etc/letsencrypt/live/$WEB_DOMAIN/fullchain.pem" ] && [ -f "/etc/letsencrypt/live/$API_DOMAIN/fullchain.pem" ]; then
  for domain in "$WEB_DOMAIN" "$API_DOMAIN"; do
    site_filter < "$SRC/nginx/$domain.conf" | put "/etc/nginx/sites-available/$domain.conf" 644 || true
    ln -sfn "/etc/nginx/sites-available/$domain.conf" "/etc/nginx/sites-enabled/$domain.conf"
  done
  rm -f /etc/nginx/sites-enabled/rocket-bootstrap.conf
else
  sed -e "s/__WEB_DOMAIN__/$WEB_DOMAIN/g" -e "s/__API_DOMAIN__/$API_DOMAIN/g" "$SRC/nginx/bootstrap-http.conf" \
    | site_filter | put /etc/nginx/sites-available/rocket-bootstrap.conf 644 || true
  ln -sfn /etc/nginx/sites-available/rocket-bootstrap.conf /etc/nginx/sites-enabled/rocket-bootstrap.conf
  rm -f "/etc/nginx/sites-enabled/$WEB_DOMAIN.conf" "/etc/nginx/sites-enabled/$API_DOMAIN.conf"
fi
nginx -t -q && systemctl reload nginx

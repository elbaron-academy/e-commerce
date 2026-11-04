#!/usr/bin/env bash
# One-time (and safe to re-run) setup of the Rocket Market VM. Run as root:
#
#   scp -r deploy hossam@35.226.179.10:/tmp/rocket-setup
#   ssh -t hossam@35.226.179.10 'sudo CERTBOT_EMAIL=you@example.com bash /tmp/rocket-setup/scripts/server-setup.sh'
#
# It installs nginx, Python, Node.js 22 and certbot, creates the folders,
# secrets and systemd services, and gets HTTPS certificates when DNS is ready.
# It never touches other nginx sites on the machine.
set -euo pipefail

DEPLOY_USER="${DEPLOY_USER:-hossam}"
WEB_DOMAIN="${WEB_DOMAIN:-rocket.hossam-ameen.online}"
API_DOMAIN="${API_DOMAIN:-api.rocket.hossam-ameen.online}"
CERTBOT_EMAIL="${CERTBOT_EMAIL:-}"
APP_DIR=/opt/rocket
WEB_DIR=/var/www/html/rocket
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"   # the deploy/ folder

log() { printf '\n\033[1;32m==> %s\033[0m\n' "$*"; }
warn() { printf '\n!! %s\n' "$*"; }

[ "$(id -u)" -eq 0 ] || { echo "Run this script with sudo."; exit 1; }
id "$DEPLOY_USER" >/dev/null 2>&1 || { echo "User $DEPLOY_USER does not exist."; exit 1; }

log "Installing packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq nginx python3 python3-venv python3-pip certbot rsync curl ca-certificates tar gzip >/dev/null
NODE_MAJOR="$(node -v 2>/dev/null | sed -E 's/^v([0-9]+).*/\1/' || echo 0)"
if [ "${NODE_MAJOR:-0}" -lt 20 ]; then
  log "Installing Node.js 22"
  curl -fsSL https://deb.nodesource.com/setup_22.x | bash - >/dev/null
  apt-get install -y -qq nodejs >/dev/null
fi
python3 -c 'import sys; assert sys.version_info >= (3, 10), "Python 3.10+ required"'
echo "python $(python3 -V | cut -d' ' -f2), node $(node -v), nginx $(nginx -v 2>&1 | cut -d/ -f2)"

log "Creating folders"
install -d -o "$DEPLOY_USER" -g www-data -m 755 "$APP_DIR" "$APP_DIR"/{releases,incoming,data,data/cache,media,static,backups} "$WEB_DIR" "$WEB_DIR/releases"
install -d -m 755 /var/www/certbot

log "Writing secrets (only if missing)"
gen() { python3 -c 'import secrets; print(secrets.token_urlsafe(50))'; }
if [ ! -f "$APP_DIR/.env" ]; then
  sed -e "0,/__GENERATED__/s//$(gen)/" -e "0,/__GENERATED__/s//$(gen)/" "$SRC/env/backend.env.example" > "$APP_DIR/.env"
  echo "Created $APP_DIR/.env"
else
  echo "Keeping existing $APP_DIR/.env"
fi
[ -f "$APP_DIR/storefront.env" ] || cp "$SRC/env/storefront.env.example" "$APP_DIR/storefront.env"
chown "$DEPLOY_USER":www-data "$APP_DIR/.env" "$APP_DIR/storefront.env"
chmod 600 "$APP_DIR/.env"
chmod 640 "$APP_DIR/storefront.env"

log "Python virtualenv"
[ -x "$APP_DIR/venv/bin/python" ] || sudo -u "$DEPLOY_USER" python3 -m venv "$APP_DIR/venv"

log "systemd services and nginx sites"
bash "$SRC/scripts/sync-server-config.sh" "$DEPLOY_USER"
systemctl enable rocket-api.service rocket-web.service >/dev/null
systemctl enable --now rocket-jobs.timer rocket-backup.timer >/dev/null

log "Allowing $DEPLOY_USER to restart the Rocket services (for CI/CD)"
SYSTEMCTL="$(command -v systemctl)"
cat > /etc/sudoers.d/rocket-deploy <<SUDO
$DEPLOY_USER ALL=(root) NOPASSWD: $SYSTEMCTL restart rocket-api, $SYSTEMCTL restart rocket-web, $SYSTEMCTL reload nginx, $SYSTEMCTL status rocket-api, $SYSTEMCTL status rocket-web, $SYSTEMCTL daemon-reload, $(command -v tee) /etc/systemd/system/rocket-*
SUDO
chmod 440 /etc/sudoers.d/rocket-deploy
visudo -cf /etc/sudoers.d/rocket-deploy >/dev/null

log "HTTPS certificates"
have_cert() { [ -f "/etc/letsencrypt/live/$1/fullchain.pem" ]; }
if ! { have_cert "$WEB_DOMAIN" && have_cert "$API_DOMAIN"; }; then
  email_args=(--register-unsafely-without-email)
  [ -n "$CERTBOT_EMAIL" ] && email_args=(--email "$CERTBOT_EMAIL")
  for domain in "$WEB_DOMAIN" "$API_DOMAIN"; do
    have_cert "$domain" && continue
    certbot certonly --webroot -w /var/www/certbot -d "$domain" --cert-name "$domain" \
      --non-interactive --agree-tos "${email_args[@]}" --deploy-hook "systemctl reload nginx" \
      || warn "Could not get a certificate for $domain. Check its DNS A record and that ports 80/443 are open, then run this script again. Sites work over HTTP meanwhile."
  done
  bash "$SRC/scripts/sync-server-config.sh" "$DEPLOY_USER"   # switch to the HTTPS sites
fi

if command -v ufw >/dev/null && ufw status | grep -q "Status: active"; then
  ufw allow 'Nginx Full' >/dev/null && echo "ufw: allowed HTTP/HTTPS"
fi

log "Done"
cat <<DONE
Folders:     $APP_DIR (API)  ·  $WEB_DIR (storefront)
Secrets:     $APP_DIR/.env  (edit here, never in git)
Services:    rocket-api, rocket-web, rocket-jobs.timer, rocket-backup.timer
Next step:   push to main (GitHub Actions deploys), or run the "CI/CD" workflow manually.
DONE

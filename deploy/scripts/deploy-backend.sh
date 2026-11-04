#!/usr/bin/env bash
# Runs on the server (as the deploy user), called by GitHub Actions:
#   ssh hossam@host "bash -s -- <release>" < deploy/scripts/deploy-backend.sh
# Expects /opt/rocket/incoming/backend-<release>.tgz (contains backend/ and deploy/).
set -euo pipefail

RELEASE="${1:?usage: deploy-backend.sh <release-id>}"
APP=/opt/rocket
TARBALL="$APP/incoming/backend-$RELEASE.tgz"
DEST="$APP/releases/backend-$RELEASE"
PY="$APP/venv/bin/python"
KEEP=5

[ -f "$TARBALL" ] || { echo "Missing $TARBALL"; exit 1; }
[ -x "$PY" ] || { echo "Run deploy/scripts/server-setup.sh on the server first."; exit 1; }

echo "==> Unpacking $RELEASE"
rm -rf "$DEST" && mkdir -p "$DEST"
tar -xzf "$TARBALL" -C "$DEST"

echo "==> Installing Python packages"
"$PY" -m pip install --quiet --upgrade pip
"$PY" -m pip install --quiet -r "$DEST/backend/requirements.txt"

export DJANGO_SETTINGS_MODULE=config.settings.prod DJANGO_ENV_FILE="$APP/.env"
cd "$DEST/backend"
echo "==> Checks and migrations"
"$PY" manage.py check --deploy --fail-level ERROR
"$PY" manage.py migrate --noinput
"$PY" manage.py collectstatic --noinput -v0
"$PY" manage.py setup_roles -v0
if grep -qi '^SEED_DEMO=true' "$APP/.env"; then
  "$PY" manage.py seed_demo --if-empty
fi

echo "==> systemd service files"
units_changed=0
for unit in "$DEST"/deploy/systemd/*; do
  target="/etc/systemd/system/$(basename "$unit")"
  rendered="$(sed "s/__USER__/$(whoami)/g" "$unit")"
  if ! printf '%s\n' "$rendered" | cmp -s - "$target"; then
    if printf '%s\n' "$rendered" | sudo -n tee "$target" >/dev/null; then
      echo "updated $(basename "$unit")"; units_changed=1
    else
      echo "!! Could not update $target (no sudo rights). Run the Server setup workflow."
    fi
  fi
done
if [ "$units_changed" = 1 ]; then sudo -n systemctl daemon-reload; fi

echo "==> Switching to the new release"
# A real directory left from a manual install is moved aside, not deleted.
for link in backend deploy; do
  if [ -e "$APP/$link" ] && [ ! -L "$APP/$link" ]; then mv "$APP/$link" "$APP/$link.manual-$(date +%s)"; fi
done
ln -sfn "$DEST/backend" "$APP/backend.next" && mv -Tf "$APP/backend.next" "$APP/backend"
ln -sfn "$DEST/deploy" "$APP/deploy.next" && mv -Tf "$APP/deploy.next" "$APP/deploy"
sudo systemctl restart rocket-api

echo "==> Health check"
sleep 2
curl -fsS --retry 15 --retry-delay 2 --retry-connrefused -H "Host: 127.0.0.1" http://127.0.0.1:8000/api/health/ && echo

echo "==> Cleaning up old releases (keeping $KEEP)"
ls -1dt "$APP"/releases/backend-* | tail -n +$((KEEP + 1)) | xargs -r rm -rf
rm -f "$TARBALL"
echo "Backend $RELEASE is live."

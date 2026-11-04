#!/usr/bin/env bash
# Runs on the server (as the deploy user), called by GitHub Actions:
#   ssh hossam@host "bash -s -- <release>" < deploy/scripts/deploy-storefront.sh
# Expects /opt/rocket/incoming/storefront-<release>.tgz (the Nuxt .output folder).
set -euo pipefail

RELEASE="${1:?usage: deploy-storefront.sh <release-id>}"
WEB=/var/www/html/rocket
TARBALL=/opt/rocket/incoming/storefront-$RELEASE.tgz
DEST="$WEB/releases/$RELEASE"
KEEP=5

[ -f "$TARBALL" ] || { echo "Missing $TARBALL"; exit 1; }

echo "==> Unpacking $RELEASE"
rm -rf "$DEST" && mkdir -p "$DEST"
tar -xzf "$TARBALL" -C "$DEST"

echo "==> Settings"
# storefront.env holds no secrets, so it always follows the template in git.
install -m 640 /opt/rocket/deploy/env/storefront.env.example /opt/rocket/storefront.env

echo "==> Switching to the new release"
ln -sfn "$DEST" "$WEB/current.next" && mv -Tf "$WEB/current.next" "$WEB/current"
sudo systemctl restart rocket-web

echo "==> Health check"
healthy=0
for _ in $(seq 1 20); do
  sleep 2
  if curl -fsS -o /dev/null -m 5 http://127.0.0.1:3000/; then healthy=1; echo "storefront OK"; break; fi
done
if [ "$healthy" != 1 ]; then
  echo "!! The storefront did not start. Service log:"
  sudo -n journalctl -u rocket-web -n 30 --no-pager -o cat 2>/dev/null || true
  exit 1
fi

echo "==> Cleaning up old releases (keeping $KEEP)"
ls -1dt "$WEB"/releases/* | tail -n +$((KEEP + 1)) | xargs -r rm -rf
rm -f "$TARBALL"
echo "Storefront $RELEASE is live."

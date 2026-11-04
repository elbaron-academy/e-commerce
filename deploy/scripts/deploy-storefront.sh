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

echo "==> Switching to the new release"
ln -sfn "$DEST" "$WEB/current.next" && mv -Tf "$WEB/current.next" "$WEB/current"
sudo systemctl restart rocket-web

echo "==> Health check"
sleep 2
curl -fsS -o /dev/null --retry 15 --retry-delay 2 --retry-connrefused http://127.0.0.1:3000/ && echo "storefront OK"

echo "==> Cleaning up old releases (keeping $KEEP)"
ls -1dt "$WEB"/releases/* | tail -n +$((KEEP + 1)) | xargs -r rm -rf
rm -f "$TARBALL"
echo "Storefront $RELEASE is live."

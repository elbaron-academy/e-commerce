#!/usr/bin/env bash
# Points backend or storefront back to the previous release and restarts it.
#   ssh hossam@35.226.179.10 'bash /opt/rocket/deploy/scripts/rollback.sh backend'
#   ssh hossam@35.226.179.10 'bash /opt/rocket/deploy/scripts/rollback.sh storefront'
# Note: database migrations are not reversed.
set -euo pipefail

case "${1:-}" in
  backend)
    current="$(readlink -f /opt/rocket/backend)"
    previous="$(ls -1dt /opt/rocket/releases/backend-* | while read -r d; do [ "$d/backend" != "$current" ] && echo "$d" && break; done)"
    [ -n "$previous" ] || { echo "No previous backend release."; exit 1; }
    ln -sfn "$previous/backend" /opt/rocket/backend.next && mv -Tf /opt/rocket/backend.next /opt/rocket/backend
    ln -sfn "$previous/deploy" /opt/rocket/deploy.next && mv -Tf /opt/rocket/deploy.next /opt/rocket/deploy
    sudo systemctl restart rocket-api
    echo "Backend rolled back to $(basename "$previous")" ;;
  storefront)
    current="$(readlink -f /var/www/html/rocket/current)"
    previous="$(ls -1dt /var/www/html/rocket/releases/* | while read -r d; do [ "$d" != "$current" ] && echo "$d" && break; done)"
    [ -n "$previous" ] || { echo "No previous storefront release."; exit 1; }
    ln -sfn "$previous" /var/www/html/rocket/current.next && mv -Tf /var/www/html/rocket/current.next /var/www/html/rocket/current
    sudo systemctl restart rocket-web
    echo "Storefront rolled back to $(basename "$previous")" ;;
  *) echo "usage: rollback.sh backend|storefront"; exit 1 ;;
esac

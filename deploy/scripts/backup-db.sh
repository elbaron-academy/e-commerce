#!/usr/bin/env bash
# Nightly SQLite backup (online, consistent) kept for 14 days. Run by rocket-backup.timer.
set -euo pipefail
DB=/opt/rocket/data/db.sqlite3
OUT=/opt/rocket/backups
[ -f "$DB" ] || exit 0
file="$OUT/db-$(date +%F-%H%M).sqlite3"
/opt/rocket/venv/bin/python - "$DB" "$file" <<'PY'
import sqlite3, sys
src, dst = sqlite3.connect(sys.argv[1]), sqlite3.connect(sys.argv[2])
with dst:
    src.backup(dst)
PY
gzip -f "$file"
find "$OUT" -name 'db-*.sqlite3.gz' -mtime +14 -delete
echo "Backup written: $file.gz"

#!/usr/bin/env bash
# Runs a command and streams its output. Lines starting with "!!" become warning
# annotations; on failure the last 40 lines become an error annotation, so the
# reason shows on the run summary page without opening the log.
#   .github/scripts/run.sh "Deploy backend" bash -c 'ssh rocket ...'
set -uo pipefail
title="$1"
shift
log="$(mktemp)"
"$@" 2>&1 | tee "$log"
status=${PIPESTATUS[0]}
encode() { sed -e 's/%/%25/g' -e 's/\r//g' | awk '{printf "%s%%0A", $0}'; }
grep '^!! ' "$log" | while IFS= read -r line; do echo "::warning title=$title::${line#!! }"; done
if [ "$status" -ne 0 ]; then
  echo "::error title=$title failed::$(tail -n 40 "$log" | encode)"
fi
exit "$status"

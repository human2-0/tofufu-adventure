#!/usr/bin/env bash
set -euo pipefail
touch /var/lib/tofufu-public/stop-request
for attempt in {1..250}; do
  if ! kill -0 "$1" 2>/dev/null; then exit 0; fi
  sleep 0.1
done
echo 'Public authority did not finish its checkpoint.' >&2
exit 1

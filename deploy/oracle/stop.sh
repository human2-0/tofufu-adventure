#!/usr/bin/env bash
set -euo pipefail
# The game saves on its next frame before exiting; systemd kills only on timeout.
touch /var/lib/tofufu/stop-request
for attempt in {1..200}; do
  if ! kill -0 "$1" 2>/dev/null; then exit 0; fi
  sleep 0.1
done
echo 'Timed out waiting for the meadow checkpoint.' >&2
exit 1

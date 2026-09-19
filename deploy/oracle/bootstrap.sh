#!/usr/bin/env bash
set -euo pipefail
if [[ $EUID != 0 || $# != 1 ]]; then
  echo 'Usage: sudo bash deploy/oracle/bootstrap.sh /private/path/server.json' >&2
  exit 1
fi
root=$(cd -- "$(dirname -- "$0")/../.." && pwd)
if ! id tofufu >/dev/null 2>&1; then
  useradd --system --home-dir /var/lib/tofufu --shell /usr/sbin/nologin tofufu
fi
install -d -m 755 /opt/tofufu/releases /usr/local/lib/tofufu
install -d -m 700 -o tofufu -g tofufu /var/lib/tofufu
install -d -m 750 -o root -g tofufu /etc/tofufu
if [[ -e /etc/tofufu/server.json ]]; then
  echo 'Keeping existing server identity and player allowlist.'
else
  install -m 640 -o root -g tofufu "$1" /etc/tofufu/server.json
fi
python3 "$root/deploy/oracle/install_godot.py" /opt/tofufu/godot
install -m 755 "$root/deploy/oracle/stop.sh" /usr/local/lib/tofufu/stop.sh
install -m 755 "$root/deploy/oracle/release.sh" /usr/local/lib/tofufu/release.sh
install -m 644 "$root/deploy/oracle/tofufu.service" /etc/systemd/system/tofufu.service
systemctl daemon-reload
systemctl enable tofufu
echo 'Bootstrap complete. Deploy a release next; no network rules were changed.'

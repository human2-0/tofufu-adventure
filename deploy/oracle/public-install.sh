#!/usr/bin/env bash
set -euo pipefail
if [[ $EUID != 0 || $# != 2 ]]; then
  echo 'Usage: sudo bash deploy/oracle/public-install.sh PACK.pck PRIVATE-SERVER.json' >&2
  exit 1
fi
# The full world needs headroom even after textures are stripped. Do not swap it
# over existing services on an undersized shared VM.
memory_kib=$(awk '/MemTotal:/ {print $2}' /proc/meminfo)
if (( memory_kib < 2097152 )); then
  echo 'Public authority needs at least 2 GiB RAM; this VM is too small.' >&2
  exit 1
fi
root=$(cd -- "$(dirname -- "$0")/../.." && pwd)
if ! id tofufu >/dev/null 2>&1; then
  useradd --system --home-dir /var/lib/tofufu-public --shell /usr/sbin/nologin tofufu
fi
install -d -m 755 /opt/tofufu/public-releases /usr/local/lib/tofufu
install -d -m 700 -o tofufu -g tofufu /var/lib/tofufu-public
install -d -m 750 -o root -g tofufu /etc/tofufu-public
if [[ ! -e /etc/tofufu-public/server.json ]]; then
  install -m 640 -o root -g tofufu "$2" /etc/tofufu-public/server.json
fi
if [[ ! -x /opt/tofufu/godot ]] || [[ $(/opt/tofufu/godot --headless --version) != 4.7.2.* ]]; then
  python3 "$root/deploy/oracle/install_godot.py" /opt/tofufu/godot
fi
digest=$(sha256sum "$1" | cut -d ' ' -f 1)
release="/opt/tofufu/public-releases/$digest"
install -d -m 755 "$release"
install -m 644 "$1" "$release/tofufu.pck"
install -m 755 "$root/deploy/oracle/public-stop.sh" /usr/local/lib/tofufu/public-stop.sh
install -m 644 "$root/deploy/oracle/tofufu-public.service" /etc/systemd/system/tofufu-public.service
systemctl daemon-reload
systemctl stop tofufu-public.service
if [[ -f /var/lib/tofufu-public/adventure_00.json ]]; then
  cp -p /var/lib/tofufu-public/adventure_00.json "/var/lib/tofufu-public/before-$digest.json"
fi
previous=$(readlink /opt/tofufu/public-current || true)
ln -sfn "$release" /opt/tofufu/public-next
mv -Tf /opt/tofufu/public-next /opt/tofufu/public-current
systemctl start tofufu-public.service
invocation=$(systemctl show tofufu-public.service --property=InvocationID --value)
for attempt in {1..60}; do
  if systemctl is-active --quiet tofufu-public.service && \
     journalctl "_SYSTEMD_INVOCATION_ID=$invocation" --no-pager | grep -q ORACLE_READY; then
    systemctl enable tofufu-public.service
    echo 'Public authority ready. Validate Nginx and real TLS clients before exposing it.'
    exit 0
  fi
  if ! systemctl is-active --quiet tofufu-public.service; then break; fi
  sleep 1
done
systemctl stop tofufu-public.service
if [[ -n "$previous" ]]; then
  ln -sfn "$previous" /opt/tofufu/public-next
  mv -Tf /opt/tofufu/public-next /opt/tofufu/public-current
  if [[ -f "/var/lib/tofufu-public/before-$digest.json" ]]; then
    cp -p "/var/lib/tofufu-public/before-$digest.json" /var/lib/tofufu-public/adventure_00.json
  fi
  systemctl start tofufu-public.service
fi
echo 'Candidate failed to become ready; previous release restored when present.' >&2
exit 1

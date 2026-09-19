#!/usr/bin/env bash
set -euo pipefail
if [[ $EUID != 0 || $# != 2 || ! $2 =~ ^[a-f0-9]{40}$ ]]; then
  echo 'Usage: sudo release.sh /path/source.tar.gz COMMIT_SHA' >&2
  exit 1
fi
exec 9>/opt/tofufu/deploy.lock
flock -n 9 || { echo 'Another deployment is active.' >&2; exit 1; }
archive=$(realpath "$1")
release="/opt/tofufu/releases/$2"
if [[ -e $release ]]; then
  echo 'Release already exists. Use a new commit or the documented rollback command.' >&2
  exit 1
fi
install -d -m 755 "$release"
tar --extract --gzip --file "$archive" --directory "$release" --no-same-owner --no-same-permissions
chown -R tofufu:tofufu "$release"
export GODOT_BIN=/opt/tofufu/godot
# Run as the game user, against disposable saves, while the old world stays live.
runuser -u tofufu -- env GODOT_BIN="$GODOT_BIN" python3 "$release/tools/verify.py"
chown -R root:root "$release"
chmod -R a+rX "$release"
previous=$(readlink -f /opt/tofufu/current || true)
if systemctl is-active --quiet tofufu; then
  systemctl stop tofufu
  if [[ -e /var/lib/tofufu/stop-request ]]; then
    echo 'Save-on-stop failed. Aborting release switch.' >&2
    systemctl start tofufu
    exit 1
  fi
fi
backup="/var/lib/tofufu/before-$2.json"
if [[ -f /var/lib/tofufu/adventure_00.json ]]; then
  cp -p /var/lib/tofufu/adventure_00.json "$backup"
fi
ln -s "$release" /opt/tofufu/next
mv -Tf /opt/tofufu/next /opt/tofufu/current
rm -f /var/lib/tofufu/server.log
systemctl start tofufu
for attempt in {1..30}; do
  if systemctl is-active --quiet tofufu && grep -q '^ORACLE_READY' /var/lib/tofufu/server.log 2>/dev/null; then
    echo "Deployed $2"
    exit 0
  fi
  sleep 1
done
systemctl stop tofufu || true
if [[ -n $previous && -d $previous ]]; then
  if [[ -f $backup ]]; then cp -p "$backup" /var/lib/tofufu/adventure_00.json; fi
  ln -s "$previous" /opt/tofufu/rollback
  mv -Tf /opt/tofufu/rollback /opt/tofufu/current
  systemctl start tofufu
fi
echo 'Release failed readiness; previous code/checkpoint restored when available.' >&2
exit 1

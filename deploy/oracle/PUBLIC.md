# Public Multiplayer

The main menu's **Public Multiplayer** entry connects to the explicitly configured
Oracle authority. Four players can be online, with up to 32 persistent test
characters. Each installation asks only for a unique name: 3–20 ASCII letters,
numbers or underscores, starting with a letter. Names are unique regardless of
capitalization. The device saves a random credential automatically; the server
stores its digest. Another device cannot recover a character by entering its name.

Keep a private backup of `public-character.json` in the Godot project user-data
folder. On macOS that folder is
`~/Library/Application Support/Godot/app_userdata/Tofufu-Adventure/`.
Securely copying that file moves a test character to another installation. Do not
run copies simultaneously, share it with another player, or commit it to Git.
There is no email/password recovery or production account ownership verification.

Public hosting is **not live as of 11 October 2026**. Oracle rejected separate
Always Free A1 launches in London AD-1 and AD-2 with `Out of host capacity`,
including a reduced 1 OCPU / 3 GB allocation. AD-3 has a zero A1 memory quota.
The existing shared VM reports only 503 MiB RAM and failed the bounded startup
trial. Its trial files were removed and its original services remain running.
The configured public WSS route has not been installed. Provisioning, Linux
service acceptance, trusted TLS ingress and internet load testing remain pending.

## Authority and persistence

The server resolves movement, combat, rewards, inventories, storage, purchases,
stat spending, shared world time/weather and crop growth. Clients render the
existing game and predict movement against authoritative snapshots. Graphics and
frame rates remain local to each player's machine. The HUD displays round-trip
latency, player count and measured server physics frequency.

Atomic checkpoints retain the party, world and personal exploration every five
seconds, after roster changes and on managed shutdown. A failed save or corrupt
checkpoint stops the authority. There is no offline elapsed-time catch-up after
server downtime. Factory encounters/puzzle trials and duels retain their existing
documented restart semantics in [COOP.md](../../docs/architecture/COOP.md).
Forced termination may lose changes since the last completed save.

## Package and install

Run the architecture/full verifier and independent dedicated acceptance before
packaging. The `Oracle Server` export strips render assets, preserves physics and
uses dedicated-only guards for decoration construction. Desktop client exports
retain their graphics.

```sh
python3 tools/verify.py
python3 tools/verify_dedicated.py
python3 tools/package_public_server.py /tmp/tofufu-public.pck
python3 tools/verify_dedicated.py --server-pack /tmp/tofufu-public.pck
```

Prepare a private configuration outside the repository, once. `server_id` is a
random 64-character lowercase hexadecimal identity. Keep it across deployments.

```json
{"server_id":"REPLACE_WITH_RANDOM_64_HEX_ID","players":[],"public_registration":true}
```

Copy the pack, this deployment folder and the private configuration to an
appropriately sized Linux VM. Provision only a shape marked Always Free-eligible
in the tenancy's home region and within current CPU, memory and combined boot/
block-volume allowance. Check the live console; capacity can be unavailable.
Oracle's [Always Free limits](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm)
and idle-instance reclamation apply.

Install the Linux libraries listed in [README.md](README.md), then run:

```sh
sudo bash deploy/oracle/public-install.sh /tmp/tofufu-public.pck /private/server.json
sudo systemctl status tofufu-public --no-pager
sudo journalctl -u tofufu-public -n 50 --no-pager
```

The installer refuses undersized VMs, verifies the matching official Godot binary,
preserves the existing server identity, and installs the pack under its SHA-256
release directory. It stops and checkpoints the old release, preserves a backup,
switches the release symlink, waits for readiness and rolls back failed startup.
Updates interrupt sessions. It does not change other services or Nginx routes.

The dedicated service uses an unprivileged account, loopback listener, restricted
writable paths, bounded CPU/RAM and restart frequency. Persistent paths are:

| Path | Contents |
| --- | --- |
| `/etc/tofufu-public/server.json` | Authority identity and admission configuration |
| `/var/lib/tofufu-public/characters.json` | Unique names and credential digests |
| `/var/lib/tofufu-public/adventure_00.json` | Shared world and retained characters/maps |
| `/var/lib/tofufu-public/health.json` | Private aggregate health and last save timestamp |
| `/opt/tofufu/public-current` | Active immutable pack release |

## TLS ingress

Expose WSS through a trusted TLS endpoint; keep port 9080 private. The client
endpoint belongs in `networking/oracle/public_profile.gd`. The existing Oracle
HTTPS endpoint is `wss://79.72.79.130/tofufu-adventure/play`; it must have a
validated proxy path to the ready game VM before internet play is available.
For local acceptance use `TOFUFU_PUBLIC_ENDPOINT=ws://127.0.0.1:PORT`.

`nginx-public-limits.conf` belongs in the Nginx `http` context once.
`nginx-public.conf` belongs in the existing HTTPS server. Validate `nginx -t`
before reloading. Its default upstream is loopback: for a separate game VM use
a verified encrypted private connection to that listener. Never expose the
loopback testing URL publicly or disable client certificate validation.
See [Nginx WebSocket proxying](https://nginx.org/en/docs/http/websocket.html).

Transport limits cap sockets, handshakes, bytes, messages, queued work and stalled
connections. Server intents validate membership, sequences, reach, prerequisites
and server-owned resources. Nginx allows four connections per IP and rate-limits
handshakes. The testing name registry is capped; an administrator must manage
exhausted test identities. These are bounded playtest controls, not a guarantee
against internet denial-of-service attacks.

## Recovery

`systemctl stop/restart tofufu-public` requests a final checkpoint. On failure,
inspect the journal and health timestamp before restarting; never delete a corrupt
save to make startup appear healthy. Keep encrypted backups of the authority
configuration, character registry and matching checkpoint together, outside the
VM. Restore all three while the service is stopped. Same-VM pre-release backups
do not survive volume loss. Keep the client build compatible with the deployed
`PlaytestRoom.GAME_VERSION`.

Cloud provisioning, TLS and four-player load are separate acceptance steps from
local tests. No automated public deployment is enabled by adding these files.

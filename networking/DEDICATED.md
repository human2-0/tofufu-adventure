# Dedicated multiplayer, without Oracle

The dedicated server runs the meadow and owns its saves. Up to four players can join, leave and reconnect using their own connection files. It keeps simulating with no players connected. Holepunch is not started in this mode.

## Try it on this computer

Run these commands from the project root. Godot is discovered automatically on macOS; otherwise set `GODOT_BIN` to its executable path.

Create four private player profiles **once**:

```sh
python3 tools/local_multiplayer.py init
```

Start the server in one terminal:

```sh
python3 tools/local_multiplayer.py server
```

Open players in separate terminals:

```sh
python3 tools/local_multiplayer.py client 1
python3 tools/local_multiplayer.py client 2
```

In each window, choose **Connect to server**, then **Join meadow**. Players 3 and 4 work the same way. Each window controls its own character; click a window to focus it. Reuse the same player number to recover that character. One profile cannot connect twice at the same time.

Ctrl-C in the server terminal requests a final save before shutdown. Alternatively:

```sh
python3 tools/local_multiplayer.py stop
```

Restart with the same `server` command to resume. After a restart, clients reconnect from the lobby. The server saves every 30 seconds and on managed shutdown; force-killing it can lose changes since the last save. It runs only while the computer is awake and the process is running.

Profiles and world saves live in `~/.tofufu-local`, outside the repository. Keep this directory private and back it up; deleting or regenerating profiles changes character identities. `init` refuses to overwrite an existing directory. Use `--directory /absolute/path` before the subcommand for a separate test world; use it consistently for server, client and stop. Use `init --port 9081` if port 9080 is occupied.

## Use the normal game menu

Open **Co-op mode**, select **Dedicated server · Local / Oracle**, and choose **Choose player connection file…**. Select your `player-N.json`, then connect and join. The selection applies to this game session. The local launcher selects the matching file automatically. **Friends · Holepunch** remains available as a separate mode; switching closes the old connection before using the new one. Solo startup opens no connection.

A server owner can supply a player file for a remote WSS endpoint later. The file contains a bearer token: share each file only with its intended player. Never commit player files to Git. Public connections require TLS; the server itself listens only on loopback. This local setup does not expose a LAN or public port.

## Verification

```sh
python3 tools/verify.py
python3 tools/verify_dedicated.py
```

The first includes real local WebSocket admission, invalid/duplicate credentials, malformed packets, four-player capacity, gameplay replication, disconnect and persistence checks. The second starts a dedicated server and two independent Godot launcher processes, checks movement and clean departure, then restarts the server and both clients and checks their persisted identities and collision-safe placement near their saved positions. It uses temporary profiles/worlds and reports the log directory.

## Later: Oracle ARM

No VM is needed for these tests. The same server scene and WebSocket transport can be deployed when ARM capacity becomes available. Cloud provisioning and deployment remain pending; see [the deployment guide](../deploy/oracle/README.md). The main-branch workflow stays opt-in through `ORACLE_DEPLOY_ENABLED=true` and requires a configured host and SSH secrets.

Runtime overrides are `TOFUFU_SERVER_CONFIG`, `TOFUFU_CLIENT_CONFIG`, `TOFUFU_SERVER_PORT` (1–65535), and `TOFUFU_STATE_DIR`. They contain file paths and a port, not tokens. Without overrides, the existing cloud defaults remain `/etc/tofufu/server.json`, loopback port 9080 and `/var/lib/tofufu`.

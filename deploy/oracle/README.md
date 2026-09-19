# Oracle always-on meadow

This is an optional **dedicated game server**, alongside the existing Holepunch approach. It keeps simulating and saving when everybody disconnects. Four people can join; the server does not occupy a player slot. Offline play and the default Holepunch launcher remain available.

## Your account: inspected 15 September 2026

Safari shows a running Always Free `VM.Standard.E2.1.Micro` in London:

- IP: `79.72.79.130`; SSH user: `opc`.
- OS: Oracle Linux 9; memory: 1 GB; AMD/x86-64.
- Network: `thoughts_blog` — inspect existing workloads before changing its services or ports.
- The console reports an A1 allowance of **2 OCPUs / 12 GB RAM**. A separate ARM VM within that allowance would be a better game-server candidate, subject to region capacity and your remaining quota.

No Oracle resource, firewall rule, SSH access, GitHub secret or live service has been changed by this implementation. Browser sign-in does not provide the VM's SSH private key. Local tests cover the new code; Oracle provisioning, Linux deployment, TLS and cross-network performance still need acceptance testing.

Oracle may reclaim idle Always Free instances. There is no availability guarantee here. Confirm the current Always Free label and total allocations in your tenancy before creating resources; do not rely on older 4-CPU/24-GB tutorials. See [Oracle's current limits and reclamation policy](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm).

## 1. Inspect the VM

On your Mac, replace the key path with the private key downloaded when creating this instance:

```bash
chmod 600 /absolute/path/to/oracle-private.key
ssh -i /absolute/path/to/oracle-private.key opc@79.72.79.130
```

Check the SSH fingerprint against a trusted console/previously verified connection before accepting it. On the VM:

```bash
uname -m
free -h
df -h /
sudo ss -lntup
systemctl --type=service --state=running
```

The game and validation processes need spare memory. This 1-GB VM is not yet load-tested; validation deliberately leaves the old world running and can need substantially more memory than the server alone. Use a separate larger Always Free VM if this instance already serves your blog or runs out of memory. Substitute that VM's IP/user in the remaining commands.

## 2. Prepare credentials and the source release

From this repository on the Mac, create four individual player files outside the repository. This first setup uses an encrypted SSH tunnel, so it needs neither a domain nor new public game ports:

```bash
python3 deploy/oracle/create_credentials.py "$HOME/tofufu-oracle-private" \
  --endpoint ws://127.0.0.1:9080 --players 4
python3 tools/verify.py
```

Do not regenerate these files on each deployment: each token identifies a saved character. Keep each player's file private. The server gets only `server.json`, containing token hashes; no raw player tokens. Never commit any of these files.

Commit the intended game changes to main, including new source/assets and this deployment folder, then package the exact commit. Review the existing working-tree changes before committing; this task does not commit unrelated work automatically.

```bash
git status --short
# Commit your reviewed changes using your normal git workflow first.
git rev-parse HEAD
git archive --format=tar.gz --output=/tmp/tofufu-source.tar.gz HEAD
scp -i /absolute/path/to/oracle-private.key /tmp/tofufu-source.tar.gz opc@79.72.79.130:/tmp/
scp -i /absolute/path/to/oracle-private.key "$HOME/tofufu-oracle-private/server.json" opc@79.72.79.130:~/tofufu-server.json
```

## 3. Install the persistent service

On the Oracle Linux VM:

```bash
sudo dnf install -y python3 tar gzip unzip util-linux libX11 libXcursor libXinerama libXrandr libXi mesa-libGL alsa-lib fontconfig
mkdir -p ~/tofufu-setup
tar -xzf /tmp/tofufu-source.tar.gz -C ~/tofufu-setup
cd ~/tofufu-setup
sudo bash deploy/oracle/bootstrap.sh "$HOME/tofufu-server.json"
```

The installer downloads **Godot 4.7.2**, matching the local project, from the official Godot release and verifies its published SHA-512 checksum. It selects x86-64 or ARM64 from the VM. If that exact upstream binary is unavailable, installation fails; do not silently substitute an older engine because this project uses typed/abstract GDScript features.

For Ubuntu 24.04, replace the dependency command with:

```bash
sudo apt-get update
sudo apt-get install -y python3 tar gzip unzip util-linux libx11-6 libxcursor1 libxinerama1 libxrandr2 libxi6 libgl1 libasound2t64 fontconfig
```

Then deploy, replacing `YOUR_40_CHARACTER_COMMIT_SHA` with the `git rev-parse HEAD` value from step 2:

```bash
sudo /usr/local/lib/tofufu/release.sh /tmp/tofufu-source.tar.gz YOUR_40_CHARACTER_COMMIT_SHA
sudo systemctl status tofufu --no-pager
sudo journalctl -u tofufu -n 80 --no-pager
```

The release script validates the candidate with the full headless test suite before stopping the running world. It asks the game to save, backs up its checkpoint, switches the source directory, restarts and waits up to 30 seconds for `ORACLE_READY`. Failed startup restores the old source and checkpoint when available. Initial deployment has no old release to restore. A failed candidate remains on disk for diagnosis; retry using a new commit. Updates interrupt connected sessions.

Persistence is in `/var/lib/tofufu/adventure_00.json`, outside release directories. A systemd restart requests a final checkpoint; forced termination/crashes can lose up to 30 seconds since the last autosave. An unreadable/corrupt checkpoint stops startup instead of replacing it with a new world.

## 4. Play through an SSH tunnel

On the Mac, keep this connection open:

```bash
ssh -i /absolute/path/to/oracle-private.key -N -L 9080:127.0.0.1:9080 opc@79.72.79.130
```

Install your own player file as `oracle-client.json` in Godot's project user-data folder. On this Mac:

```bash
mkdir -p "$HOME/Library/Application Support/Godot/app_userdata/Tofufu-Adventure"
cp "$HOME/tofufu-oracle-private/player-1.json" \
  "$HOME/Library/Application Support/Godot/app_userdata/Tofufu-Adventure/oracle-client.json"
chmod 600 "$HOME/Library/Application Support/Godot/app_userdata/Tofufu-Adventure/oracle-client.json"
/Applications/Godot.app/Contents/MacOS/Godot --path . res://game/app/oracle_launch.tscn
```

Choose **Co-op → Connect to Oracle → Join meadow**. Another person needs their own player credential and a connection path. Do not share your VM administration key with testers; use WSS below for the usual friend-testing setup. The existing/default project launcher still uses Holepunch. For a distributable Oracle build, duplicate the project/export configuration and select `oracle_launch.tscn` as its main scene; never embed private credentials in exports.

This server starts after the pod introduction. It keeps its world while empty and retains up to 32 character identities, with four online at a time. Reconnect manually after an update and use the same player file to recover progress. Clients must use a compatible game build; GitHub deployment does not update anybody's desktop game automatically. Holepunch character identities do not automatically migrate.

## 5. Public TLS connection for friends

Use a DNS hostname you control, such as `meadow.your-domain.com`, pointing to the VM. Install/configure a TLS reverse proxy. The included [Caddy example](Caddyfile.example) forwards WebSocket traffic to the private listener at `127.0.0.1:9080`. If a blog already occupies ports 80/443, add the game hostname to the existing proxy; do not replace its configuration or start a competing proxy.

For a new dedicated VM, use [Caddy's official installation instructions](https://caddyserver.com/docs/install), add the hostname block, then:

```bash
sudo caddy validate --config /etc/caddy/Caddyfile
sudo systemctl reload caddy
```

Allow TCP 80 and 443 in both the OCI subnet security list/NSG and the OS firewall. On Oracle Linux with active firewalld:

```bash
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

Keep port **9080 private**; it binds only to loopback. Retain SSH access for administration/deployments. OCI security rules are separate from the Linux firewall. Caddy needs working DNS and reachable ports to issue certificates; [its automatic HTTPS documentation](https://caddyserver.com/docs/automatic-https) explains the requirements.

In each existing player JSON, change only `endpoint` to `wss://meadow.your-domain.com`. Keep `token` unchanged. Give each tester their own file privately. The game checks the server's TLS certificate normally. No port forwarding or Holepunch runtime is needed on the testers' computers.

## 6. Deploy automatically on every push to main

The included [GitHub Actions workflow](../../.github/workflows/oracle-deploy.yml) is disabled until configured. It packages the triggering commit, uploads it over SSH, then invokes the same validated release switch. Deployments are serialized and do not cancel one another during a save/restart. A queued older deployment can finish before the latest one; this is intentional.

Create an **oracle** GitHub environment restricted to main. Configure the following repository/environment secrets:

| Secret | Value |
| --- | --- |
| `ORACLE_HOST` | `79.72.79.130` or your dedicated VM hostname/IP |
| `ORACLE_USER` | `opc` (or your deployment account) |
| `ORACLE_SSH_KEY` | Private key of an authorized deployment account |
| `ORACLE_KNOWN_HOSTS` | Verified SSH known-hosts entry for that exact host |

The deployment account needs passwordless sudo for the installed release script. That script installs and runs repository code and extracts source as root: **treat deployment access as privileged administration**, protect main/environment access, and use a dedicated deployment key rather than a personal key used on other machines. Do not bypass host-key verification. Existing `opc` administration often already has sudo; verify it before enabling CI.

Using GitHub CLI after its normal sign-in, from the repository:

```bash
gh secret set ORACLE_HOST --env oracle --body '79.72.79.130'
gh secret set ORACLE_USER --env oracle --body 'opc'
gh secret set ORACLE_SSH_KEY --env oracle < /absolute/path/to/dedicated-deploy-private-key
# Prepare a file containing only the independently verified host entry.
gh secret set ORACLE_KNOWN_HOSTS --env oracle < /absolute/path/to/oracle-known-hosts
gh variable set ORACLE_DEPLOY_ENABLED --body true
git push origin main
gh run list --workflow oracle-deploy.yml
```

Use **Run workflow** (main branch) to trigger an initial deployment without a new commit. Do not set a required approval on the environment if you want fully automatic updates. The GitHub-hosted runner must be able to reach SSH on the VM; if inbound SSH is restricted to your home IP, use an appropriately controlled deployment runner/network instead of assuming GitHub can connect.

No Oracle API key is needed for this flow. The VM runs under systemd independently of GitHub. Bootstrap scripts/service units and the Godot runtime are intentionally installed separately; review and rerun bootstrap to change those. A normal push updates the game source only.

## Operations and rollback

```bash
sudo journalctl -u tofufu -f
sudo systemctl restart tofufu
sudo systemctl stop tofufu
sudo systemctl start tofufu
```

For a manual rollback, stop first, keep a copy of the current checkpoint, choose an existing release and its matching `before-NEW_SHA.json` backup, then switch both. Backups are owned by the game account:

```bash
sudo systemctl stop tofufu
sudo cp -p /var/lib/tofufu/adventure_00.json /var/lib/tofufu/manual-rollback-backup.json
sudo cp -p /var/lib/tofufu/before-NEW_SHA.json /var/lib/tofufu/adventure_00.json
sudo ln -s /opt/tofufu/releases/OLD_SHA /opt/tofufu/manual-next
sudo mv -Tf /opt/tofufu/manual-next /opt/tofufu/current
sudo systemctl start tofufu
```

Rollback of a checkpoint loses progress made after it. Retain encrypted/off-VM copies of server identity, the allowlist and checkpoints; same-VM backups do not survive VM/volume loss. Old releases and backup files are retained, so review disk usage periodically. Set `ORACLE_DEPLOY_ENABLED=false` to pause deployments without stopping the game.

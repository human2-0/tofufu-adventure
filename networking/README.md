# Holepunch co-op

Open **Co-op mode → Discover testers**, choose **New shared adventure** or a saved adventure, then **Open a meadow**. Other testers select **Join meadow**; the host selects **Explore together**. Up to four players share the pod escape, exploration, combat, harvesting, loot and progression. Friends can also join a game already in progress.

The host owns the save. Manual save, one-minute autosave, return and quit persist the world and characters. Continue opens the lobby with the shared adventure selected. Rejoining from the same user profile restores your character. The session ends when its host leaves.

## Development setup

From the project root:

```sh
npm ci --prefix networking/sidecar
python3 tools/verify.py
npm test --prefix networking/sidecar
python3 tools/verify_coop.py
```

Node.js 22+ is required. Godot checks `TOFUFU_NODE_BIN`, a bundled Node, common install locations (including nvm) and PATH. Set `TOFUFU_NODE_BIN` to an absolute executable if automatic discovery fails. The runtime starts only after **Discover testers**; leaving co-op closes it. Missing dependencies show an in-menu error, while solo remains available.

The public topic discovers reachable compatible testers who enable discovery, without accounts or invitations. Lobby discovery is bounded to 32 peers; each world accepts three guests and retains at most 32 saved character identities. Display names are labels; encrypted peer keys identify characters. `peer-identity.key` lives in Godot's user directory and survives application restarts. Keep this profile to retain your identity, and do not run copies of the same identity simultaneously.

Connections are direct-only. Restrictive networks can prevent discovery or connection; no gameplay relay is silently enabled. Host menus leave the simulation running and neutralize local input. Host authority decides movement, damage and progress.

## Desktop export runtime

After installing dependencies on the target OS/architecture, stage its Node and sidecar beside the exported game:

```sh
python3 tools/package_coop.py /path/to/export-directory --node /absolute/path/to/node
```

For macOS `.app` exports, the destination is `Game.app/Contents/MacOS`. The helper requires a fresh runtime destination, copies installed dependencies and records the Node platform/architecture in `coop-runtime.json`. Use a matching game export and apply platform signing after staging. This does not cross-compile native dependencies, sign an app or implement mobile runtime integration.

## Verification and code ownership

`tools/verify_coop.py` launches separate Godot clients with real sidecars and an isolated local DHT. `python3 tools/verify_coop.py --public-network` instead uses the public DHT with a private random test topic, separate from tester discovery. Both paths have passed on this macOS host, including combat, healing, reconnect identity, host checkpoints and process cleanup. Separate physical networks, other operating systems, signed exports and controller hardware still require testing.

`sidecar/src/framing.cjs` owns bounded framing/backpressure; `swarm.cjs` owns encrypted discovery/connections; `runtime.cjs` owns persisted identity and isolated test configuration; `index.cjs` owns authenticated IPC. `godot/holepunch_transport.gd` supervises the child and emits identity-bound transport events. `godot/session_transport.gd` defines the replaceable backend contract; the launch scene selects its implementation, and `game/app/session_connection.gd` wires connection lifecycle to the room. A future centralized adapter can implement the same contract; no centralized backend is currently supplied. Session schemas and admission live in `game/session/`; gameplay composition lives in `game/app/coop_*.gd`. See [the co-op architecture](../docs/architecture/COOP.md) for protocol and persistence decisions.

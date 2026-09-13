# Tofufu Adventure — project instructions

## Start small
- This is a Godot 4.7 / typed GDScript 2.5D co-op game. Run from this project root.
- Read `docs/AGENT_MAP.md`, then only the relevant feature files and scoped `AGENTS.md` files before editing. Explicitly read scopes when starting at the root; do not assume child instructions were loaded.
- Search with `rg` in the mapped feature first. Skip `.godot/`, binary art, imports, and unrelated docs. Do not dump the repository into context.
- Read `docs/architecture/OVERVIEW.md` only for boundary changes; read `docs/architecture/COOP.md` for networking/session work.

## Invariants
- Preserve the example's 3D X/Z ground plane, Y elevation, billboard Fufu, mouse facing, walk/jump/dash, and obstacle collisions unless the task changes them.
- Compose small objects with one responsibility. Use typed commands, signals, exported dependencies, and Resources for configuration. Keep mutable actor state per instance.
- `game/app/` wires features. Movement rules do not read Input, scenes, UI, files, or networking. Views never decide gameplay outcomes.
- Prefer composition over inheritance; inherit only for a real substitution (e.g. command sources). No global event bus, service locator, catch-all Manager, or speculative framework.
- Aim for scripts under 200 lines and functions under 40. Split by responsibility when growing; these are review triggers, not reasons to fragment coherent code.
- Offline play stays functional. Future co-op uses a player as authority and Holepunch behind a transport boundary. No central game service or automatic gameplay relay. Never claim universal NAT connectivity or deterministic cross-machine Godot physics.

## Done
- Run `python3 tools/check_architecture.py` for source/layout changes.
- For GDScript, scene, or project changes run `python3 tools/verify.py` (Godot import, rule tests, scene smoke test). Set `GODOT_BIN` if discovery fails.
- Visually check control/art/camera changes in Godot; report when only headless checks were possible.
- Update the map when moving files; update the relevant architecture decision when changing a boundary. Record implemented vs planned honestly.
- Report changes, verification, and remaining limitations concisely. Do not add session diaries or repeat these rules in child files.

# Tofufu Adventure

A Godot 4.7 co-op game prototype, playable solo or as a host with up to three friends through Holepunch, beginning in Fufufarm: a pastel countryside valley with rolling terrain, soybean fields, a hilltop seed bank and a small village across a winding irrigation stream. Escape the nursery pod, harvest soybeans, explore and fight roaming slimes. A three-minute day/night cycle brings warm lanterns and fireflies after dark. Uses Jolt physics and the Mobile renderer.

## Get the project from GitHub

This repository is private. The owner must invite your GitHub account as a collaborator before you can clone or download it.

With GitHub CLI installed and signed in:

```sh
gh repo clone human2-0/tofufu-adventure
cd tofufu-adventure
npm ci --prefix networking/sidecar
```

Install Godot 4.7.2 and Node.js 22+ for co-op. Import `project.godot` in Godot and press F5. Offline play does not need Node.js. Godot's import cache and installed Node dependencies are generated locally and are not committed.

To get later updates, close the running game, then run:

```sh
git pull --ff-only
npm ci --prefix networking/sidecar
```

Restart the game on both computers after updating. Choose **Co-op mode → Discover testers**. One player chooses **Open a meadow → Start exploring**; the other chooses **Join meadow**. The host can begin alone and friends can join later.

GitHub Actions can run the verification scripts and Godot's headless exports. No CI/CD workflow or automatic in-game updater is configured yet. Desktop co-op exports must also bundle the matching Node runtime and sidecar; see `tools/package_coop.py` and the co-op setup guide.

## Run

Open `project.godot` in Godot 4.7.2 (the locally verified version), then press F6 on `game/app/main.tscn` or F5 for the project. 

| Control | Action |
| --- | --- |
| WASD / arrows | Walk |
| Mouse | Face / aim |
| Left mouse | Release for a knife slash; hold to charge. Punches when fists are selected. |
| Right mouse | Hold knife guard toward the attacker (front 110°); successful blocks spark |
| F | Punch with either equipment slot |
| 1 / 2 | Select knife / fists |
| Q / E | Drop knife / recover nearby knife |
| Space | Tap and release to jump; hold then release for double height |
| Shift | Dash; evade slime attacks while dashing |
| N | Advance the day/night cycle by six hours |
| R | Return to the starting clearing with fresh health |
| Tab | Toggle the controls guide |
| F3 | Toggle the active sword hitbox overlay |

Controller and mobile touch controls are also available. Left stick/D-pad steers; right stick aims; south jumps, east dashes, west charges the knife, and right shoulder guards. See [platform setup](docs/PLATFORMS.md) for the full controls, desktop/mobile export presets, and Switch/PlayStation prerequisites.

The camera holds a 45° downward view. Walking uses eight facing directions; mouse aim controls idle facing and attacks. The original high-resolution diagonal PNG is used alongside the existing cardinal sprites. Dedicated idle sprites cover all eight stationary directions. The smaller sword rests upright beside Fufu and sweeps through a forward slash; hitboxes follow the visible steel blade. Charging widens the slash and increases damage without making the blade larger.

Dropped soybeans fall and settle. Step within 3.5 units to attract them: they accelerate toward Fufu, keep following as you move, and heal up to 20 HP each on contact. Solid scenery blocks the pull. Slimes show `!` before attacking; face them and guard, move away, dodge, or interrupt them with a melee hit. Defeat returns Fufu safely to the starting clearing. Plants, crates and breakable boulders regrow after 28 seconds; slimes return after 22 seconds. Original trees and obstacle stones remain solid scenery.

Discover the Soybean Nursery, Seed Bank, Fufufarm Village and Mayor Mame. Follow curved dirt lanes up the storage hill and across the plank bridge, or wade through the shallow stream. The first terrain uses repeatable procedural seed 1847 with authored clearings and building foundations. The HUD tracks discoveries, harvests and defeated slimes for the current session.

The item shop, weapon shop, seed storage building and mayor are exterior concept placeholders. Interiors, trading, seed deposits and mayor quests are not implemented. The nursery pod escape and western harvest bed are playable. All new scenery is original procedural geometry; no external art package is required.

Three marked slime grounds lie north, south and west of the village, each with three respawning slimes. Each defeat awards 25 EXP; the HUD tracks the total for the current adventure. Character EXP, skill practice and progression are saved with the adventure. Slimes return to their spawn when led too far and cannot pursue or attack into the village. The village practice yard, south of the well, has three straw dummies for knife and fist practice. They show damage, reset after depletion or inactivity, and award no EXP or loot.

No JavaScript runtime, server, or network account is needed for the current offline example.

```sh
python3 tools/check_architecture.py
python3 tools/verify.py
```

The verifier finds `godot`, `godot4`, or the standard macOS Godot app. Override with `GODOT_BIN=/path/to/godot python3 tools/verify.py`. Python 3.9+; no Python packages required. Runtime logs go to a temporary directory printed on completion.

## Development entry points

- [AGENTS.md](AGENTS.md): compact Codex working rules.
- [Agent map](docs/AGENT_MAP.md): directory tree, ownership, and task routing.
- [Architecture](docs/architecture/OVERVIEW.md): implemented boundaries and expansion rules.
- [Co-op design](docs/architecture/COOP.md): Holepunch transport, host authority, protocol, and implementation milestones.
- [Validation](tests/README.md): automated coverage and manual gameplay checklist.

Offline play, co-op, remote input, snapshots, host-owned persistence and the Holepunch runtime bridge are implemented. See the co-op design for verification coverage and remaining limitations.

For public tester discovery, shared adventures and desktop runtime setup, see [Co-op setup](networking/README.md).

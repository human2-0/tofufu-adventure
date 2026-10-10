# Celestial Fufu armory

Built-in image generation produced these transparent PNG atlases, four matching
armor icons in `assets/equipment/celestial/`, and three weapon icons in
`assets/weapons/celestial/`. The design retains Fufu's cream bean body
and sprout, with an ivory winged laurel helm, cyan diamonds, gold Greek trim,
winged boots and a lavender cape. Originals remain at the source paths recorded
in `generation-prompts.json`; final PNGs are copied intact, without raster edits.

`sprite-layout.json` records individual AtlasTexture regions, foot baselines,
head-scale calibration and anatomical wrist points. It contains 248 painted
frames, with real views for E, SE, S, SW, W, NW, N and NE; there is no mirrored
direction fallback. Godot selects regions without changing source pixels.

| Action | Frames per direction | Source layout |
| --- | ---: | --- |
| Idle | 1 | `idle.png`: 4 columns / 2 rows, S/SW/W/NW then N/NE/E/SE |
| Walk / run | 4 | Two 4 by 4 atlases; rows S/SW/W/NW or N/NE/E/SE |
| Jump charge | 4 | Same front/back layout |
| Dash / super dash | 4 | Same front/back layout; shared movement effects |
| Jump / landing | 10 | Four 5 by 4 atlases; two consecutive rows per direction |
| Windup, cut, thrust/punch, guard | 1 each | Combat front/back; columns are the four poses |
| Aim, reload, hurt, riding | 1 each | Utility front/back; columns are the four poses |

Walking speed changes the existing animation cadence for running. Jump phases
follow the existing takeoff, ascent, apex, descent and landing timers. Combat
body poses accompany the continuous 3D weapon animation and existing combo,
charged strike, airborne attack and staff spin rules. Idle breathing, run
lowering, reload motion and dash ghosts remain procedural presentation.

`CelestialFufuArt` owns per-actor art state in `game/player/`. App composition
injects combat, damage and mounted pose context through `ActorCelestialPose`.
`CelestialWeaponModel` constructs three solid weapons beside their combat
scenes, so weapon angles, swings, first-person poses and world drops have real
depth. The Soy Raygun uses the existing gun cadence, magazine, ricochet,
reflection and damage rules with a starlight projectile view.

Nimbus presents the seven celestial items first in the Cloud Realm shop. The
four armor slots must all contain the celestial pieces to activate this outfit;
the level-five requirement applies. The complete set grants fifty-percent
protection, twenty-five-percent damage and attack-speed bonuses, and ten-percent
more chance on rolled item drops. A faint gold halo and eight drifting motes
mark the divine outfit. Items support equipment transfers, drops, saved inventories and co-op
snapshots. Partial pieces retain the normal per-piece armor rule.

Validation entries: `tests/test_celestial.gd`, `tests/preview_celestial.gd`
(`-- --weapons` for held-weapon contact sheets) and
`tests/preview_celestial_game.gd` for the actual shop and first-person rig.

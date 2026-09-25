# Validation

Run `python3 tools/verify.py` from the root. It runs the structural check, a Godot editor import, movement and combat rule tests, the original headless scene test, and sandbox integration tests. No third-party test framework is required.

Rule coverage: movement bounds, friction, falling gravity, coyote time, jump buffering, cooldown/re-entry, dash end and isolated per-player state. Scene coverage: actual world loading, floor collision, injected command source movement/jump/dash, cooldown HUD, camera target and zero-duration cooldown display.

Manual visual check in Godot after art/control/camera changes:

- Walk with WASD/arrows; aim into all four quadrants. Side art faces left unflipped and right flipped.
- Jump onto stones/platforms, walk off edges, and dash into obstacles. Collider should stay stable during sprite squash/stretch.
- Check idle/walk apparent size, camera follow, shadows, dash trails and ready/recharging HUD at 1280x720.
- Dash while jumping; vertical motion pauses on active dash ticks as in the prototype.

Sandbox coverage: light/heavy attack release and cooldown, per-instance health, healing caps, super-jump apex, blade width/height/tip bounds in eight directions, solid-wall occlusion, real crop destruction and healing drops, plant regrowth, bridge crossing, riverbed/wading, walking up the seed-bank hill, shop wall collision, slime telegraph/damage/respawn, and player recovery after defeat.

Additional visual checks:

- Hold the left mouse button until the sword and meter turn gold, release toward a nearby target, and check the 2D sword slash, hit feedback and knockback.
- Tap/release Space and compare with holding then releasing Space; the projected shadow marks the landing position.
- Harvest soy, collect beans, and watch HP and counters. Hit crates and the new faceted breakable boulders.
- Use N to compare daylight and night; inspect river flow, wind, lanterns and fireflies. Cross the village bridge and jump out of shallow water.
- Discover all four places, toggle the guide with Tab, and return with R.

Optional rendered QA (requires a display): `godot --path . --script res://tests/preview_sandbox.gd`. It saves `/tmp/tofufu-grove.png`, `/tmp/tofufu-river.png`, `/tmp/tofufu-night.png`, `/tmp/tofufu-charge.png`, and `/tmp/tofufu-strike.png` from Godot's viewport, then exits.

Sword coverage additionally checks real collider contact just inside/outside the tip, lateral/vertical/rear misses, one hit per attack, rotational sweeps across both sides of the forward arc, harmless wind-up/recovery, steel clearance outside the player body, sweeps during fast motion, eight stationary poses, diagonal sprite selection, attack-facing priority, and constant 45° camera tilt during jumps. Run `godot --path . --script res://tests/preview_sword.gd` for eight-direction and active-hitbox screenshots in `/tmp/tofufu-eight-directions.png` and `/tmp/tofufu-sword-hitboxes.png`. Press F3 in the game to inspect active sword bounds.

Headless tests cannot validate visual quality or real internet/NAT connectivity. Real Holepunch integration is checked separately below.

Input coverage: synthesized gamepad events check analog travel, deadzones, D-pad, independent aim, retained aim, dash direction, held/edge actions and charge release. Touch surface composition, three-finger movement/jump/charge and release cleanup are also checked. Run `godot --path . --script res://tests/preview_controls.gd` for desktop, touch, wide-phone and tablet viewport images in `/tmp/tofufu-controls-*.png`.

Physical-device checks still required: controller connect/disconnect, mouse/controller switching, simultaneous touch walk/jump/charge, cutouts, both landscape rotations, app background/foreground, target frame rate, signing and install/launch for each export target.

Jump coverage checks grounded charging, proportional release, roughly doubled apex, no midair boost, dash/ledge cancellation, per-actor charge, all ten animation phases and ground-contact landing. Run `godot --path . --script res://tests/preview_jump.gd --fixed-fps 60` for real physics/render snapshots at `/tmp/tofufu-jump-*.png`. The supplied jump art is front-facing only.

Equipment coverage: real front/rear incoming damage, guard cone, charge cancellation, committed slash restrictions, knife drop/recovery range, punch cooldown, punches in both slots, height and wall misses. RMB press/release is synthesized through the input map. `godot --path . --script res://tests/preview_equipment.gd` renders guard, block sparks, dropped knife and punches to `/tmp/tofufu-{guard,block,drop,punch}.png`.

Opening quest coverage: early/wrong/held directional input, isolated quest state, four alternating timed pushes, short/overheld charge retries, authored drop and landing, seam release, restored world/camera/movement, and combat suppression while confined. `test_pod_escape.gd` runs in the main verifier. Other sandbox tests explicitly set `play_opening = false` before entering the tree.

Run `godot --path . --script res://tests/preview_pod.gd` to render hanging, stem, charge, landed, escape and world milestones to `/tmp/tofufu-pod-*.png`. For manual play, launch normally: tap the indicated left/right movement direction as the marker enters gold, then hold/release Space (controller south / touch Jump) in gold to snap and split. Check retry feedback, shell opening, world reveal and walking away. Physical controller/touch playtesting remains separate from scripted desktop rendering.

Fufufarm terrain QA: `godot --path . --script res://tests/preview_fufufarm.gd` renders `/tmp/fufufarm-{overview,village,seed-bank,nursery,fields,mayor,night}.png`. The first map uses repeatable seed 1847 with graded nursery/village clearings and physical slopes. Item/weapon shops, storage and Mayor Mame are exterior placeholders; transactions, interiors and mayor quests are not implemented. The opening pod quest and western nursery harvest plants remain playable.

Farm combat coverage: nine slimes in three outdoor packs, three village dummies, real knife/fist damage, dummy recovery without rewards, exactly-once EXP per defeat, repeatable respawns, session EXP retained on player defeat, and village protection against pursuit, pending attacks and knockback. `test_farm_combat.gd` runs in the verifier. `godot --path . --script res://tests/preview_farm_combat.gd --fixed-fps 60` renders practice, outdoor packs and EXP feedback to `/tmp/fufufarm-{practice,pack-3,pack--29,pack-31,experience}.png`.

Co-op coverage in the main verifier: schema and numeric guards, four-player admission, replay/rate limits, stale held-input cancellation, authoritative guest combat/guard/drop/retrieval, harvest/loot healing, mob EXP, respawn, reconnect state, JSON-wire opening progression and disk checkpoints. `test_coop_launch.gd` also exercises the actual new/save/return/continue lobby flow. Guests never save or simulate outcomes.

Run `npm test --prefix networking/sidecar` for encrypted local discovery, framing/backpressure, persistent identity and shutdown. `python3 tools/verify_coop.py` runs separate Godot processes and real sidecars using an isolated local DHT; add `--public-network` to use the public DHT on a random verification topic. Both paths verify guest combat, healing, drop/recovery, disconnect/rejoin, stable identity, host saves and child cleanup. Passing on one computer does not verify different NATs or operating systems.

Run `godot --path . --script res://tests/preview_coop.gd` for `/tmp/tofufu-coop-{host,guest}.png`, and `godot --path . --script res://tests/preview_menu.gd` for `/tmp/tofufu-menu-*.png`. Physical controllers, distant-network latency and signed export installation remain manual checks.


Progression coverage: `test_progression.gd` exercises cumulative curves, rank boundaries, event restrictions, caps, modifier bounds and save/wire counter validation. Farm combat tests cover actual dummy practice and damage/defence bonuses. Frontend and co-op tests cover partial practice on disk, solo-to-host continuation, actor isolation, replicated EXP and reconnect restoration. `preview_progression.gd` renders ranks 1, 25 and 99 plus the compact HUD to `/tmp/tofufu-progression-*.png`.

Charge-walk coverage checks the corrected south/north rows, six animation columns, mirrored east/south-east, rear-diagonal fallback, blocked movement, focused aim and transition into airborne/landing art. `tests/preview_charge_walk.gd` renders each phase with held knives to `/tmp/tofufu-charge-walk-*.png`.


Proximity chat: `test_chat.gd` covers authoritative distance/yell routing, authenticated sender identity, epoch/replay/rate guards, malformed PCM, synthetic audio conversion, bounded playback, microphone-bus cleanup without recording, composer input suppression, speech expiry and history limits. `test_coop_scene.gd` covers bidirectional host/guest text and rejects non-host deliveries. Both run in the verifier. `tools/verify_coop.py` additionally sends text and synthetic voice through real Holepunch sidecars and confirms host playback. `godot --path . --script res://tests/preview_chat.gd` saves `/tmp/tofufu-chat-{host,guest}.png` with speech, history, a yell composer and the controls guide.

For physical voice QA, run two desktop clients with headphones, grant microphone permission, enable Mic and hold V. Confirm voice stops on release, typing, pause menus, focus loss and departure; Listen should silence playback. Walk across 12 units and confirm attenuation/cutoff, then test normal text versus yelling at 12/36 units. Check denied permission and the selected OS input device. These physical and separate-network checks are not automated.

`test_session_transport.gd` verifies a non-Holepunch transport against room admission, delivery, reconnect, host loss, delayed shutdown and actual launch injection. It runs in `tools/verify.py` with no sidecar or network.

Inventory coverage: `test_inventory.gd` checks stacking, equipment restrictions, transfers, invalid slot IDs and malformed saved stacks. `test_inventory_input.gd` exercises real viewport I/B events with the solo handler disabled, Escape, key repeat, chat and menu isolation, plus item descriptions on focus. Run it without `--headless` and with `-- --preview` to render `/tmp/tofufu-inventory.png`. `test_seed_storage.gd` and `test_loadout_shop.gd` also check focused item descriptions in chest and shop views. `test_coop_gameplay.gd` checks local bag identity, host-applied transfers, guest snapshots and replay rejection.

`test_currency.gd` checks 100-item stacks, the 100:1 / 1:1 / 100:1 / 100:1 refinement path, shortcut/replay rejection, shop tender, save limits, high-quality thumbnails, transparent 5+ art and non-overlapping sprite-sheet crop dividers. Run `godot --path . --script res://tests/preview_currency.gd` with a display for `/tmp/tofufu-currency-crops.png`, showing every stack in real backpack slots. `test_farming.gd` and `test_world_items.gd` cover compact ground beans and backpacks, full-bag retention and recovery.

World drops: `test_world_items.gd` covers swept wall/floor collision, occluded pickup, cross-actor ownership, duplicate claims, guns, reservoir-preserving swaps, focus, bag drops and save schemas. Run it without `--headless` with `-- --preview` for `/tmp/tofufu-world-items.png` and `/tmp/tofufu-ground-backpack.png`. Co-op gameplay tests also exercise another player collecting a host drop with authoritative removal on both peers.

`test_loadout_shop.gd` covers two combat slots, four support slots, Mature Bean purchases, merchant range, full bags, equipment transfers, Soyjet reserve and save restoration. Run with `-- --preview` to render equipment and shop previews. Co-op gameplay tests also check authoritative purchases and replicated currency inventories.

Stack/trade coverage includes merging a full source into a partial destination, support-slot merging, 100-item save/replica limits, sale proceeds, stale sale IDs, merchant distance and host-authoritative guest sales.

`test_map.gd` checks map projection, NPC and party markers, live movement/departure, chat isolation and modal controls. Run with `-- --preview` in a rendered Godot session to save minimap and full-map captures under `/tmp/tofufu-map*.png`.

Soybean nursery: `test_farming.gd` checks growth milestones, isolated state, repeated harvest rejection, ground Edamame, proximity pickup, full-bag retention and reach. `preview_farming.gd` renders the garden and harvest into `/tmp/soybean-{garden,harvest}.png`.

`test_coop_farming.gd` covers host and dedicated farming with two guests, JSON state and inventory synchronization, stale/range/capacity guards, checkpoint restoration, and first-person strafing/idle-facing replication. Running without `--headless` saves `/tmp/soy-coop-facing-{false,true}-{0,1}.png`.

Dedicated server acceptance: `python3 tools/verify_dedicated.py` starts a server and two actual launcher processes on loopback, checks movement and leaving, restarts the world, and verifies retained player identities and nearby collision-safe saved positions. No Oracle account or Holepunch runtime is used. `test_dedicated_peer.gd` is invoked only by this coordinator.

Sky atmosphere: `test_sky.gd` checks per-world materials, storm thresholds, flash decay and delayed thunder. Run `Godot --path . --script res://tests/preview_sky.gd` without `--headless` to render day, dawn, peach/lavender twilight, night and lightning over the meadow to `/tmp/tofufu-sky-*.png`. Thunder is cosmetic and locally timed; its final playback mix needs listening on the target device.

River and oasis: `test_river.gd` checks downhill water levels, collision-backed channels, the desert seam, correct wading bounds and bounded fish/jump/splash presentation. `preview_river.gd` renders the village, extended stream, desert descent, oasis and a fish jump to `/tmp/tofufu-river-*.png`. Wildlife is cosmetic; it does not grant loot or replicate gameplay state.

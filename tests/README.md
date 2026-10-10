# Validation

Use [the feature routing map](../docs/AGENT_MAP.md#route-a-change) to find a focused scenario. Test/preview entry scripts stay under `tests/` while runtime files are organized within their feature directories; their resource paths must follow runtime moves. Long integration scenarios are exempt from the 200-line runtime budget.

Run `python3 tools/verify.py` from the root. It runs the structural check, a Godot editor import, movement and combat rule tests, the original headless scene test, and sandbox integration tests. No third-party test framework is required.

Rule coverage: movement bounds, friction, falling gravity, coyote time, jump buffering, cooldown/re-entry, dash end and isolated per-player state. Scene coverage: actual world loading, floor collision, injected command source movement/jump/dash, cooldown HUD, camera target and zero-duration cooldown display.

Manual visual check in Godot after art/control/camera changes:

- Walk with WASD/arrows; aim into all four quadrants. Side art faces left unflipped and right flipped.
- Jump onto stones/platforms, walk off edges, and dash into obstacles. Collider should stay stable during sprite squash/stretch.
- Check idle/walk apparent size, camera follow, shadows, dash trails and ready/recharging HUD at 1280x720.
- Dash while jumping; vertical motion pauses on active dash ticks as in the prototype.

Sandbox coverage: light/heavy attack release and cooldown, per-instance health, healing caps, super-jump apex, blade width/height/tip bounds in eight directions, solid-wall occlusion, real crop destruction and healing drops, plant regrowth, bridge crossing, riverbed/wading, walking up the seed-bank hill, shop wall collision, slime telegraph/damage/respawn, and player recovery after defeat.

Parrot transport: `test_parrot_travel.gd` covers steering, altitude, menu hover, real obstacle collision, arbitrary safe landings/remounts and bounded persistence. `test_coop_parrot_travel.gd` covers JSON-wire mount/landing, guest steering, parked state, replay rejection, checkpoints and departure cleanup. `preview_parrot.gd` renders the jungle bird, free-flight hints/riding and the parked bird at 1280×720 and 960×540 to `/tmp/tofufu-parrot-*.png`.

Cloud Realm: `test_cloud_realm.gd` covers an actual flight from jungle to the realm at Y≈58, cloud landing and walking, connected satellite islands, Godfufu's placeholder greeting, landed save/load and elevated remounting. The co-op parrot scenario also checks authoritative cloud landing, guest prediction recovery and disconnect persistence. `preview_cloud_realm.gd` renders `/tmp/tofufu-cloud-{overview,godfufu,landing}.png` in Godot.

Celestial armory: `test_celestial.gd` covers real Nimbus-only purchases, level requirements, the complete four-piece outfit and partial armor, 50% protection across all hit kinds, 25% melee/fist/ranged damage and attack rates including Soyjet tick cadence, real lucky shell rolls and per-actor host loot rules, bounded aura activation and first-person masking, all 248 source frames and wrist/foot bounds, JSON equipment and combat restoration, replica variants, invalid variant rejection, authoritative raygun shots and world pickups. `preview_celestial.gd` renders all eight directions and animation phases; add `-- --weapons` for held weapon sheets. `preview_celestial_game.gd` renders the Cloud Realm shop and the real first-person equipment rig. Previews save under `.codex/visualizations/2026/10/08/celestial/`; hardware FPS and internet connectivity remain separate checks.

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


Melee flow coverage: `test_melee_flow.gd` checks eight-facing trajectory continuity, the repeating four-move chain beyond the critical cap, real swept contacts, one hit per target, frozen impact poses, buffered release aim, misses, wall occlusion, physical launch/landing, shell immunity/breaking, factory recoil, player interruption and bounded co-op fields. `preview_melee_flow.gd --fixed-fps 60` renders `/tmp/tofufu-melee-trajectories.png` and live enemy launch/combo snapshots. First-person timing is also exercised by the weapon preview/tests; human rhythm/balance and cross-device co-op remain separate checks.

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

Inventory coverage: `test_inventory.gd` checks stacking, equipment restrictions, transfers, invalid slot IDs and malformed saved stacks. `test_inventory_input.gd` exercises I/B events, item descriptions, and the first-drop confirmation with its saved opt-out. Run it without `--headless` and with `-- --preview` to render `/tmp/tofufu-inventory.png` and `/tmp/tofufu-drop-confirmation.png`. `test_seed_storage.gd` checks both Shift-click directions between bag and depot; `test_loadout_shop.gd` checks shop descriptions. `test_coop_gameplay.gd` checks host-applied inventory and depot transfers, guest snapshots and replay rejection.

`test_currency.gd` checks 100-item stacks, the 100:1 / 1:1 / 100:1 / 100:1 refinement path, shortcut/replay rejection, shop tender, save limits, high-quality thumbnails, transparent 5+ art and non-overlapping sprite-sheet crop dividers. Run `godot --path . --script res://tests/preview_currency.gd` with a display for `/tmp/tofufu-currency-crops.png`, showing every stack in real backpack slots. `test_farming.gd` and `test_world_items.gd` cover compact ground beans and backpacks, full-bag retention and recovery.

World drops: `test_world_items.gd` covers swept wall/floor collision, occluded pickup, cross-actor ownership, duplicate claims, guns, reservoir-preserving swaps, focus, bag drops and save schemas. Run it without `--headless` with `-- --preview` for `/tmp/tofufu-world-items.png` and `/tmp/tofufu-ground-backpack.png`. `test_depot_focus.gd` checks both chest rows, separate mouse targets for desk items and chest lids, directional pickup priority, stale prompts, owner protection and pickup followed by opening storage. Run with `-- --preview` and a display for `/tmp/tofufu-depot-{chest,item}-{0,10}.png`. Co-op gameplay tests also exercise another player collecting a host drop with authoritative removal on both peers.

`test_meadow_meshes.gd` checks texture-aware static batching, fixed projection scale,
shared enemy geometry, individual damage/warning materials, shell bounds, wing motion
and triangle budgets. `preview_meadow_meshes.gd` uses the actual renderer to save
`/tmp/meadow-textured-{enemies,enemies-reverse,house,depot,machinery,units,well}.png`.

`test_loadout_shop.gd` covers two combat slots, four support slots, Mature Bean purchases, merchant range, full bags, equipment transfers, Soyjet reserve and save restoration. Run with `-- --preview` to render equipment and shop previews. Co-op gameplay tests also check authoritative purchases and replicated currency inventories.

Stack/trade coverage includes merging a full source into a partial destination, support-slot merging, 100-item save/replica limits, sale proceeds, stale sale IDs, merchant distance and host-authoritative guest sales.

`test_map.gd` checks map projection, NPC and party markers, live movement/departure, chat isolation and modal controls. Run with `-- --preview` in a rendered Godot session to save minimap and full-map captures under `/tmp/tofufu-map*.png`.

Soybean nursery: `test_farming.gd` checks growth milestones, isolated state, repeated harvest rejection, ground Edamame, proximity pickup, full-bag retention and reach. `preview_farming.gd` renders the garden and harvest into `/tmp/soybean-{garden,harvest}.png`.

`test_coop_farming.gd` covers host and dedicated farming with two guests, JSON state and inventory synchronization, stale/range/capacity guards, checkpoint restoration, and first-person strafing/idle-facing replication. Running without `--headless` saves `/tmp/soy-coop-facing-{false,true}-{0,1}.png`.

Dedicated server acceptance: `python3 tools/verify_dedicated.py` starts a server and two actual launcher processes on loopback, checks movement and leaving, restarts the world, and verifies retained player identities and nearby collision-safe saved positions. No Oracle account or Holepunch runtime is used. `test_dedicated_peer.gd` is invoked only by this coordinator.

Sky atmosphere: `test_sky.gd` checks per-world materials, storm thresholds, flash decay and delayed thunder. Run `Godot --path . --script res://tests/preview_sky.gd` without `--headless` to render day, dawn, peach/lavender twilight, night and lightning over the meadow to `/tmp/tofufu-sky-*.png`. Thunder is cosmetic and locally timed; its final playback mix needs listening on the target device.

River and oasis: `test_river.gd` checks downhill water levels, collision-backed channels, the desert seam, correct wading bounds and bounded fish/jump/splash presentation. `preview_river.gd` renders the village, extended stream, desert descent, oasis and a fish jump to `/tmp/tofufu-river-*.png`. Wildlife is cosmetic; it does not grant loot or replicate gameplay state.

`test_map_exploration.gd` checks personal reveal radius, history, teleport gaps, world edges and mask round trips. `test_map.gd` also checks the following crop, pointer/camera headings, fogged NPCs, zoom and adventure-save restoration.

Armored shell coverage: `test_armored_shell.gd` checks real low foot rays, separate 65-HP armor, break-hit isolation, removed dome collision, respawn, snapshot restoration, doubled successful drops, and one shell hit per sword swing. `godot --path . --script res://tests/preview_armored_shell.gd` renders intact, hit, and break frames to `/tmp/armored-shell-{intact,hit,break}.png`. Farming and encounter drops use one stacked soybean pickup per drop event, and collection feedback is aggregated for one second.

`test_meadow_reorg.gd` covers camera-relative NPC art, both depot entrances,
wide machinery access, locked-room boundaries, village lawn/path coverage and
the satellite-plan village's personal chest
ownership, stale-bay rejection, attended/public frontal displays, save/protocol
validation, actual food harvests and the barn combat boundary.
`preview_meadow_reorg.gd` renders the village, barn cutaway, both Fufu NPCs,
wood-fired kitchen, guest room, split garden, covered Studnia and detailed walnuts
with the actual renderer. `preview_village_residents.gd` renders the five camera
angles for both NPCs together, including matched scale, feet and mirrored SE. The co-op gameplay
scenario checks guest quest acceptance, personal kill progress, authoritative
reward replication and duplicate-claim rejection.

`test_soy_reload.gd` checks reload countdown/progress through render callbacks,
world and first-person poses, replica presentation, weapon switching and refill.
Run it without `--headless` with `-- --preview` to save start, midpoint and ready
frames in all three camera modes to `/tmp/tofufu-reload-*.png`.

`test_gun_run_pose.gd` checks smooth running/walking carry transitions, matching
reticle and aiming rays, fire/reload priority, exhaustion and camera/weapon cleanup.
Run with a display and `-- --preview` to save shoulder and first-person carry
poses to `/tmp/tofufu-gun-carry-*.png`.

Grass: `test_grass.gd` checks the fixed deformation map, gradual recovery, swept
contacts, teleport gaps, jumping/mounted/departed actors, co-op cosmetic contacts,
seeded dense patches and preserved wind/rain wiring. `preview_grass.gd` renders normal
and close views, a walked trail, wind and recovery to `/tmp/tofufu-grass-*.png`.
Grass uses five triangles per narrow blade, eight-metre culled patches with
distance taper, and a shared 304 × 256 texture updated at 20 Hz only while dirty.
No grass physics bodies or per-blade CPU simulation are created.

Natural terrain: `test_world_contours.gd` checks reproducible seeded coastlines,
continuous biome crossings and colours, collision-backed islands, lagoon access,
map discovery, aquatic wildlife and actual walking from reef to dry atoll ground.
`test_ocean.gd` and `test_coop_ocean.gd` cover sustained underwater movement,
save recovery and authoritative/predicted water resistance. `preview_world_contours.gd`
renders the atoll, lagoon, meadow/dunes and dunes/jungle crossings plus the map to
`/tmp/tofufu-world-*.png` using Godot's renderer.

`test_volcanic.gd` verifies the separate ocean channel, actual parrot crossing/landing, all 149 royal-route chamber passages, every physical switchback ascent, retained collision under cutaway, local/host lava burns and guest exclusion, King greeting, expanded map round trips and original-mask migration. `preview_volcanic.gd` captures the actual Godot continent, ocean, castle, maze and king to `/tmp/tofufu-volcanic-*.png`.

`test_castle_challenge.gd` checks twelve connected dead-end chests, atomic/replayed/full-bag grants, legacy saves, memory press feedback, compact task-panel bounds, actual guardian strafing/dashing/lunge contact, shield flanking, and fast king chunks stopped by cover or applying burning on an exposed hit. `test_coop_castle.gd` sends real JSON-wire chest/puzzle intent between local fake peers and verifies inventory entitlement, visible acknowledgements, guardian spell/stance replication, fast chunk bursts and host-only outcomes. `preview_castle_challenge.gd` captures the actual shoulder and FPP cameras on all puzzle decks, additional north/east/west approaches, remembered/wrong glyph feedback, closed/opening/open treasure and king chunk VFX to `/tmp/tofufu-castle-challenge-*.png`. Human difficulty tuning and remote-device play remain separate checks.

`test_volcanic_expansion.gd` walks a player-size capsule across every outdoor lava bridge and both ramps, sweeps the complete ash circuit for supported dry terrain, lava protection and obstacle clearance, and checks eastern-coast co-op records plus finite coordinate bounds. Volcanic tests also retain both older exploration masks and eastern-coast saves. The preview includes all five authored districts and the enlarged central volcano.

`test_lava_king_art.gd` orbits a real camera through eight directions, checks the
five authored King Lava views, mirrored western angles, constant height and foot
anchors, authored rotation, retained collider and greeting state. Run
`preview_lava_king.gd` with a display for the five-view plate and eight camera views
at `/tmp/tofufu-lava-king-*.png`. Original art and exact generation prompts remain
under `assets/characters/lava_king/`.

Perspective performance: `benchmark_perspectives.gd` measures overhead, shoulder and
first-person cameras at village, grass, reef, castle and clouds.
`benchmark_coop_rendering.gd -- --perspectives` covers four moving/firing actors;
add `--adaptive` for the 120 FPS local profile or `--guest` for the deliberate
two-world guest stress harness. All rendering benchmarks use a fixed 2560 × 1440
SubViewport through `rendering_viewport.gd` and record actual texture dimensions.
The co-op fixture protects actors from defeat, checks relocation and rejects
location changes so a respawn cannot turn a reef sample into a meadow sample.
Run them separately from the verifier and other Godot processes. Use explicit
matching baselines with `tools/check_render_budget.py`; historical JSON without
render dimensions is not valid 1440p evidence. See [performance policy](../docs/PERFORMANCE.md).

`test_occlusion.gd` checks inset opaque blockers, cutaway visibility, retained
collision and one-sided cloud floors. `test_scenery_batch.gd` checks exact leaf
positions, material/layer separation, named controls, scaled/mirrored normals, UVs
and ink extrusion. `preview_occlusion.gd` captures paired culling-off/on views at
buildings, cutaways, openings and below clouds. `preview_scenery_batch.gd` compares
authored and baked props at native 1440p. Headless passes do not establish FPS.

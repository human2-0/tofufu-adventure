# Agent map

This is a routing map for coding work, not a list of runtime AI characters or an instruction to spawn agents. Paths below exist unless marked **planned**. Root `AGENTS.md` always applies; load only the scopes on your edit path.

```text
./
├── AGENTS.md                    # global invariants + short workflow
├── export_presets.cfg           # desktop/mobile development export baselines
├── project.godot                # entry scene, controls, engine, collision layers
├── game/
│   ├── AGENTS.md                # Godot conventions
│   ├── app/
│   │   ├── dedicated_server.{gd,tscn} # optional persistent server authority and saves
│   │   ├── oracle_launch.tscn # explicit Oracle client composition
│   │   ├── launch.{gd,tscn}    # title, pause and feature lifecycle composition
│   │   ├── {save,settings,lobby}_flow.gd # menu action composition
│   │   ├── actor_progression.gd # combat events -> per-character rules, modifiers and HUD
│   │   ├── adventure_snapshot.gd # scene-to-save value translation
│   │   ├── proximity_chat.gd   # offline/co-op chat composition, host distance routing and input gating
│   │   ├── session_connection.gd # injected transport -> room wiring and connection lifecycle
│   │   ├── coop_session.gd      # full host gameplay / guest synchronization
│   │   ├── coop_prediction.gd # bounded guest movement history and host position corrections
│   │   ├── coop_{actor,roster}.gd # party simulation, presentation and reconnect state
│   │   ├── coop_{world,encounters}.gd # replicated encounters, loot and progression
│   │   ├── coop_{opening,checkpoint,values}.gd # shared quest, saves and command translation
│   │   ├── main.tscn            # player, level, camera and HUD composition
│   │   ├── first_person_weapon.gd # isolated first-person weapon/hand overlay
│   │   ├── shooting_view.gd    # local view toggle, mouse orbit, aim zoom and reticle wiring
│   │   ├── world_items.gd # shared drops, actor grants, focused pickup and stack drops
│   │   ├── world_item_visuals.gd # existing weapon art on centered pickup bodies
│   │   ├── inventory_controls.gd # local bag shortcuts, modal input and cursor lifecycle
│   │   ├── coop_inventory.gd # bounded host-authoritative bag transfer intents
│   │   ├── main.gd              # cross-feature wiring + respawn
│   │   ├── quest_giver.gd       # Mayor Mame quest interaction, kill counting and rewards
│   │   ├── pod_opening.gd       # first-quest actor/camera/world composition
│   │   ├── weather_flow.gd      # weather -> atmosphere, HUD and snail modifiers
│   │   ├── sandbox_encounters.gd # explicit combat, prop and loot composition
│   │   ├── exploration_sites.gd  # four Fufufarm discovery landmarks
│   │   └── tofu_dungeon{,_replica}.gd # factory entry, waves, snapshots and unlock
│   ├── farming/                 # per-plot soybean lifecycle, soil and supplied atlas presentation
│   ├── app/soybean_farming.gd  # nursery test plots, reach and ground Edamame drops
│   ├── app/coop_farming.gd     # host/server farming intents, revisions and reward routing
│   ├── quest/quest_state.gd     # isolated quest rules, status and save representation
│   ├── quest/tofu_dungeon_state.gd # six factory stages and one-use crate record
│   ├── progression/character_progress.gd # capped skill practice, EXP curves and derived stats
│   ├── progression/{progression_tuning.gd,default_progression.tres} # shared authored balance
│   ├── ui/character_stats.gd   # level, skill ranks, stat points and interactive allocation
│   ├── persistence/save_store.gd # versioned atomic adventure slots
│   ├── settings/game_preferences.gd # saved display and device bindings
│   ├── chat/                    # bounded proximity rules, composer/history, speech labels, microphone and playback
│   ├── inventory/equipment_layout.gd # anatomical slot placement and muted SVG placeholders
│   ├── inventory/apparel_set_bonus.gd # Soypod/Nori full-set movement and combat modifiers
│   ├── inventory/               # bag, equipment, transfers, healing and world_item_{drop,pool}.gd collision bodies
│   │   ├── currency_{exchange,visuals}.gd # selected-stack atomic refinement and transparent stack art
│   │   ├── inventory_icon_quality.gd # isolated high-quality thumbnails for slot art
│   │   └── icons/*.png          # rendered staff and Soypod Backpack item art
│   ├── session/                 # roster, actor/world schemas and bounded input window
│   ├── ui/menu/                 # themed title, settings, saves and lobby views
│   ├── player/
│   │   ├── AGENTS.md            # actor responsibilities
│   │   ├── player.tscn          # body + collider + input + sprite
│   │   ├── player.gd            # actor coordinator / physics adapter
│   │   ├── player_command.gd    # per-tick intent value
│   │   ├── player_command_source.gd # substitutable input contract
│   │   ├── remote_player_input.gd # bounded validated intent with stale-input stop
│   │   ├── party_opening_input.gd # shared quest intent composition
│   │   ├── local_player_input.gd # keyboard/mouse/gamepad/touch -> command
│   │   ├── player_tuning.gd     # editor-configurable parameters
│   │   ├── player_placement.gd # free capsule placement for joins, respawns and loads
│   │   ├── player_motor.gd      # walk, jump, dash rules + per-actor state
│   │   ├── fufu_visuals.gd      # facing, frames, squash/stretch, hand landmarks
│   │   ├── outfit_equip_effect.gd # short world-space set completion transition
│   │   ├── fufu_charge_animation.gd # six-frame charge walking, atlas regions and hands
│   │   ├── directional_jump_art.gd # four generated rows, mirrored views and hand/foot calibration
│   │   ├── jump_atlas.gdshader # full billboard rendering and source matte removal
│   │   ├── fufu_jump_animation.gd # contact-driven jump/fall/landing frames
│   │   ├── ground_shadow.gd   # projected landing cue
│   │   └── dash_ghost.gd        # disposable dash effect
│   ├── opening/
│   │   ├── pod_escape_rules.gd  # timed pushes, stem snap, fall, split, reveal
│   │   └── soybean_plant.gd     # 3D nursery plant, shell and occupant marker
│   ├── camera/camera_follow.gd # follows an assigned target
│   ├── app/map_flow.gd       # terrain atlas, NPC and replicated party marker composition
│   ├── ui/{map_view,map_canvas}.gd # minimap and full north-up map presentation
│   ├── ui/gun_reticle.gd     # pointer/center aim and spread cue
│   ├── ui/touch_controls.gd      # multitouch action buttons
│   ├── ui/pod_quest_hud.gd     # opening instructions and precision meter
│   ├── ui/quest_window.gd      # frosted dialog for quest dialogue, progress and rewards
│   ├── ui/pod_focus.gdshader   # close-up background softening
│   ├── ui/weather_view.gd    # local weather status and rain overlay
│   ├── ui/rain.gdshader      # animated rain streaks
│   ├── ui/soy_hit_flash.gd # brief local soybean impact feedback
│   ├── ui/snail_smear.{gd,gdshader} # fading screen refraction on local damage
│   ├── ui/hud.{gd,tscn}         # presentation of cooldown data
│   ├── ui/{dash_slot,jump_meter,kawaii_popup,hud_elements}.gd # skill slot, delayed jump, celebrations and HUD styling
│   ├── ui/outfit_celebration.gd # full-set banner above inventory
│   ├── combat/
│   │   ├── {combat,encounter}_state.gd # bounded capture and replica presentation
│   │   ├── combat_tuning.gd     # shared authored combat values
│   │   ├── player_equipment.gd # knife/fist/gun slots, directional guard, punch and drop/recovery
│   │   ├── gun_recoil.gd      # per-weapon spray bloom and release recovery
│   │   ├── sotjet{,_tuning,_flow,_parcel}.gd # slot-4 reservoir, gravity-driven milk and swept hits
│   │   ├── sotjet_{visual,stream_visual}.gd # generated weapon views and physical stream presentation
│   │   ├── soy_gun.gd         # slot-3 cadence, spread and authority/replica bean creation
│   │   ├── liquid_impact.gd # rounded short-lived drops at soybean collision points
│   │   ├── soy_projectile.gd  # swept fast-bean collision, body/head damage
│   │   ├── soy_gun_visual.gd # camera-facing directional atlas and grip attachment
│   │   ├── melee_rules.gd       # per-instance charge/cooldown
│   │   ├── damageable.gd        # explicit health and hit contract
│   │   ├── player_combat.gd     # swept blade overlaps + world occlusion
│   │   ├── sword_geometry.gd    # upright hand pose, cutting arc, blade transform
│   │   ├── sword_visual.gd      # eight-view sword, hand attachment + debug bounds
│   │   ├── staff_attack.gd      # shared melee moves and staff 360-degree secondary sweep
│   │   ├── staff_visual.gd      # supplied 3D staff aligned with melee pose
│   │   ├── sword_trail.gd       # visual ribbon during the cutting arc
│   │   ├── combat_effects.gd    # floating hit/heal feedback
│   │   ├── training_mob.gd      # snail chase/leash, village exclusion, respawn
│   │   ├── {snail_tuning.gd,default_snail.tres} # dry/rain health, damage and respawn balance
│   │   ├── snail_visuals.gd     # idle/walk/attack frames, eight mirrored directions
│   │   ├── armored_snail_visuals.gd # procedural full-3D level-two snail and shell response
│   │   ├── practice_dummy.gd    # reusable straw target, damage feedback, recovery
│   │   ├── harvest_prop.gd      # 3D renewable soy/crate/boulder
│   │   ├── factory_{bean,crate}.gd # evil soy variants and breakable milk crate
│   │   └── soybean_pickup.gd    # proximity-collected Edamame drop
│   ├── world/sky_effects.gd    # pastel cloud sky, twilight palettes and cosmetic thunder
│   ├── world/storybook_sky.gdshader # drifting billows, celestial details and distant lightning
│   └── world/
│       ├── meadow.{gd,tscn}     # Fufufarm terrain/scenery composition
│       ├── tofu_factory.gd      # Gigalopolis entry and two-deck switchback factory
│       ├── ocean_{world,terrain,props}.gd # broad northern underwater world and reef scenery
│       ├── frost_{world,terrain,props}.gd # northern snowfields, ice and alpine scenery
│       ├── desert_{world,terrain,props}.gd # broad southern dunes, oasis and desert scenery
│       ├── jungle_{world,terrain,props}.gd # level-eight southern jungle, terrain and tropical scenery
│       ├── river_course.gd # shared downhill river/oasis profile, carved bed and bounded water queries
│       ├── river_surface.gd # continuous flowing surface from northern reach to desert pond
│       ├── river_{wildlife,fish_art,plants}.gd # cosmetic fish jumps, splash rings, reeds and lilies
│       ├── farm_terrain.gd     # seeded heightfield + shared collision surface
│       ├── farm_ground.gdshader # soft lanes, soil furrows and stream banks
│       ├── farm_buildings.gd   # cottages, storage, village NPC placeholders
│       ├── farm_combat_grounds.gd # outdoor clearings, village practice yard, placement data
│       ├── farm_foliage.gd     # instanced soy rows and wild ground cover
│       ├── meadow_geometry.gd  # local geometry construction helpers
│       ├── weather_cycle.gd     # authoritative clear/overcast/rain clock
│       ├── environment_cycle.gd # day/night, lanterns and fireflies
│       ├── ink_outline.{gdshader,tres} # shared ink silhouette pass
│       ├── {river,meadow_grass}.gdshader # flow and wind presentation
│       └── {tree,stone,platform}.tscn # original reusable environment props
├── assets/
│   ├── AGENTS.md                # import and art conventions
│   ├── currency/source/*.png    # supplied transparent bean and tofu stack sheets
│   ├── factory/*.svg            # original evil soybean/Dofu sprites and soy milk bottle
│   ├── combat/*.svg            # original vector slime, fist and soybean art
│   ├── characters/snail/       # supplied sources and extracted animation atlases
│   ├── equipment/               # Soypod/Nori set item art and equipment sheets
│   ├── weapons/soy_gun/      # unchanged supplied sources and provenance
│   ├── weapons/sotjet/       # generated ten-view milk sprayer atlas and provenance
│   ├── weapons/sword/          # generated atlas and generation prompt
│   └── characters/fufu/        # walk art, idle/source provenance, and Soypod/Nori outfit walking + standing sheets
├── networking/
│   ├── AGENTS.md                # adapter/transport rules
│   ├── godot/session_transport.gd # abstract discovery, delivery and shutdown contract
│   ├── godot/holepunch_transport.gd # process + authenticated loopback bridge
│   ├── oracle/                  # TLS WebSocket adapter and bounded socket lifecycle
│   ├── sidecar/                 # pinned Hyperswarm runtime and local tests
│   ├── DEDICATED.md             # local dedicated server and player setup
│   └── README.md                # setup and current limitations
├── tests/
│   ├── AGENTS.md
│   ├── README.md
│   ├── test_pod_escape.gd       # failure/retry and complete quest integration
│   ├── preview_pod.gd           # rendered opening milestones
│   ├── test_frontend.gd         # menu startup, save/load, bindings, protocol guards
│   ├── test_chat.gd             # distance/yell routing, identity/rate guards, PCM and input isolation
│   ├── preview_chat.gd          # rendered chat composer, guide, speech and history
│   ├── test_dedicated_peer.gd  # launcher client for verify_dedicated.py
│   ├── test_oracle.gd          # real local sockets, dedicated world, identity and reconnect
│   ├── test_session_transport.gd # alternate transport lifecycle, room protocol and launch injection
│   ├── preview_coop_response.gd # rendered shoulder walking and soybean hit feedback
│   ├── test_coop_response.gd # injected latency, prediction, facing and friendly-hit feedback
│   ├── test_coop_farming.gd   # three-world host/dedicated farming and first-person facing
│   ├── test_coop_scene.gd       # fake transport, two worlds, roster and snapshots
│   ├── test_coop_{protocol,gameplay,opening,launch}.gd # limits, outcomes, quest/save flow
│   ├── test_coop_peer.gd        # real Godot + Holepunch process verification
│   ├── coop_test_input.gd       # injected co-op test commands
│   ├── preview_coop.gd          # rendered host/guest views
│   ├── preview_menu.gd          # rendered title/settings/lobby at two sizes
│   ├── test_jungle.gd          # per-character level gate, collision ground and rendered jungle QA
│   ├── test_map.gd             # map markers, projection, modal input and rendered atlas QA
│   ├── test_input.gd            # gamepad actions, deadzones and touch composition
│   ├── preview_controls.gd      # desktop/phone/tablet rendered layouts
│   ├── test_actor_collisions.gd # player/snail sweeps, dash and occupied respawns
│   ├── preview_actor_collisions.gd # rendered movement contact and capsule bounds
│   ├── test_player_motor.gd     # rule behavior and instance isolation
│   ├── test_scene.gd            # actual scene wiring/collisions/controls
│   ├── test_tofu_dungeon{,_coop}.gd # stages, loot, healing, recipe and co-op authority
│   ├── test_factory_route.gd  # real capsule walk through factory doors and ramp
│   ├── preview_tofu_factory.gd # rendered exterior, decks, machinery and enemies
│   ├── test_jump.gd             # charge/release, cancellation and animation phases
│   ├── preview_charge_walk.gd   # all charge directions and six-frame grip renders
│   ├── preview_jump.gd          # rendered real jump through all ten poses
│   ├── test_progression.gd   # growth curves, training gates, caps and value validation
│   ├── preview_progression.gd # rendered skill HUD at early, middle and capped ranks
│   ├── test_combat.gd           # combat/health rules + jump-height regression
│   ├── test_sandbox.gd          # harvest/heal, occlusion, river, farm slopes, buildings, mobs
│   ├── {test,preview}_river.gd # river seams/collision, bounded wildlife and rendered oasis QA
│   ├── {test,preview}_sky.gd # isolated atmosphere timing and six rendered sky moods
│   ├── test_weather.gd         # rain outcomes, old saves, replicas and rendered weather QA
│   ├── test_snail.gd           # eight views, attack timing, damage smear and rendered QA
│   ├── test_farm_combat.gd     # dummy knife/fists, EXP/respawn, village protection
│   ├── preview_farm_combat.gd  # rendered practice, packs and EXP HUD
│   ├── test_equipment.gd       # directional guard, charge cancellation, slots and punches
│   ├── preview_gun_recoil.gd # cold/sustained/recovered aimed-fire rendering
│   ├── test_gun_recoil.gd    # burst growth, bounds, recovery and instance isolation
│   ├── preview_directional_jump.gd # all jump phases/directions and cosmetic muzzle origins
│   ├── test_sotjet{,_coop}.gd # ballistics, reservoir, cover, saves and two-world friendly fire
│   ├── preview_reflection.gd # live sword deflection returning milk to its source
│   ├── preview_liquid_hits.gd # rendered milk damage numbers and soybean collision drops
│   ├── preview_sotjet.gd    # rendered directional weapon art and falling milk stream
│   ├── {test,preview}_soy_flight.gd # continuous single-bean muzzle departure in FPP/overhead
│   ├── test_soy_gun.gd       # swept hits, headshots, occlusion, protocol, orbit and input
│   ├── test_first_person.gd # view cycle, eye position, local visibility and camera-relative input
│   ├── preview_first_person.gd # rendered first-person equipment slots and aim
│   ├── preview_soy_gun.gd    # rendered overhead, shoulder, ADS and eight orbit directions
│   ├── test_sword.gd            # eight-direction blade bounds, sweeps, sprites, tilt
│   ├── test_staff_combat.gd     # power tiers, charged strikes and 360-degree staff hits
│   ├── preview_staff.gd         # rendered staff and knife size comparison
│   ├── preview_sword.gd         # rendered directions and hitbox overlays
│   ├── preview_fufufarm.gd     # overview, farms, storage and village renders
│   └── preview_sandbox.gd       # rendered day/river/night QA images
├── deploy/oracle/               # setup guide, systemd, credentials, validated release switch
├── .github/workflows/oracle-deploy.yml # opt-in main-branch deployment over SSH
├── tools/
│   ├── check_architecture.py    # dependency and path checks
│   ├── local_multiplayer.py     # portable dedicated server/player/stop commands
│   ├── verify_dedicated.py      # separate server/client processes and restart checks
│   ├── verify_coop.py           # separate Godot/sidecar lifecycle integration
│   ├── package_coop.py          # platform-matched desktop runtime staging
│   ├── render_staff_inventory_icon.gd # transparent PNG render from supplied staff GLB
│   └── verify.py                # headless verification entry point
└── docs/
    ├── AGENTS.md
    ├── PLATFORMS.md             # controls, exports and release prerequisites
    ├── AGENT_MAP.md             # this routing index
    └── architecture/
        ├── OVERVIEW.md          # decisions, dependency diagram, growth rules
        └── COOP.md              # implemented co-op protocol, persistence and limits
```

## Route a task

| Task / ownership role | Read first | Verification |
| --- | --- | --- |
| Opening quest | `game/opening/`, `app/pod_opening.gd`, `ui/pod_quest_hud.gd` | pod escape + rendered preview |
| Gameplay rules | `game/player/AGENTS.md`, motor, tuning, command | motor tests + scene test |
| Combat / healing / mobs | `game/combat/`, app encounter wiring | combat + sandbox tests |
| Inventory / Equipment | `game/inventory/`, `game/app/actor_loadout.gd`, `game/app/weapon_merchant.gd` | inventory, loadout/shop, world items + sandbox tests |
| World / exploration | `game/world/meadow.*`, cycle, app discovery wiring | sandbox + rendered preview |
| Tofu Factory dungeon | `world/tofu_factory.gd`, `world/factory_*.gd`, `world/gigalopolis*.gd`, `app/tofu_dungeon*.gd`, `quest/tofu_dungeon_state.gd` | dungeon/route tests + rendered preview |
| Controls | local input, command source, `project.godot` | scene test + manual mouse check |
| Character art / animation | visuals, ghost, `assets/AGENTS.md` | import + manual play |
| Camera / HUD | respective feature + `game/app/main.gd` | scene test + manual play |
| Level / collision | `game/world/`, `game/app/main.tscn` | scene test + traversal |
| Proximity chat / voice | `game/chat/`, `app/proximity_chat.gd`, `architecture/COOP.md` | chat + co-op scene tests, rendered preview, physical microphone check |
| Co-op / transport | `networking/AGENTS.md`, `architecture/COOP.md` | protocol, gameplay + two-process tests |
| Structure / tooling | `architecture/OVERVIEW.md`, tools | architecture checker + verifier |
| Agent instructions | root + affected scope, this map | architecture checker |

For an explicit parallel-agent task, divide by these ownership roles, assign exact files, and have one integrator own scene wiring and shared contracts. Do not have multiple agents edit the same scene. Otherwise use the map for focused single-agent work.

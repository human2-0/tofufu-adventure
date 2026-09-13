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
│   │   ├── launch.{gd,tscn}    # title, pause and feature lifecycle composition
│   │   ├── {save,settings,lobby}_flow.gd # menu action composition
│   │   ├── actor_progression.gd # combat events -> per-character rules, modifiers and HUD
│   │   ├── adventure_snapshot.gd # scene-to-save value translation
│   │   ├── proximity_chat.gd   # offline/co-op chat composition, host distance routing and input gating
│   │   ├── session_connection.gd # injected transport -> room wiring and connection lifecycle
│   │   ├── coop_session.gd      # full host gameplay / guest synchronization
│   │   ├── coop_{actor,roster}.gd # party simulation, presentation and reconnect state
│   │   ├── coop_{world,encounters}.gd # replicated encounters, loot and progression
│   │   ├── coop_{opening,checkpoint,values}.gd # shared quest, saves and command translation
│   │   ├── main.tscn            # player, level, camera and HUD composition
│   │   ├── shooting_view.gd    # local view toggle, mouse orbit, aim zoom and reticle wiring
│   │   ├── main.gd              # cross-feature wiring + respawn
│   │   ├── pod_opening.gd       # first-quest actor/camera/world composition
│   │   ├── weather_flow.gd      # weather -> atmosphere, HUD and snail modifiers
│   │   ├── sandbox_encounters.gd # explicit combat, prop and loot composition
│   │   └── exploration_sites.gd  # four Fufufarm discovery landmarks
│   ├── progression/character_progress.gd # capped skill practice, EXP curves and derived stats
│   ├── progression/{progression_tuning.gd,default_progression.tres} # shared authored balance
│   ├── ui/character_stats.gd   # level, skill ranks and next-rank progress view
│   ├── persistence/save_store.gd # versioned atomic adventure slots
│   ├── settings/game_preferences.gd # saved display and device bindings
│   ├── chat/                    # bounded proximity rules, composer/history, speech labels, microphone and playback
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
│   ├── ui/gun_reticle.gd     # pointer/center aim and spread cue
│   ├── ui/touch_controls.gd      # multitouch action buttons
│   ├── ui/pod_quest_hud.gd     # opening instructions and precision meter
│   ├── ui/pod_focus.gdshader   # close-up background softening
│   ├── ui/weather_view.gd    # local weather status and rain overlay
│   ├── ui/rain.gdshader      # animated rain streaks
│   ├── ui/snail_smear.{gd,gdshader} # fading screen refraction on local damage
│   ├── ui/hud.{gd,tscn}         # presentation of cooldown data
│   ├── ui/{dash_slot,jump_meter,kawaii_popup,hud_elements}.gd # skill slot, delayed jump, celebrations and HUD styling
│   ├── combat/
│   │   ├── {combat,encounter}_state.gd # bounded capture and replica presentation
│   │   ├── combat_tuning.gd     # shared authored combat values
│   │   ├── player_equipment.gd # knife/fist/gun slots, directional guard, punch and drop/recovery
│   │   ├── gun_recoil.gd      # per-weapon spray bloom and release recovery
│   │   ├── soy_gun.gd         # slot-3 cadence, spread and authority/replica bean creation
│   │   ├── soy_projectile.gd  # swept fast-bean collision, body/head damage
│   │   ├── soy_gun_visual.gd # camera-facing directional atlas and grip attachment
│   │   ├── melee_rules.gd       # per-instance charge/cooldown
│   │   ├── damageable.gd        # explicit health and hit contract
│   │   ├── player_combat.gd     # swept blade overlaps + world occlusion
│   │   ├── sword_geometry.gd    # upright hand pose, cutting arc, blade transform
│   │   ├── sword_visual.gd      # eight-view sword, hand attachment + debug bounds
│   │   ├── sword_trail.gd       # visual ribbon during the cutting arc
│   │   ├── combat_effects.gd    # floating hit/heal feedback
│   │   ├── training_mob.gd      # snail chase/leash, village exclusion, respawn
│   │   ├── {snail_tuning.gd,default_snail.tres} # dry/rain health, damage and respawn balance
│   │   ├── snail_visuals.gd     # idle/walk/attack frames, eight mirrored directions
│   │   ├── practice_dummy.gd    # reusable straw target, damage feedback, recovery
│   │   ├── harvest_prop.gd      # 3D renewable soy/crate/boulder
│   │   └── soybean_pickup.gd    # collectible 2D healing drop
│   └── world/
│       ├── meadow.{gd,tscn}     # Fufufarm terrain/scenery composition
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
│   ├── combat/*.svg            # original vector slime, fist and soybean art
│   ├── characters/snail/       # supplied sources and extracted animation atlases
│   ├── weapons/soy_gun/      # unchanged supplied sources and provenance
│   ├── weapons/sword/          # generated atlas and generation prompt
│   └── characters/fufu/        # walk art, eight-pose idle PNG, source provenance
├── networking/
│   ├── AGENTS.md                # adapter/transport rules
│   ├── godot/session_transport.gd # abstract discovery, delivery and shutdown contract
│   ├── godot/holepunch_transport.gd # process + authenticated loopback bridge
│   ├── sidecar/                 # pinned Hyperswarm runtime and local tests
│   └── README.md                # setup and current limitations
├── tests/
│   ├── AGENTS.md
│   ├── README.md
│   ├── test_pod_escape.gd       # failure/retry and complete quest integration
│   ├── preview_pod.gd           # rendered opening milestones
│   ├── test_frontend.gd         # menu startup, save/load, bindings, protocol guards
│   ├── test_chat.gd             # distance/yell routing, identity/rate guards, PCM and input isolation
│   ├── preview_chat.gd          # rendered chat composer, guide, speech and history
│   ├── test_session_transport.gd # alternate transport lifecycle, room protocol and launch injection
│   ├── test_coop_scene.gd       # fake transport, two worlds, roster and snapshots
│   ├── test_coop_{protocol,gameplay,opening,launch}.gd # limits, outcomes, quest/save flow
│   ├── test_coop_peer.gd        # real Godot + Holepunch process verification
│   ├── coop_test_input.gd       # injected co-op test commands
│   ├── preview_coop.gd          # rendered host/guest views
│   ├── preview_menu.gd          # rendered title/settings/lobby at two sizes
│   ├── test_input.gd            # gamepad actions, deadzones and touch composition
│   ├── preview_controls.gd      # desktop/phone/tablet rendered layouts
│   ├── test_actor_collisions.gd # player/snail sweeps, dash and occupied respawns
│   ├── preview_actor_collisions.gd # rendered movement contact and capsule bounds
│   ├── test_player_motor.gd     # rule behavior and instance isolation
│   ├── test_scene.gd            # actual scene wiring/collisions/controls
│   ├── test_jump.gd             # charge/release, cancellation and animation phases
│   ├── preview_charge_walk.gd   # all charge directions and six-frame grip renders
│   ├── preview_jump.gd          # rendered real jump through all ten poses
│   ├── test_progression.gd   # growth curves, training gates, caps and value validation
│   ├── preview_progression.gd # rendered skill HUD at early, middle and capped ranks
│   ├── test_combat.gd           # combat/health rules + jump-height regression
│   ├── test_sandbox.gd          # harvest/heal, occlusion, river, farm slopes, buildings, mobs
│   ├── test_weather.gd         # rain outcomes, old saves, replicas and rendered weather QA
│   ├── test_snail.gd           # eight views, attack timing, damage smear and rendered QA
│   ├── test_farm_combat.gd     # dummy knife/fists, EXP/respawn, village protection
│   ├── preview_farm_combat.gd  # rendered practice, packs and EXP HUD
│   ├── test_equipment.gd       # directional guard, charge cancellation, slots and punches
│   ├── preview_gun_recoil.gd # cold/sustained/recovered aimed-fire rendering
│   ├── test_gun_recoil.gd    # burst growth, bounds, recovery and instance isolation
│   ├── preview_directional_jump.gd # all jump phases/directions and cosmetic muzzle origins
│   ├── test_soy_gun.gd       # swept hits, headshots, occlusion, protocol, orbit and input
│   ├── preview_soy_gun.gd    # rendered overhead, shoulder, ADS and eight orbit directions
│   ├── test_sword.gd            # eight-direction blade bounds, sweeps, sprites, tilt
│   ├── preview_sword.gd         # rendered directions and hitbox overlays
│   ├── preview_fufufarm.gd     # overview, farms, storage and village renders
│   └── preview_sandbox.gd       # rendered day/river/night QA images
├── tools/
│   ├── check_architecture.py    # dependency and path checks
│   ├── verify_coop.py           # separate Godot/sidecar lifecycle integration
│   ├── package_coop.py          # platform-matched desktop runtime staging
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
| World / exploration | `game/world/meadow.*`, cycle, app discovery wiring | sandbox + rendered preview |
| Controls | local input, command source, `project.godot` | scene test + manual mouse check |
| Character art / animation | visuals, ghost, `assets/AGENTS.md` | import + manual play |
| Camera / HUD | respective feature + `game/app/main.gd` | scene test + manual play |
| Level / collision | `game/world/`, `game/app/main.tscn` | scene test + traversal |
| Proximity chat / voice | `game/chat/`, `app/proximity_chat.gd`, `architecture/COOP.md` | chat + co-op scene tests, rendered preview, physical microphone check |
| Co-op / transport | `networking/AGENTS.md`, `architecture/COOP.md` | protocol, gameplay + two-process tests |
| Structure / tooling | `architecture/OVERVIEW.md`, tools | architecture checker + verifier |
| Agent instructions | root + affected scope, this map | architecture checker |

For an explicit parallel-agent task, divide by these ownership roles, assign exact files, and have one integrator own scene wiring and shared contracts. Do not have multiple agents edit the same scene. Otherwise use the map for focused single-agent work.

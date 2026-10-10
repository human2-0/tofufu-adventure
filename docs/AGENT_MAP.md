# Agent map

Start here, then read the applicable `AGENTS.md` scopes and only the feature needed.
This is a routing index, not an instruction to create agents. Every listed directory exists.

## Entry points

- `project.godot` → `game/app/bootstrap/launch.tscn`: illustrated landing, saves, lobby and pause; `adventure_loader.gd` defers world resources behind `ui/menu/loading_view.gd`, with `loading_readiness.gd` preserving early guest readiness; `launch_input.gd` applies menu and local-control state.
- `game/app/adventure/main.tscn`: the playable world; `main.gd` owns runtime callbacks and `adventure_setup.gd` constructs its dependencies in order.
- `game/app/bootstrap/dedicated_server.tscn`: explicit optional dedicated authority.
- `game/app/bootstrap/oracle_launch.tscn`: explicit Oracle client composition.
- `tools/check_architecture.py`: feature dependencies, 200-line runtime budget, resources and documentation links.
- `tools/verify.py`: import, rules, scene integration and local co-op checks.

## Runtime directories

First-level directories under `game/` are dependency boundaries. Subdirectories organize
responsibilities inside that feature; they do not permit new cross-feature dependencies.
Only `app/` wires unrelated features and networking.

| Feature / scope | Subdirectories and responsibilities |
| --- | --- |
| `game/app/` · `AGENTS.md` | `bootstrap/` lifecycle, connection, save/settings/lobby flows; `adventure/` scene root, setup and snapshots; `actors/` loadout/progression; `coop/` replicated actors, world, prediction, duel authority and scores; `inventory/` drops, focus, storage and merchant; `quests/` opening, mayor and dungeon; `world/` encounters, farming, weather and exploration; `presentation/` camera/weapon, map and chat composition |
| `game/player/` · `AGENTS.md` | Actor adapter, typed commands/sources, motor/tuning/placement, Fufu walk/charge/jump art, shadow, positional footsteps and dash ghost. Existing small feature stays together. |
| `game/combat/` · `AGENTS.md` | Shared tuning/health/vitals and weapon-model catalog at root; `melee/` attack lifecycle, sweep, pose, combos, clash, equipment and weapon visuals; `ranged/` soybean gun, recoil, projectiles and Sotjet; `abilities/` Nori plunge, Podburst and super-dash cloud; `enemies/` snails, ranged wild bees and factory beans; `targets/` dummies, harvestables, crates and bean pickups; `effects/` hit visuals; `state/` snapshot translation |
| `game/inventory/` · `AGENTS.md` | `items/` definitions, stacks, apparel and currency art; `state/` bag/equipment/chest contents; `rules/` transfers, exchange, healing and trade; `drops/` shared collision bodies/pool; `ui/` windows, layouts, slots and icon quality; `icons/` authored thumbnails |
| `game/world/` · `AGENTS.md` | `farm/` meadow scene, terrain, buildings, foliage, duel arena and spawn data; `factory/` Gigalopolis, factory shell, machinery and station displays; `biomes/{desert,frost,ocean,jungle,clouds,volcanic}/` each region's world/terrain/props; `river/` shared course, surface, fish and plants; `weather/` clock, wind, instanced rain/leaves, puddles, day/night and sky; `common/` geometry, outlines and reusable scenes |
| `game/ui/` · `AGENTS.md` | `hud/` HUD facade, layout, combat readouts, stats and skill widgets; `menu/` title/settings/saves/lobby, optional nickname editing, discovery pulse and shared vector menu icons; `map/` canvas, view and fog; `controls/` reticle and touch; `quests/` opening and dialogue views; `effects/` hit/set feedback; `weather/` forecast label |
| `game/session/` · `AGENTS.md` | Room lifecycle, bounded room messages, input window and actor/world protocol validation; no transport implementation |
| `game/farming/` | Crop rules and plot visuals |
| `game/quest/` | Opening follow-up quest and dungeon production rules |
| `game/progression/` | Per-character practice/EXP rules and authored tuning |
| `game/opening/` | Pod escape rules and nursery plant presentation |
| `game/camera/` | Assigned-target camera follow/orbit |
| `game/cartography/` | Personal visited-cell state |
| `game/chat/` | Bounded text/voice rules, composer/history, speech, recording and playback |
| `game/persistence/` | Versioned atomic save storage |
| `game/settings/` | Display preferences, saved local nickname and device bindings |

## Route a change

| Work | Read first | Focused verification (all under `tests/`) |
| --- | --- | --- |
| Scene wiring / lifecycle | `app/adventure/`, `app/bootstrap/` | `test_scene.gd`, `test_frontend.gd`, `test_coop_launch.gd` |
| Movement / collisions / running reserve | `player/AGENTS.md`, motor, `planar_movement.gd`, `run_endurance.gd`, player and placement; `app/world/terrain_locomotion.gd` | `test_player_motor.gd`, `test_heavy_movement.gd`, `test_actor_collisions.gd`, `test_jump.gd`, `preview_winter_movement.gd` |
| Art / held weapon / camera | `player/`, `combat/melee/`, `combat/ranged/`, `app/presentation/`, `assets/AGENTS.md` | `test_right_hand.gd`, `test_sword.gd`, `test_first_person.gd`, `test_soy_flight.gd`, `preview_right_hand.gd` and relevant `preview_*.gd` |
| Melee / guard / abilities | `combat/melee/`, `combat/abilities/` | `test_combat.gd`, `test_knife_combo.gd`, `test_melee_flow.gd`, `test_melee_clash.gd`, `preview_melee_flow.gd`, Nori/staff/Edamame tests |
| Ranged weapons | `combat/ranged/`, `app/actors/`, `app/presentation/` | `test_soy_gun.gd` (magazine, reload and ricochet), `test_soy_reload.gd`, `test_gun_run_pose.gd` (carry and aim), `test_sotjet.gd`, `test_sotjet_coop.gd`, `test_gun_recoil.gd` |
| Mobs / harvesting | `combat/enemies/` (snails and ranged wild bees; shared plated shell and bee meshes), `combat/targets/`, `app/world/sandbox_encounters.gd` | `test_snail.gd`, `test_armored_shell.gd`, `test_wild_bee.gd`, `test_coop_wild_bee.gd`, `test_meadow_meshes.gd`, `preview_meadow_meshes.gd`, `preview_wild_bee.gd`, `test_farm_combat.gd`, `test_sandbox.gd` |
| Breakable soybean growth / art | `combat/targets/harvest_prop.gd`, `soy_plant_visual.gd`, `soy_plant_geometry.gd`, `combat/state/encounter_state.gd` | `test_soy_plant.gd`, `preview_soy_plant.gd`, `test_sandbox.gd` |
| Inventory / equipment / drops | `inventory/`, `app/actors/actor_loadout.gd`, `app/inventory/` | `test_inventory.gd`, `test_loadout_shop.gd`, `test_world_items.gd`, `test_depot_focus.gd`, `test_backpack.gd` |
| HUD / menus | `ui/`, `app/bootstrap/` | `test_frontend.gd`, `test_landing.gd`, `test_lobby.gd`, `test_inventory_input.gd`, `preview_menu.gd`, `preview_frontend.gd`, `preview_controls.gd` |
| Weather / terrain / biomes | Relevant `world/` subdirectory, `world/weather/weather_particles.gd` (rain/leaves/snow), `app/world/weather_flow.gd`, `weather_exposure.gd` | `test_weather.gd`, `test_weather_exposure.gd`, `test_heavy_movement.gd`, `test_river.gd`, `test_sky.gd`, biome tests and `preview_winter_movement.gd` |
| Natural biome contours / islands / map terrain | `world/common/world_contours.gd`, `biome_palette.gd`, `terrain_grid.gd`, `world/biomes/ocean/ocean_islands.gd`, `app/presentation/map_terrain_image.gd` | `test_world_contours.gd`, `test_map.gd`, `preview_world_contours.gd` |
| Northern ocean / beach / underwater walking | `world/biomes/ocean/`, `app/world/ocean_experience.gd`, `app/world/terrain_locomotion.gd`, `player/player_motor.gd` | `test_ocean.gd`, `test_coop_ocean.gd`, `preview_ocean.gd` |
| Rendering budget / water / scenery culling | `world/common/terrain_chunks.gd`, `terrain_support.gd`, `ocean_material.gd`, `ocean_water.gdshader`, `scenery_instances.gd`, `static_decoration_batch.gd`, `decoration_mesh_bake.gd`, `solid_occlusion.gd`, `ground_occlusion.gd`, tree/grass LODs, `combat/enemies/mob_rest.gd`, `settings/resolution_budget.gd`, `app/bootstrap/render_budget.gd`; `docs/PERFORMANCE.md` | `test_render_budget.gd`, `test_occlusion.gd`, `test_scenery_batch.gd`, `test_mob_rest.gd`, `preview_occlusion.gd`, `benchmark_perspectives.gd`, `benchmark_rendering.gd`, `benchmark_coop_rendering.gd`, fixed `rendering_viewport.gd` (GPU/window required), `tools/check_render_budget.py`, full verifier |
| Grass density / bending / recovery | `world/farm/meadow_grass.gd`, `meadow_grass.gdshader`, `grass_imprint.gd`, `app/world/grass_response.gd` | `test_grass.gd`, `preview_grass.gd` |
| Reactive wildlife / movement feedback | `world/farm/meadow_birds.gd`, `world/weather/`, `app/world/world_life.gd`, `player/player_footsteps.gd` | `test_world_life.gd`, `test_player_motor.gd`, `preview_world_life.gd` |
| Jungle eastern coast | `world/biomes/jungle/jungle_coast.gd`, `jungle_terrain.gd`, `app/world/terrain_locomotion.gd`, `app/presentation/map_terrain_image.gd` | `test_jungle.gd`, `preview_cloud_realm.gd` |
| Jungle waterfall sanctuary | `world/biomes/jungle/jungle_waterfall.gd`, `waterfall_spray.gd`, `rainforest_wildlife.gd`, `rainforest_audio.gd`, `world/weather/sky_effects.gd`, `app/world/world_life.gd` | `test_waterfall.gd`, `test_jungle.gd`, `test_sky.gd`, `preview_waterfall.gd` |
| Grandma quests (legacy mayor state) | `opening/`, `quest/`, `app/quests/` | `test_pod_escape.gd`, `test_coop_opening.gd`, `preview_pod.gd` |
| Tofu Factory | `quest/tofu_dungeon_state.gd`, `app/quests/tofu_dungeon.gd`, `dungeon_stage.gd`, `dungeon_interaction.gd`, `world/factory/` | `test_tofu_dungeon_active.gd`, `test_tofu_dungeon_active_coop.gd`, `test_factory_route.gd`, `test_factory_recovery.gd`, `test_factory_handling.gd`, `test_factory_surfaces.gd`, `test_factory_reactivity.gd`, `test_factory_stashes.gd`; legacy fixtures: `test_tofu_dungeon.gd`, `test_tofu_dungeon_coop.gd` |
| Orchard and broadleaf tree art | `game/app/apple_harvest.gd`, `game/world/apple_tree.gd`, `game/world/common/natural_tree_visuals.gd`, `game/world/common/tree.tscn`, `game/app/inventory/apple_drop_visual.gd`, `game/app/coop/coop_apple_harvest.gd`, `game/app/coop/coop_world.gd` | `test_apple_trees.gd`, `test_apple_pickup.gd`, `test_coop_farming.gd`, `preview_apple_tree.gd`, `preview_natural_trees.gd` |
| Meadow village / barn / produce | `world/farm/meadow_village.gd`, `meadow_barn.gd`, `meadow_gardens.gd` (flowers, well, walnuts), `meadow_surfaces.gd`, `meadow_building_details.gd`, `meadow_machinery_details.gd`, `assets/environment/meadow/`, `meadow_village_ground.gd`, `meadow_resident_art.gd`, `meadow_hearth.gd`, `app/inventory/seed_storage.gd`, `barn_display.gd`, `app/world/meadow_harvest.gd`, `app/coop/coop_quests.gd` | `test_meadow_reorg.gd`, `test_meadow_meshes.gd`, `test_seed_storage.gd`, `test_coop_gameplay.gd`, `preview_meadow_reorg.gd`, `preview_meadow_meshes.gd` |
| Farming | `farming/`, `app/world/soybean_farming.gd`, `app/coop/coop_farming.gd` | `test_farming.gd`, `test_coop_farming.gd` |
| Co-op / protocols / character smoothness | `app/coop/` (replica motion and changed world views), `player/actor_presentation.gd`, `camera/`, `session/`, `networking/AGENTS.md`, `architecture/COOP.md` | `test_coop_protocol.gd`, `test_coop_gameplay.gd` (duel loop and equalized kit), `test_coop_response.gd`, `test_render_budget.gd`, `benchmark_coop_rendering.gd` |
| Chat / voice | `chat/`, `app/presentation/proximity_chat.gd`, `architecture/COOP.md` | `test_chat.gd`, `preview_chat.gd`; physical audio remains manual |
| Parrot transport | `world/biomes/jungle/parrot_art.gd`, `parrot_perches.gd`, `app/world/parrot_travel.gd`, `parrot_flight.gd`, `parrot_landing.gd`, `app/presentation/parrot_mount_view.gd`, `app/presentation/parrot_controls.gd`, `app/coop/coop_parrot_travel.gd`, `ui/map/parrot_travel_view.gd` | `test_parrot_travel.gd`, `test_coop_parrot_travel.gd`, `test_parrot_art.gd`, `preview_parrot.gd`, `preview_parrot_art.gd`, `preview_parrot_motion.gd`, `benchmark_parrot_rendering.gd` |
| Embercrown volcanic continent / castle maze | `world/biomes/volcanic/` (materials, carving details, maze, contextual signs and hidden treasure), `assets/environment/lava_castle/`, `lava_king_art.gd`, `assets/characters/lava_king/`, `app/world/volcanic_visit.gd`, `app/quests/castle/`, `quest/castle/`, `combat/castle/`, `ui/quests/castle/`, `session/castle_protocol.gd`, `castle_combat_protocol.gd`, `castle_treasure_protocol.gd`, `persistence/castle_save_validation.gd`, `castle_treasure_validation.gd`, `terrain_locomotion.gd`, parrot landing/perches and map terrain | `test_volcanic.gd`, `test_volcanic_expansion.gd`, `test_castle_stairs.gd`, `test_castle_adventure.gd`, `test_castle_challenge.gd`, `test_coop_castle.gd`, `test_lava_king_art.gd`, `preview_castle_challenge.gd`, `preview_castle_adventure.gd`, `preview_castle_surfaces.gd`, `preview_lava_king.gd`, `preview_volcanic.gd`, `test_map_exploration.gd`, `test_coop_parrot_travel.gd` |
| Cloud Realm / Godfufu | `world/biomes/clouds/` (terrain, textured Olympian temples/courtyards, batched ornaments and mist, court residents/angels), `app/world/cloud_realm_visit.gd`, `app/inventory/merchant_locations.gd`, `assets/characters/cloud_court/` (nine directional atlases), `cloud_sprite_catalog.gd`, `assets/environment/cloud_realm/`; parrot flight ceiling and elevated perch | `test_cloud_realm.gd`, `test_cloud_realm_art.gd`, `test_cloud_heaven.gd`, `test_coop_parrot_travel.gd`, `preview_cloud_realm.gd`, `preview_cloud_realm_art.gd`, `preview_cloud_heaven.gd` |
| Celestial armory / worn animation | `inventory/items/celestial_items.gd`, `player/celestial_fufu_art.gd`, `player/celestial_aura.gd`, `inventory/items/apparel_set_bonus.gd`, `app/presentation/actor_celestial_pose.gd`, `combat/celestial_combat.gd`, `celestial_weapon_model.gd`, `combat/models/`, `combat/ranged/celestial_raygun_view.gd`, `celestial_soy_ray.gd`; Nimbus stock, loadout, combat snapshots, world drops; `assets/characters/fufu/celestial/`, `assets/equipment/celestial/`, `assets/weapons/celestial/` | `test_celestial.gd`, `test_loadout_shop.gd`, `preview_celestial.gd`, `preview_celestial_game.gd` |
| Map | `cartography/`, `ui/map/`, `app/presentation/map_flow.gd` | `test_map.gd`, `test_map_exploration.gd` |
| Structure / guidelines | This map, `architecture/OVERVIEW.md`, affected scopes and `tools/` | Architecture checker and full verifier |

## Infrastructure, assets and tests

- `networking/AGENTS.md`: `godot/` transport contract and Holepunch adapter, `sidecar/` pinned Hyperswarm runtime, `oracle/` optional authenticated WebSocket adapter. Read `networking/README.md` and `networking/DEDICATED.md` for runtime setup.
- `deploy/oracle/` and `.github/workflows/oracle-deploy.yml`: explicit dedicated deployment; never an automatic gameplay fallback.
- `assets/AGENTS.md`: keep supplied source art and provenance. Characters, equipment, weapons, currency and factory art remain separate from game scripts.
- `tests/AGENTS.md`, `tests/README.md`: stable `test_*.gd` and `preview_*.gd` entry scripts. Search by feature name; do not load every scenario. Long end-to-end scenarios are not runtime scripts.
- `docs/AGENTS.md`: `architecture/OVERVIEW.md` records design decisions, `architecture/COOP.md` records authority/protocol limits, and `PLATFORMS.md` records controls/export constraints.

For explicitly requested parallel work, divide by feature ownership and give scene wiring,
resource moves and shared contracts one owner. Otherwise work within the mapped feature.

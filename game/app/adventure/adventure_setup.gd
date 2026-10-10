class_name AdventureSetup
extends RefCounted
## Ordered scene construction; runtime callbacks remain on the composition root.

static func actor(game: AdventureGame) -> void:
	game.player.relocated.connect(game.camera.reset_follow)
	game.chat = ProximityChat.new()
	game.chat.game = game
	game.add_child(game.chat)
	game.player.dash_cooldown_updated.connect(game.hud.show_dash_cooldown)
	game.player.jump_charge_updated.connect(game.hud.show_jump_charge)
	game.hud.show_dash_cooldown(game.player.motor.cooldown_remaining, game.player.tuning.dash_cooldown)
	game.combat = PlayerCombat.new()
	game.combat.actor = game.player
	game.add_child(game.combat)
	ActorWeaponHands.connect_visuals(game.player.visuals, game.combat)
	game.health = Damageable.new()
	game.health.maximum = game.combat.tuning.maximum_health
	game.health.body = game.player
	game.health.headshot_height = 0.78
	game.health.position.y = 0.55
	game.player.add_child(game.health)
	game.combat.owner_health = game.health
	game.combat.gun.owner_health = game.health
	game.combat.sotjet.flow.owner_health = game.health
	game.health.projectile_guard = game._reflect_projectile
	if not game.health.reflected_hit.is_connected(game.combat.gun.weapon_trained.emit):
		game.health.reflected_hit.connect(game.combat.gun.weapon_trained.emit)
	game.health.changed.connect(game.hud.show_health)
	game.health.depleted.connect(game._on_player_depleted)
	game.health.hit.connect(game._on_player_hit)
	game.health.hit.connect(ActorMeleeImpact.receive.bind(game.player, game.combat, game.health))
	game.health.restored.connect(game.player.motor.impact.clear)
	game.health.pushed.connect(game.player.apply_push)
	game.hud.show_health(game.health.current, game.health.maximum)
	game.player.command_sampled.connect(game._on_command)
	game.combat.charge_changed.connect(game.hud.show_charge)
	game.combat.combo_changed.connect(game.hud.show_combo)
	game.combat.gun.status_changed.connect(game.hud.show_gun_status)
	game.combat.equipment.changed.connect(game.hud.show_equipment)
	game.combat.equipment.punch_cadence_updated.connect(game.hud.show_punch_cadence)
	game.combat.struck.connect(game._on_strike)

static func inventory(game: AdventureGame) -> void:
	game.progression = ActorProgression.new()
	game.progression.actor = game.player
	game.progression.combat = game.combat
	game.progression.hud = game.hud
	game.add_child(game.progression)
	game.hud.stat_point_allocated.connect(game.progression.progress.allocate_stat)
	game.inventory = PlayerInventory.new()
	game.character_equipment = CharacterEquipment.new()
	game.progression.equipment = game.character_equipment
	game.character_equipment.wearer_level = game.progression.progress.level()
	game.loadout = ActorLoadout.new()
	game.loadout.combat = game.combat
	game.loadout.inventory = game.inventory
	game.loadout.equipment = game.character_equipment
	game.loadout.hud = game.hud
	game.add_child(game.loadout)
	game.loadout.seed()
	game.healing = PlayerHealing.new()
	game.healing.equipment = game.character_equipment
	game.healing.health = game.health
	game.healing.vitals = game.combat.vitals
	game.healing.eaten.connect(game._on_healing_eaten)
	game.healing.cooldown_updated.connect(game._on_healing_cooldown_updated)
	game.character_equipment.changed.connect(game._update_hud_healing)
	game.inventory_window = InventoryWindow.new()
	game.inventory_window.inventory = game.inventory
	game.inventory_window.equipment = game.character_equipment
	game.inventory_window.conversion_handler = func(slot: int, source_id: String) -> String: return CurrencyExchange.convert(game.inventory, slot, source_id)
	game.inventory_window.consume_handler = func(slot: int) -> bool: return game.healing.consume_from_bag(game.inventory, slot)
	game.add_child(game.inventory_window)
	game.world_items = WorldItems.new()
	game.world_items.game = game
	game.add_child(game.world_items)
	var inventory_controls := InventoryControls.new()
	inventory_controls.game = game
	game.add_child(inventory_controls)
	game.seed_storage = SeedStorage.new()
	game.seed_storage.game = game
	game.add_child(game.seed_storage)
	game.inventory_window.quick_transfer_handler = func(source: String, id: Variant) -> String: return game.seed_storage.quick_transfer(game.player, game.inventory, source, id)

static func encounters(game: AdventureGame) -> void:
	game.encounters = SandboxEncounters.new()
	game.encounters.player = game.player
	game.encounters.combat = game.combat
	game.encounters.health = game.health
	game.encounters.inventory = game.inventory
	game.encounters.shell_drop = game.world_items.spawn_mob_loot
	game.encounters.loot_chance = func(base: float, _at: Vector3) -> float: return ApparelSetBonus.drop_chance(game.character_equipment.complete_set(), base)
	game.encounters.experience_awarded.connect(game.progression.progress.award_experience)
	game.encounters.ground_point = game.world.ground_point
	game.encounters.mob_centers = FarmCombatGrounds.CAMPS
	game.encounters.dummy_positions = FarmCombatGrounds.DUMMIES
	game.encounters.protected_area = FarmCombatGrounds.VILLAGE
	game.add_child(game.encounters)
	game.encounters.progress_changed.connect(game.hud.show_progress)
	game.encounters.experience_changed.connect(game.hud.show_experience)
	game.encounters.populate()
	for tree in game.world.apple_trees:
		var target := Damageable.new()
		target.maximum = 1.0
		target.body = tree
		target.position.y = 1.1
		tree.add_child(target)
		tree.fruit_regrew.connect(_restore_apple_tree.bind(target))
		game.apple_tree_targets.append(target)
	game.meadow_harvest = MeadowHarvest.new()
	game.meadow_harvest.game = game
	game.add_child(game.meadow_harvest)
	game.player.super_dashed.connect(game._on_super_dashed)
	game.player.placement_peers.append(game.player)
	for mob in game.encounters.mob_nodes: game.player.placement_peers.append(mob)
	for mob in game.encounters.mob_nodes:
		mob.spawn_clearance = func(shape: CapsuleShape3D, at: Transform3D) -> bool:
			return not PlayerPlacement.overlaps_actors(mob, shape, at, game.player.placement_peers)

static func weather(game: AdventureGame) -> void:
	game.weather = WeatherCycle.new()
	game.add_child(game.weather)
	game.wind = WindField.new()
	game.player.movement_modifier = game.wind.movement_multiplier
	game.weather_view = WeatherView.new()
	game.add_child(game.weather_view)
	game.weather_particles = WeatherParticles.new()
	game.weather_particles.focus = game.player
	game.weather_particles.ground_point = WeatherExposure.precipitation_floor.bind(game)
	game.add_child(game.weather_particles)
	var weather_flow := WeatherFlow.new()
	weather_flow.focus = game.player
	weather_flow.atmosphere = game.weather_particles
	weather_flow.weather = game.weather
	weather_flow.cycle = game.cycle
	weather_flow.encounters = game.encounters
	weather_flow.view = game.weather_view
	weather_flow.ground = game.world.rain_effects
	weather_flow.wind = game.wind
	weather_flow.grass = game.world.grass_material
	game.add_child(weather_flow)
	var life := WorldLife.new()
	life.game = game
	game.add_child(life)

static func exploration(game: AdventureGame) -> void:
	game.exploration = ExplorationSites.new()
	game.exploration.explorer = game.player
	game.add_child(game.exploration)
	game.exploration.discovered.connect(game.hud.show_discovery)
	game.cycle.time_changed.connect(game.hud.show_time)
	game.shooting_view = ShootingView.new()
	game.shooting_view.game = game
	game.add_child(game.shooting_view)
	game.merchant = WeaponMerchant.new()
	game.merchant.game = game
	game.add_child(game.merchant)
	game.quest_giver = QuestGiver.new()
	game.quest_giver.game = game
	game.add_child(game.quest_giver)
	game.factory_dungeon = TofuDungeon.new()
	game.factory_dungeon.game = game
	game.add_child(game.factory_dungeon)
	game.map = MapFlow.new()
	game.map.game = game
	game.add_child(game.map)
	game.parrot_travel = ParrotTravel.new()
	game.parrot_travel.game = game
	game.add_child(game.parrot_travel)
	var volcanic_visit := VolcanicVisit.new()
	volcanic_visit.game = game
	game.add_child(volcanic_visit)
	game.castle_adventure = CastleAdventure.new()
	game.castle_adventure.game = game
	game.add_child(game.castle_adventure)
	var cloud_visit := CloudRealmVisit.new()
	cloud_visit.game = game
	game.add_child(cloud_visit)
	game.farming = SoybeanFarming.new()
	game.farming.game = game
	game.add_child(game.farming)
	for npc: Node3D in [game.world.quest_npc, game.world.weapon_merchant]:
		(npc.get_node("DirectionalArt") as MeadowResidentArt).view_focus = game.player
	var interiors := MeadowInteriorView.new()
	interiors.actor = game.player
	interiors.camera = game.camera
	interiors.buildings = game.world.interiors
	game.add_child(interiors)
	game.apple_harvest = AppleHarvest.new()
	game.apple_harvest.setup(game)
	game.add_child(game.apple_harvest)

static func _restore_apple_tree(target: Damageable) -> void:
	target.current = target.maximum
	target.invulnerability = 0.0

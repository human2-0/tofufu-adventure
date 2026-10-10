extends SceneTree
## Real Cloud Realm purchases, full equipment, snapshots, projectiles and art coverage.

var failures: int = 0
func _initialize() -> void: call_deferred("_run")
func check(ok: bool, message: String) -> void:
	if ok: return
	failures += 1
	printerr("FAIL: ", message)

func _run() -> void:
	var game := preload("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	await process_frame
	game.player.set_physics_process(false)
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	game.combat.set_process(false)
	_geometry()
	_art(game.player.visuals)
	game.player.position = game.world.weapon_merchant.global_position + Vector3(0, 0.1, 1.5)
	await physics_frame
	check(not game.merchant.purchase(game.player, game.inventory, "celestial_helmet").is_empty(), "ordinary shop cannot grant Cloud Realm gear")
	check(game.inventory.count_item("celestial_helmet") == 0, "rejected merchant purchase does not create an item")
	var nimbus: Node3D = game.world.cloud_realm.court.merchant
	game.player.position = nimbus.global_position + Vector3(0, 0.1, 1.5)
	await physics_frame
	check(MerchantLocations.nearest(game.world, game.player) == nimbus, "Nimbus can be approached in his royal armory")
	check(MerchantLocations.stock(game.world, nimbus).slice(0, 7) == CelestialItems.IDS, "Nimbus showcases his own celestial equipment first")
	for id in CelestialItems.IDS:
		var item := InventoryItem.from_id(id)
		check(item != null and item.icon != null and item.max_stack == 1, id + " has an item definition and generated icon")
		game.merchant.purchase(game.player, game.inventory, id)
		check(game.inventory.count_item(id) == 1, id + " enters the actual inventory")
	var helm := ItemStack.new(InventoryItem.apparel("celestial_helmet"), 1)
	check(not game.character_equipment.can_equip("helmet", helm), "existing level-five apparel gate is preserved")
	game.progression.progress.award_experience(CharacterProgress.threshold(5, true))
	for slot in CharacterEquipment.APPAREL_SLOTS:
		game.character_equipment.equip(slot, ItemStack.new(InventoryItem.apparel("celestial_" + slot), 1))
	check(game.character_equipment.complete_set() == "celestial" and game.player.visuals.worn_set == "celestial", "four worn pieces activate celestial art through real loadout wiring")
	check(is_equal_approx(game.health.armor_multiplier, 0.5), "full celestial set halves all received damage")
	_bonuses(game)
	var before: float = game.health.current
	game.health.damage(20.0)
	check(is_equal_approx(before - game.health.current, 10.0), "actual damage uses full-set armor")
	game.character_equipment.set_slot("boots", null)
	check(game.player.visuals.worn_set.is_empty() and is_equal_approx(game.health.armor_multiplier, 0.97), "removing a piece restores base animation and partial-piece protection")
	check(not game.player.visuals.celestial_aura.visible and is_equal_approx(game.combat.attack_speed_multiplier, game.progression.progress.attack_multiplier()), "partial gear removes aura and faster attack bonus")
	game.character_equipment.set_slot("boots", ItemStack.new(InventoryItem.apparel("celestial_boots"), 1))
	var restored := CharacterEquipment.new()
	restored.wearer_level = 5
	restored.restore(JSON.parse_string(JSON.stringify(game.character_equipment.capture())))
	check(restored.complete_set() == "celestial", "worn celestial pieces survive JSON checkpoint serialization")
	var replica := PlayerCombat.new()
	replica.actor = game.player
	replica.replica_view = true
	game.add_child(replica)
	game.shooting_view.cycle_mode()
	game.shooting_view.cycle_mode()
	_hidden_geometry(game.player.visuals)
	for kind in [1, 2, 3]:
		var id := CelestialCombat.item_id(kind)
		game.character_equipment.set_slot("combat_1", ItemStack.new(InventoryItem.weapon(id), 1))
		game.loadout.select(1)
		check(game.combat.equipment.celestial_weapon == kind, id + " selects its cosmetic combat variant")
		_hidden_geometry(game.combat.staff)
		if kind == 2:
			game.combat.staff.present(Transform3D.IDENTITY)
			check(game.combat.staff._model.to_global(Vector3(0, 1.136, 0)).distance_to(Vector3(0, 0, -game.combat.tuning.staff_length)) < 0.02, "celestial staff tip matches its authoritative reach")
			check(game.combat.staff.model_grip_position().distance_to(Vector3(0, 0, game.combat.tuning.grip_length)) < 0.02, "celestial staff source grip meets the real palm")
		var state := CombatState.capture(game.combat)
		check(ExplorationProtocol.combat(state), id + " produces a valid co-op combat snapshot")
		var json_state: Dictionary = JSON.parse_string(JSON.stringify(state))
		CombatState.present(replica, json_state, Vector2.DOWN)
		check(replica.equipment.celestial_weapon == kind and replica.gun.celestial == (kind == 3), id + " appears correctly on a cosmetic peer")
		CombatState.restore(replica, json_state)
		check(replica.equipment.celestial_weapon == kind, id + " survives combat checkpoint restore")
		var invalid := json_state.duplicate(true)
		invalid.celestial = 4
		check(not ExplorationProtocol.combat(invalid), "out-of-range celestial variant is rejected")
		invalid.celestial = kind
		invalid["selected" if kind == 1 else ("staff" if kind == 2 else "gun")] = false
		check(not ExplorationProtocol.combat(invalid), "unequipped celestial variant is rejected")
		check(ItemStack.restore(ItemStack.new(InventoryItem.weapon(id), 1).capture()).item.id == id, id + " retains its identity in inventory saves")
	game.combat.gun.step(true, true, Vector2.DOWN, game.player.global_position + Vector3(0, 0.6, 20), 0.016)
	var projectiles: Array[Node] = game.combat.gun.get_children().filter(func(node: Node) -> bool: return node is SoyProjectile)
	check(projectiles.size() == 1 and (projectiles[0] as SoyProjectile).celestial and (projectiles[0] as SoyProjectile).authoritative, "raygun fires one real authoritative celestial projectile")
	check(game.combat.gun.magazine == 8, "raygun keeps the existing nine-shot magazine")
	var pool: WorldItemPool = game.world_items.pool
	for id in CelestialItems.IDS:
		var drop := pool.spawn_at(id, 1, 100, game.player.global_position + Vector3(0, 1, 2))
		check(drop != null and drop.get_child_count() >= 3, id + " builds a visible world pickup")
	check(WorldProtocol.world_items(pool.capture()), "celestial drops survive bounded world snapshot validation")
	await create_timer(0.5).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("Celestial equipment and art: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures > 0 else 0)

func _geometry() -> void:
	var model := CelestialWeaponModel.new()
	model.kind = 2
	root.add_child(model)
	for child: Node in model.get_children():
		if child is MeshInstance3D:
			check(child.mesh != null and child.mesh.get_surface_count() > 0, "celestial model builds every solid panel and feather")
	model.queue_free()

func _bonuses(game: AdventureGame) -> void:
	var progress: CharacterProgress = game.progression.progress
	check(is_equal_approx(game.combat.sword_damage_multiplier, progress.damage_multiplier("sword") * 1.25), "sword, staff and ability damage gain twenty-five percent")
	check(is_equal_approx(game.combat.fist_damage_multiplier, progress.damage_multiplier("fist") * 1.25), "unarmed damage gains twenty-five percent")
	check(is_equal_approx(game.combat.gun.damage_multiplier, progress.damage_multiplier("shooting") * 1.25) and is_equal_approx(game.combat.sotjet.flow.damage_multiplier, progress.damage_multiplier("shooting") * 1.25), "both ranged paths gain twenty-five percent damage")
	for speed: float in [game.combat.attack_speed_multiplier, game.combat.gun.attack_speed_multiplier, game.combat.sotjet.attack_speed_multiplier]:
		check(is_equal_approx(speed, progress.attack_multiplier() * 1.25), "all attack rates gain twenty-five percent")
	var flow: SotjetFlow = game.combat.sotjet.flow
	check(is_equal_approx(flow.attack_cadence_multiplier, 1.25), "continuous Soyjet damage ticks also gain twenty-five percent attack cadence")
	var target: Damageable = game.encounters.dummy_nodes[0].target
	flow._hit_until.clear()
	flow._clock = 1.0
	flow._impact({"collider": target.body, "position": target.global_position, "normal": Vector3.UP}, Vector3.ZERO)
	check(is_equal_approx(flow._hit_until[target.get_instance_id()] - flow._clock, flow.tuning.damage_interval / 1.25), "actual stream hit interval is reduced to eighty percent")
	for kind in Damageable.HitKind.values():
		game.health.invulnerability = 0.0
		var before: float = game.health.current
		game.health.damage(2.0, Vector3.ZERO, kind)
		check(is_equal_approx(before - game.health.current, 1.0), "every damage kind receives half protection")
	check(game.player.visuals.celestial_aura.visible and game.player.visuals.celestial_aura.get_child_count() == 11, "complete outfit activates bounded rings and eight motes")
	check(is_equal_approx(ApparelSetBonus.drop_chance("celestial", 0.1), 0.11) and ApparelSetBonus.drop_chance("celestial", 1.0) == 1.0, "luck increases arbitrary drop chances by ten percent and preserves guaranteed loot")
	var mob := ArmoredSnail.new()
	game.add_child(mob)
	mob.set_physics_process(false)
	var drops: Array[String] = []
	var drop_callback: Callable = game.encounters.shell_drop
	game.encounters.shell_drop = func(id: String, _at: Vector3) -> void: drops.append(id)
	game.encounters.shell_drop_roll = func() -> float: return 0.105
	game.encounters._mob_defeated(game.player.global_position, mob)
	check(drops == ["piece_of_shell"], "real loot roll succeeds in the celestial bonus interval")
	game.character_equipment.set_slot("boots", null)
	game.encounters._mob_defeated(game.player.global_position, mob)
	check(drops.size() == 1, "the same loot roll fails without the complete set")
	game.character_equipment.set_slot("boots", ItemStack.new(InventoryItem.apparel("celestial_boots"), 1))
	game.encounters.shell_drop = drop_callback
	game.encounters.shell_drop_roll = func() -> float: return randf()
	var party_loot := CoopEncounters.new()
	var member := CoopActor.new()
	member.actor = game.player
	member.character_equipment = game.character_equipment
	party_loot.party["wearer"] = member
	check(is_equal_approx(party_loot._loot_chance(0.1, game.player.global_position), 0.11), "host derives guest loot luck from that actor's equipped set")
	party_loot.free()
	member.free()
	mob.queue_free()

func _hidden_geometry(node: Node) -> void:
	if node is GeometryInstance3D:
		check(node.layers == 0, "replacing celestial staff preserves first-person body masking")
	for child: Node in node.get_children(): _hidden_geometry(child)

func _art(sprite: FufuVisuals) -> void:
	sprite.worn_set = "celestial"
	var context := sprite.celestial_pose
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CelestialFufuArt.DIRECTORY + "sprite-layout.json"))
	var expected := {"idle": 1, "walk": 4, "charge": 4, "dash": 4, "jump": 10, "windup": 1, "cut": 1, "thrust": 1, "guard": 1, "aim": 1, "reload": 1, "hurt": 1, "riding": 1}
	var count: int = 0
	for action: String in expected:
		check(layout.has(action) and layout[action].size() == 8, action + " covers all eight directions")
		for facing in 8:
			check(layout[action][str(facing)].size() == expected[action], "%s facing %d has every phase" % [action, facing])
			for phase in int(expected[action]):
				sprite.celestial_art.apply(sprite, facing, action, phase)
				var view := sprite.texture as AtlasTexture
				check(view != null and Rect2(Vector2.ZERO, view.atlas.get_size()).encloses(view.region), "source frame stays inside its original atlas")
				check(not sprite.flip_h and Rect2(Vector2.ZERO, sprite.texture.get_size()).has_point(FufuRightHand.point(sprite)), "authored anatomical wrist stays inside a true directional view")
				var feet: float = sprite.offset.y + sprite.texture.get_height() * 0.5 + 0.56 / sprite.pixel_size
				check(absf(feet - float(layout[action][str(facing)][phase].feet)) < 0.1, "feet remain on the actor baseline")
				count += 1
	check(count == 248, "complete outfit covers 248 distinct authored sprite frames")
	sprite.worn_set = "celestial"
	var command := PlayerCommand.new()
	command.aim = Vector2.DOWN
	sprite.present(command, Vector3.ZERO, true, false, 0.016, 0.5)
	check(sprite.celestial_art.action == "charge", "charged jumps keep celestial armor")
	sprite.present(command, Vector3(0, 4, 0), false, false, 0.016)
	check(sprite.celestial_art.action == "jump", "airborne movement keeps celestial armor")
	sprite.present(command, Vector3.ZERO, true, true, 0.016)
	check(sprite.celestial_art.action == "dash", "dash selects the celestial dash frames")
	sprite.celestial_pose = func() -> Dictionary: return {"action": "riding"}
	sprite.present(command, Vector3.ZERO, false, false, 0.016)
	check(sprite.celestial_art.action == "riding", "mounted movement selects seated celestial art")
	sprite.celestial_pose = context
	sprite.worn_set = ""
	sprite.jump_animation.reset()
	sprite._set_frame(false)

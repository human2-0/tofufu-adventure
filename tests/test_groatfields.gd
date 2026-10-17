extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.player.set_physics_process(false)
	game.weather.set_physics_process(false)
	for mob in game.encounters.mob_nodes: mob.set_physics_process(false)
	check(game.encounters.mob_nodes.size() == WorldProtocol.CURRENT_MOB_COUNT, "encounter roster matches the shared protocol")
	var quest := game.quest_giver.quest
	game.encounters.angel_defeated.emit(Vector3.ZERO)
	check(quest.god_count == 0, "kills before acceptance do not count")
	game.player.position = game.world.cloud_realm.godfufu.global_position + Vector3(0, 0, 2)
	await physics_frame
	game.camera.position = game.player.position + Vector3(0, 5, 8)
	game.camera.look_at(game.world.cloud_realm.godfufu.global_position + Vector3.UP)
	WorldInteractionFocus.select_focus(game.world_items, game.shooting_view.local_input)
	check(game.world_items.focused_kind == "god_quest", "Godfufu participates in the real interaction focus")
	game.god_hunt._action("accept")
	check(quest.god_status == QuestState.Status.IN_PROGRESS, "accept at Godfufu")
	game.encounters.mob_defeated.emit(Vector3.ZERO)
	check(quest.god_count == 0, "other mobs do not count")
	for i in 199: game.encounters.angel_defeated.emit(Vector3.ZERO)
	check(not quest.claim_god(), "cannot claim early")
	var saved := quest.capture()
	var restored := QuestState.new()
	restored.restore(saved)
	check(restored.god_count == 199 and GrandmaQuestProtocol.valid(saved), "hunt roundtrips through validated character schema")
	game.encounters.angel_defeated.emit(Vector3.ZERO)
	var before := game.progression.progress.experience
	game.god_hunt._action("claim")
	check(game.progression.progress.experience == before + 50000, "exact 50k experience")
	check(game.inventory.count_item("golden_tofu_chunk") == 10, "exact ten golden chunks")
	game.god_hunt._action("claim")
	check(game.progression.progress.experience == before + 50000 and game.inventory.count_item("golden_tofu_chunk") == 10, "reward cannot repeat")
	var legacy := saved.duplicate()
	legacy.erase("god_status")
	legacy.erase("god_count")
	check(GrandmaQuestProtocol.valid(legacy), "legacy quests still load")
	var invalid := saved.duplicate()
	invalid.god_count = 201
	check(not GrandmaQuestProtocol.valid(invalid), "out of range quest rejected")
	for i in range(43, 55):
		var archer := game.encounters.mob_nodes[i] as TofufuArcher
		check(archer != null and archer.target.maximum == 420, "level twenty archer health")
		check(is_equal_approx((archer._collider.shape as CapsuleShape3D).height, 1.8) and archer.shot_height == 1.2, "archer capsule and bow origin match tall sprite")
		archer.set_rain(true)
		check(archer.target.current == 420, "weather does not weaken archers")
		archer.set_rain(false)
		var at := archer.position
		check(absf(at.y - game.world.ground_point(at.x, at.z).y - 0.1) < 0.01, "spawn follows authored terrain")
		var ray := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 5, at - Vector3.UP * 5, 1)
		var hit := game.get_world_3d().direct_space_state.intersect_ray(ray)
		check(not hit.is_empty() and absf(hit.position.y - (at.y - 0.1)) < 0.03, "collision matches ground")
	var archer := game.encounters.mob_nodes[43] as TofufuArcher
	game.player.position = archer.position + Vector3.BACK * 6
	archer.quarry = game.player
	_wandering_facings(game, archer)
	_eight_views(game, archer)
	archer._choose_direction(0.01)
	check(archer._windup == 0.9, "readable bow telegraph")
	var locked := archer._sting_aim
	game.player.position.x += 3
	archer._choose_direction(0.91)
	check(archer.sting.active and archer.sting.velocity.normalized().distance_to(locked) < 0.01, "locked groat aim permits sidestepping")
	check(is_equal_approx(archer.sting.velocity.length(), 32.0) and is_equal_approx(archer.sting.remaining, 0.75), "groats fly twice as fast with unchanged travel distance")
	await _shot_collisions(game, archer)
	var world := CoopWorld.capture(game)
	check(WorldProtocol.valid(world), "expanded authoritative world validates")
	var invalid_flight := world.duplicate(true)
	invalid_flight.mobs[43][14] = 33.0
	check(not WorldProtocol.valid(invalid_flight), "angel speed above the new bound is rejected")
	invalid_flight = world.duplicate(true)
	invalid_flight.mobs[39][14] = 32.0
	check(not WorldProtocol.valid(invalid_flight), "ordinary bee shots retain their original speed bound")
	var legacy_flight := world.duplicate(true)
	legacy_flight.mobs[43][14] = 16.0
	legacy_flight.mobs[43][15] = 0.0
	legacy_flight.mobs[43][16] = 0.0
	legacy_flight.mobs[43][17] = 1.5
	check(WorldProtocol.valid(legacy_flight), "older slower saved groat flights remain valid")
	var before_exp := game.encounters.experience
	archer.target.damage(9999)
	check(game.encounters.experience == before_exp + 450, "grinding EXP per kill")
	check(not archer.sting.active and archer._respawn == 18, "death clears projectile and enables renewable hunt")
	for x in [-40.0, 0.0, 40.0]:
		check(game.world.jungle.point(x, 340).distance_to(game.world.groatfields.point(x, 340)) < 0.01, "continuous jungle seam")
	var level_twenty := game.progression.progress.capture()
	level_twenty.experience = CharacterProgress.threshold(20, true)
	game.progression.progress.restore(level_twenty)
	game.health.restore()
	game.health.invulnerability = 0
	var unarmored := game.health.current
	game.encounters._bee_stung(game.player, 88, game.player.position - Vector3.BACK, archer)
	var naked_damage := unarmored - game.health.current
	for slot in ["helmet", "armor", "legs", "boots"]:
		game.character_equipment.equip(slot, ItemStack.new(InventoryItem.apparel("celestial_" + slot), 1))
	game.health.restore()
	game.health.invulnerability = 0
	var armored := game.health.current
	game.encounters._bee_stung(game.player, 88, game.player.position - Vector3.BACK, archer)
	var celestial_damage := armored - game.health.current
	check(game.progression.progress.level() == 20 and game.character_equipment.complete_set() == "celestial", "recommended level and set compose correctly")
	check(naked_damage > 0 and is_equal_approx(celestial_damage * 2, naked_damage), "celestial set halves real groat damage")
	var tuning := CharacterProgress.TUNING
	var level := game.progression.progress.level()
	var defence := game.progression.progress.effective_defence()
	var expected := 88.0 * maxf(0.2, 1.0 / (1.0 + tuning.character_defence * (level - 1) + tuning.defence_reduction * (defence - 1))) * 0.5
	check(is_equal_approx(celestial_damage, expected) and celestial_damage > 0 and celestial_damage < armored * 0.25, "groat damage follows stronger level defence and outfit protection")
	game.queue_free()
	await process_frame
	print("Groatfields: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _wandering_facings(game: AdventureGame, archer: TofufuArcher) -> void:
	var player_at := game.player.position
	game.player.position = archer.position + Vector3.BACK * 40
	archer._destination = archer.position + Vector3.LEFT * 2
	archer._timer = 1.0
	var travel := archer._choose_direction(0.01)
	check(travel.dot(Vector3.LEFT) > 1 and archer.facing.dot(Vector3.LEFT) > 0.99, "wander faces travel instead of the distant player")
	archer.velocity = travel
	archer._present_visual(Vector3.BACK * 40, 0.1)
	check(archer.facing.dot(Vector3.LEFT) > 0.99, "presentation cannot overwrite authoritative travel facing")
	archer._destination = archer.position
	archer._choose_direction(0.01)
	check(archer.facing.dot(Vector3.LEFT) > 0.99, "idle wandering retains the last travel facing")
	archer.velocity = Vector3.ZERO
	game.player.position = player_at

func _eight_views(game: AdventureGame, archer: TofufuArcher) -> void:
	var forward := game.camera.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := Vector3(forward.z, 0, -forward.x)
	for index in 8:
		var angle := index * PI / 4
		var facing := forward * cos(angle) - right * sin(angle)
		archer.art.present(facing, 0, 0, true)
		check(archer.art.direction_index == index, "eight observer-relative walking directions")
		check(archer.art.flip_h == (index in [1, 2, 3]), "left-facing views mirror the matching right views")
		check((archer.art.texture as AtlasTexture).filter_clip, "isolated frames prevent neighbouring sprite bleed")
	archer.art.elapsed = 0.01
	archer.art.present(forward, 0, 0, true)
	check(archer.art.walk_phase == 0, "first walking stride")
	archer.art.present(forward, 0, 0.18, true)
	check(archer.art.walk_phase == 1, "second walking stride")
	archer.art.present(forward, 0.9, 0)
	check((archer.art.texture as AtlasTexture).atlas == ArcherVisuals.BOW, "bow draw retains the original authored attack art")

func _shot_collisions(game: AdventureGame, archer: TofufuArcher) -> void:
	var enemy_at := archer.position
	var player_at := game.player.position
	var health := game.health.current
	archer.position = Vector3(200, 20, 100)
	game.player.position = archer.position + Vector3.BACK * 6
	await physics_frame
	await physics_frame
	var start := archer.position + Vector3.UP * archer.shot_height
	var aim := (game.player.position + Vector3.UP * 0.7 - start).normalized()
	var impacts: Array[Vector3] = []
	var contact := func(victim: Node3D, source: Vector3) -> void:
		if victim == game.player: impacts.append(source)
	archer.sting.struck.connect(contact)
	for speed in [32.0, 16.0]:
		game.health.current = game.health.maximum
		game.health.invulnerability = 0
		var motion: Vector3 = aim * speed
		# The slower flight emulates an old saved projectile on the new client.
		archer.sting.apply([start.x, start.y, start.z, motion.x, motion.y, motion.z, 24.0 / speed])
		archer.sting.step(0.08, archer.protected_area, archer.get_rid())
		archer.sting.step(6.2 / speed - 0.08, archer.protected_area, archer.get_rid())
		check(not archer.sting.active and game.health.current < game.health.maximum, "fast and saved groats sweep into real actor collision")
	check(impacts.size() == 2 and impacts.all(func(at: Vector3) -> bool: return at.distance_to(start) < 0.01), "both flight speeds preserve the original damage source for guarding")
	archer.sting.struck.disconnect(contact)
	archer.position = enemy_at
	game.player.position = player_at
	game.health.current = health
	archer.sting.launch(enemy_at + Vector3.UP * archer.shot_height, aim)

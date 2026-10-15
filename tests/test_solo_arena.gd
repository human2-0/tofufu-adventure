extends SceneTree
## Real solo arena lifecycle, loans/checkpoints, attacks, cover and eight-way art.

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", label)

func ticks(count: int) -> void:
	for tick in count:
		await physics_frame
		await process_frame

func _run() -> void:
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	await ticks(2)
	game.encounters.set_physics_process(false)
	for mob in game.encounters.mob_nodes: mob.set_physics_process(false)
	check(game.player.relocate(game.world.duel_arena.pad_positions()[0] + Vector3.UP * 0.5), "fixture can stand on the raised gate tile")
	await ticks(2)
	var arena := game.solo_arena
	check(arena.phase == "invite" and arena.panel.challenge.visible, "solo option appears at a gate tile")
	game.health.current = 37.0
	game.combat.gun.magazine = 3
	game.combat.vitals.current = 43.0
	game.healing.apple_duration_remaining = 20.0
	game.player.motor.cooldown_remaining = 0.7
	var old := AdventureSnapshot.capture(game, "Before", 0.0)
	arena.start()
	if not is_instance_valid(arena.boss):
		printerr("FAIL: boss could not start at ", game.player.global_position)
		quit(1)
		return
	check(arena.phase == "entry" and arena.boss.target.maximum == 2400.0, "challenge creates one powerful boss and countdown")
	check(game.health.maximum == 180.0 and game.loadout.has_equipped("celestial_sword") and game.loadout.has_equipped("soy_raygun"), "match grants explicit temporary weapons and health")
	var command := PlayerCommand.new()
	command.move = Vector2.RIGHT
	command.jump_pressed = true
	command.dash_pressed = true
	command.attack_held = true
	command.drop_pressed = true
	command.pickup_pressed = true
	command.use_healing_1 = true
	arena.prepare(command)
	check(command.move.is_zero_approx() and not command.jump_pressed and not command.dash_pressed and not command.attack_held, "countdown blocks movement and attacks before motor sampling")
	check(not command.drop_pressed and not command.pickup_pressed and not command.use_healing_1, "loans cannot be dropped and consumables cannot be spent")
	await ticks(3)
	var head_point := arena.boss.global_position + Vector3.UP * 1.9
	var head_query := PhysicsRayQueryParameters3D.create(head_point + Vector3.RIGHT * 3.0, head_point, 2, [game.player.get_rid()])
	var head_hit := arena.boss.get_world_3d().direct_space_state.intersect_ray(head_query)
	check(not head_hit.is_empty() and head_hit.collider == arena.boss and arena.boss.target.is_headshot(head_point), "new sprite's visible head has a hittable headshot region")
	check(game.healing.apple_duration_remaining == 20.0, "pre-existing healing buff freezes for the challenge")
	var checkpoint := AdventureSnapshot.capture(game, "During", 12.0)
	for field in SoloArenaFighter.SAVE_FIELDS:
		check(checkpoint[field] == old[field], "save retains original actor field: " + field)
	check(checkpoint.seconds == 12.0, "current world save metadata survives actor overlay")
	arena.remaining = 0.0
	await ticks(1)
	check(arena.phase == "fight" and arena.boss.running, "countdown starts live boss simulation")
	var boss := arena.boss
	boss.set_physics_process(false)
	var floor_y := game.world.duel_arena.spawn_positions()[0].y
	boss.global_position = Vector3(55.0, floor_y + 0.15, 39.5)
	game.player.global_position = boss.global_position + Vector3(2.0, 0, 0)
	await ticks(2)
	game.health.invulnerability = 0.0
	game.combat.equipment.guarding = false
	boss.committed = Vector3.RIGHT
	boss.facing = Vector3.RIGHT
	boss.rules.skill = DofufuRules.Skill.GLAIVE
	var health_before := game.health.current
	boss._execute()
	check(game.health.current < health_before, "committed glaive hits an exposed nearby player")
	game.health.invulnerability = 0.0
	health_before = game.health.current
	game.player.motor.is_dashing = true
	arena._hurt(40.0, boss.global_position, Vector3.RIGHT * 7.0)
	check(game.health.current == health_before, "dash immunity applies to boss hits")
	game.player.motor.is_dashing = false
	game.player.set_physics_process(false)
	game.combat.equipment.guarding = true
	game.combat.equipment.facing = Vector2.LEFT
	game.combat.vitals.current = 100.0
	var blade := DofufuBlade.new()
	blade.shooter = boss
	blade.victim = game.health
	blade.boss_health = boss.target
	blade.hurt = arena._hurt
	blade.velocity = Vector3.RIGHT * 19.0
	boss.add_child(blade)
	blade.global_position = boss.global_position + Vector3(0.6, 0.8, 0)
	blade.set_physics_process(false)
	blade._physics_process(0.1)
	check(blade.reflected and blade.velocity.x < 0.0 and game.combat.vitals.current == 78.0, "directional sword guard reflects a blade and pays stamina")
	var boss_hp := boss.target.current
	blade._physics_process(0.1)
	check(boss.target.current == boss_hp - 44.0, "reflected blade can damage its shooter")
	game.combat.equipment.guarding = false
	game.player.set_physics_process(true)
	game.health.invulnerability = 0.0
	game.player.global_position = boss.global_position + Vector3(2.0, 2.0, 0)
	boss.rules.skill = DofufuRules.Skill.SLAM
	health_before = game.health.current
	boss._execute()
	check(game.health.current == health_before, "jump above the slam avoids its ground damage")
	game.player.global_position = Vector3(61.0, floor_y + 0.15, 33.0)
	boss.global_position = Vector3(55.0, floor_y + 0.15, 33.0)
	await ticks(2)
	check(not boss._clear_line(boss.global_position, game.health.global_position), "full crate blocks boss damage line")
	var route := arena.navigation.next(boss.global_position, game.player.global_position)
	check(route.distance_to(boss.global_position) > 1.0 and route != game.player.global_position, "navigation finds a detour around the crate")
	game.player.set_physics_process(false)
	game.player.global_position = game.world.duel_arena.spawn_positions()[0] + Vector3.UP * 0.15
	boss.global_position = game.world.duel_arena.spawn_positions()[1] + Vector3.UP * 0.15
	game.health.invulnerability = 100.0
	boss.running = true
	boss.rules.recovery = 10000.0
	for tick in 1800: boss._physics_process(0.05)
	if boss.global_position.distance_to(game.player.global_position) >= 8.0:
		printerr("ROUTE DEBUG: boss=", boss.global_position, " destination=", boss._destination, " next=", arena.navigation.next(boss.global_position, game.player.global_position))
	check(boss.global_position.distance_to(game.player.global_position) < 8.0, "boss crosses the cover-filled arena instead of sticking at spawn")
	boss.clear_attacks()
	await ticks(1)
	game.player.set_physics_process(true)
	boss.rules.enraged = true
	boss.rules.skill = DofufuRules.Skill.FAN
	boss._execute()
	var blades: int = 0
	for child in boss.get_children():
		if child is DofufuBlade: blades += 1
	check(blades == 7, "second phase produces seven bounded returning blades")
	var art := boss.art
	var camera := game.camera
	var back := camera.global_basis.z
	back.y = 0.0
	back = back.normalized()
	for direction in 8:
		art.present(back.rotated(Vector3.UP, -direction * PI / 4.0), false, false, false, 0.0)
		check(art.pose_index == direction, "idle has independent directional frame %d" % direction)
		art.present(back.rotated(Vector3.UP, -direction * PI / 4.0), false, true, false, 0.0)
		check(art.pose_index == direction + 8, "weapon pose has independent directional frame %d" % direction)
	arena.finish("TEST SURRENDER")
	check(game.player.motor.cooldown_remaining == 0.7, "original dash cooldown is restored")
	await ticks(1)
	check(arena.phase == "complete" and not game.player.command_filter.is_valid(), "surrender ends boss and removes input filter")
	check(game.character_equipment.capture() == old.equipment and game.inventory.capture() == old.inventory, "original equipment and inventory restored")
	check(game.combat.gun.magazine == 3 and game.health.current >= 37.0 and game.health.maximum == game.combat.tuning.maximum_health, "original magazine and health restored")
	check(game.world.duel_arena.pad_for(game.player.global_position) >= 0, "fighter returns to gate")
	arena.remaining = 0.0
	await ticks(1)
	arena.start()
	arena.remaining = 0.0
	await ticks(1)
	game.health.invulnerability = 0.0
	game.health.damage(10000.0)
	check(arena.phase == "complete" and game.health.current > 0.0, "fatal defeat restores actor instead of world death drops")
	check(game.character_equipment.capture() == old.equipment, "defeat preserves original items")
	arena.remaining = 0.0
	await ticks(1)
	arena.start()
	arena.boss.target.damage(10000.0)
	check(arena.phase == "complete" and arena._result.begins_with("VICTORY"), "boss defeat completes once with victory")
	arena.enabled = false
	arena.phase = "idle"
	arena.start()
	check(arena.phase == "idle", "solo simulation cannot start in disabled co-op composition")
	game.queue_free()
	await process_frame
	print("Solo arena: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

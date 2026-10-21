extends SceneTree
## Native render of actual adventure weapon components on embedded Tofufu skins.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	GamePreferences.install_translations(self)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	var room := BattleRoom.new()
	root.add_child(room)
	room.practice()
	var game := BattleRoyaleGame.new()
	game.room = room
	root.add_child(game)
	while not game.composed: await physics_frame
	BattleTestDeployment.finish(game)
	game.set_physics_process(false)
	game.match_state.time = 14
	var center := game.world.ground_point(-22, -22, 0.1)
	for slot in 20:
		var at := center + Vector3((slot % 4 - 1.5) * 3, 0, (slot / 4) * 3)
		game.bodies[slot].position = game.world.ground_point(at.x, at.z, 0.1) if slot < 8 else center + Vector3(60 + slot, 0, 0)
		var row: Array = game.match_state.rows[slot]
		for axis in 3: row[axis] = game.bodies[slot].position[axis]
	var choices: Array[int] = [2, 3, 4, 6, 8, 7, 5, 11]
	for slot in choices.size():
		var kind := choices[slot]
		var row: Array = game.match_state.rows[slot]
		row[22 if kind in BattleGear.MELEE else 23] = kind
		row[10] = kind
		game.combat.fighters[slot].equip(row)
	game.camera.target = game.bodies[1]
	game.camera.reset_follow()
	for tick in 30:
		for slot in 8:
			var command := PlayerCommand.new()
			command.aim = Vector2.DOWN
			command.aim_point = game.bodies[slot].position + Vector3(0, 0.65, 12)
			command.attack_held = slot in [0, 5, 7] or (slot == 1 and tick < 8)
			command.guard_held = slot in [0, 4, 5, 7]
			game.combat.fighters[slot].step(command, 1.0 / 60)
			game.bodies[slot].visuals.present(command, Vector3.ZERO, true, false, 1.0 / 60)
		game.combat.capture()
		await physics_frame
	for locale in ["en", "pl"]:
		TranslationServer.set_locale(locale)
		game._update_hud()
		for frame in 4: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.codex/visualizations/2026/10/20/battle-adventure/weapons-%s.png" % locale)
	game.queue_free()
	room.queue_free()
	await process_frame
	quit()

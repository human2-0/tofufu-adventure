extends SceneTree
## Native rendering of every pose, arena invitation and committed boss attack.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 900)
	var gallery := Node3D.new()
	root.add_child(gallery)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 13.8
	gallery.add_child(camera)
	camera.position = Vector3(0, 4.5, 20)
	camera.look_at(Vector3(0, 4.5, 0))
	for pose in 16:
		var art := DofufuVisuals.new()
		gallery.add_child(art)
		art.position = Vector3((pose % 4 - 1.5) * 3.3, 9.6 - floorf(pose / 4.0) * 3.0, 0)
		art.set_pose(pose)
		var label := Label3D.new()
		label.text = ["S", "SW", "W", "NW", "N", "NE", "E", "SE"][pose % 8] + (" · weapon" if pose >= 8 else " · idle")
		label.position = art.position + Vector3(0, -1.55, 0)
		label.font_size = 24
		label.pixel_size = 0.014
		gallery.add_child(label)
	await _capture("directions")
	gallery.queue_free()
	await process_frame
	root.size = Vector2i(1280, 720)
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	for mob in game.encounters.mob_nodes: mob.set_physics_process(false)
	game.player.relocate(game.world.duel_arena.pad_positions()[0] + Vector3.UP * 0.5)
	await _capture("gate")
	game.shooting_view.cycle_mode()
	game.shooting_view.cycle_mode()
	await _capture("first-person-gate")
	assert(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE)
	game.solo_arena.start()
	game.solo_arena.remaining = 0.0
	await physics_frame
	await process_frame
	await _capture("first-person-entry")
	assert(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED)
	game.shooting_view.cycle_mode()
	var boss := game.solo_arena.boss
	boss.set_physics_process(false)
	var at := game.world.duel_arena.spawn_positions()[0] + Vector3(0, 0.15, 7)
	game.player.global_position = at
	boss.global_position = at + Vector3(4, 0, -2)
	boss.facing = Vector3(-4, 0, 2).normalized()
	boss.committed = boss.facing
	boss.rules.skill = DofufuRules.Skill.SLAM
	boss.rules.windup = 1.15
	boss.warning.show_skill(boss.rules.skill, boss.global_position, boss.facing)
	boss.art.present(boss.facing, false, true, false, 0.0)
	game.camera.reset_follow()
	await _capture("slam")
	root.size = Vector2i(960, 720)
	await _capture("compact")
	game.shooting_view.cycle_mode()
	game.shooting_view.cycle_mode()
	await _capture("first-person-fight")
	assert(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED)
	game.solo_arena.finish("VICTORY · You defeated Dofufu!")
	await _capture("result")
	game.solo_arena.enabled = false
	game.hud._notice.hide()
	game.shooting_view.cycle_mode()
	game.player.global_position = at
	var factory_boss := Dofufu.new()
	factory_boss.quarry = game.player
	factory_boss.position = at + Vector3(4, 0, -2)
	game.add_child(factory_boss)
	factory_boss.set_physics_process(false)
	factory_boss._face(game.player.global_position - factory_boss.global_position)
	game.camera.reset_follow()
	await _capture("factory-scale")
	game.queue_free()
	await process_frame
	quit()

func _capture(label: String) -> void:
	for frame in 20: await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("/tmp/tofufu-dofufu-" + label + ".png") == OK)

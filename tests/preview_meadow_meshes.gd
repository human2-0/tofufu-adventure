extends SceneTree
## Three-quarter and reverse enemy meshes at a readable scale, plus village details.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.hud.hide()
	game.chat.view.hide()
	game.weather_view.hide()
	game.player.set_physics_process(false)
	game.combat.equipment.knife_selected = false
	game.combat.gun.selected = false
	game.combat.sotjet.selected = false
	game.combat.equipment.staff_selected = false
	game.combat.sword.hide()
	game.combat.gun.visual.hide()
	game.combat.sotjet.visual.hide()
	game.combat.staff.hide()
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	game.camera.set_physics_process(false)
	game.camera.set_process(false)
	game.cycle.set_process(false)
	game.cycle.phase = 0.4
	game.cycle._process(0)
	var center := Vector3(500, 0, 0)
	var floor_view := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(30, 30)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("c4cea7")
	material.roughness = 1.0
	plane.material = material
	floor_view.mesh = plane
	floor_view.position = center
	game.world.add_child(floor_view)
	var snail := ArmoredSnailVisuals.new()
	game.world.add_child(snail)
	snail.position = center + Vector3(-1.2, 0, 0)
	var bee := BeeVisuals.new()
	game.world.add_child(bee)
	bee.position = center + Vector3(1.0, 0, 0)
	snail.present(Vector3.ZERO, Vector3.BACK, 0, 0, 0.01)
	bee.present(Vector3.BACK, 0, 0.024)
	for view in [
		{"name": "enemies", "at": center + Vector3.UP * 0.6, "camera": center + Vector3(3.0, 2.1, 4.5)},
		{"name": "enemies-reverse", "at": center + Vector3.UP * 0.6, "camera": center + Vector3(-3.0, 2.1, -4.5)},
		{"name": "house", "at": Vector3(46, 2.5, -7), "camera": Vector3(33, 7, -24)},
		{"name": "depot", "at": Vector3(24, 1.5, -18), "camera": Vector3(33, 8, -5)},
		{"name": "machinery", "at": Vector3(26, 1.5, -49), "camera": Vector3(34, 7, -39)},
		{"name": "units", "at": Vector3(49, 1.5, -54), "camera": Vector3(48, 12, -37)},
		{"name": "well", "at": Vector3(56.5, 1.5, -19), "camera": Vector3(61, 5, -13)},
	]:
		game.player.position = view.at + Vector3.UP * 0.5
		game.player.visible = false
		game.camera.position = view.camera
		game.camera.look_at(view.at)
		game.camera.fov = 50
		for i in 12: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/meadow-textured-" + view.name + ".png")
	game.queue_free()
	for i in 3: await process_frame
	await create_timer(0.1).timeout
	quit()

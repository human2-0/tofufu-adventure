extends SceneTree
## Real Sotjet damage numbers and soybean contact droplets, viewed behind Fufu.

func _initialize() -> void: call_deferred("_run")

func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-" + name + ".png")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var game: Node3D = load("res://game/app/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.player.set_physics_process(false)
	game.player.command_source.enabled = false
	game.player.position = Vector3(0, 0.05, 2)
	var dummy: PracticeDummy = game.encounters.dummy_nodes[0]
	dummy.position = Vector3(0, 0.05, -1)
	game.camera.set_shoulder(true)
	game.camera.yaw = 0
	game.camera._physics_process(0.016)
	game.camera.set_physics_process(false)
	game.hud.announce("")
	for i in 3: await physics_frame
	var command := PlayerCommand.new()
	command.weapon_slot = 4
	command.aim = Vector2.UP
	command.aim_point = dummy.position + Vector3.UP * 0.8
	command.attack_held = true
	for i in 20:
		game._on_command(command, 1.0 / 60.0)
		game.player.visuals.present(command, Vector3.ZERO, true, false, 1.0 / 60.0)
		await physics_frame
	await capture("milk-damage-drops")
	command.attack_held = false
	for i in 55:
		game._on_command(command, 1.0 / 60.0)
		await physics_frame
	command.weapon_slot = 3
	command.guard_held = true
	command.attack_held = true
	game._on_command(command, 1.0 / 60.0)
	game.player.visuals.present(command, Vector3.ZERO, true, false, 1.0 / 60.0)
	command.attack_held = false
	for i in 6:
		game._on_command(command, 1.0 / 60.0)
		await physics_frame
	await capture("soybean-impact-drops")
	game.queue_free()
	await process_frame
	quit()

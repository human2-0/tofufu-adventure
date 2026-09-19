extends SceneTree
## Real game, generated directional art, both cameras and falling fluid.

func _initialize() -> void: call_deferred("_run")

func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-sotjet-" + name + ".png")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var game: Node3D = load("res://game/app/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.player.set_physics_process(false)
	game.player.command_source.enabled = false
	game.player.position = Vector3(0, 0.05, 2)
	game.camera.set_shoulder(true)
	game.camera.yaw = 0
	game.camera._physics_process(0.016)
	game.camera.set_physics_process(false)
	game.hud.announce("")
	var command := PlayerCommand.new()
	command.weapon_slot = 4
	for index in 8:
		command.aim = Vector2.from_angle(index * PI / 4)
		game._on_command(command, 0.016)
		game.player.visuals.present(command, Vector3.ZERO, true, false, 0.016)
		await capture("view-%d" % index)
	command.aim = Vector2.UP
	command.aim_point = game.player.position + Vector3(0, 3, -25)
	command.attack_held = true
	for i in 45:
		game._on_command(command, 1.0 / 60.0)
		game.player.visuals.present(command, Vector3.ZERO, true, false, 1.0 / 60.0)
		await physics_frame
	await capture("shoulder")
	game.camera.set_shoulder(false)
	game.camera.position = game.player.position + Vector3(7, 5, 8)
	game.camera.look_at(game.player.position + Vector3(0, 0, -4))
	for i in 12:
		game._on_command(command, 1.0 / 60.0)
		game.player.visuals.present(command, Vector3.ZERO, true, false, 1.0 / 60.0)
		await physics_frame
	await capture("arc")
	game.queue_free()
	await process_frame
	quit()

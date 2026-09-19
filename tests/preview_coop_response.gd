extends SceneTree
## Render the actual shoulder walking poses and local soybean impact.

func _initialize() -> void: call_deferred("_run")

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
	command.weapon_slot = 3
	command.aim = Vector2.UP
	for direction in [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]:
		command.move = direction
		game.player.velocity = Vector3(direction.x, 0, direction.y)
		game._on_command(command, 0.016)
		game.player.visuals.present(command, game.player.velocity, true, false, 0.016)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/tofufu-walk-%d.png" % game.player.visuals.current_facing)
	game.hud._soy_hit.set_process(false)
	game.hud.show_damage_hit(2)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-soy-hit.png")
	game.queue_free()
	await process_frame
	quit()

extends SceneTree
## Render a live milk stream returning from Fufu's correctly oriented guard.
func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var game: Node3D = load("res://game/app/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.player.set_physics_process(false)
	game.player.command_source.enabled = false
	game.player.position = Vector3(0, 0.05, 0)
	game.camera.set_physics_process(false)
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.position = Vector3(4, 2.8, 3)
	camera.look_at(Vector3(0, 0.65, -0.8))
	camera.current = true
	var dummy: PracticeDummy = game.encounters.dummy_nodes[0]
	dummy.position = Vector3(0, 0.05, -2.5)
	var flow := SotjetFlow.new()
	flow.shooter = dummy.target.body
	flow.owner_health = dummy.target
	flow.targets = [game.health]
	flow.tuning = SotjetTuning.new()
	game.add_child(flow)
	var command := PlayerCommand.new()
	command.weapon_slot = 1
	command.guard_held = true
	command.aim = Vector2.UP
	for i in 24:
		game._on_command(command, 1.0 / 60.0)
		game.player.visuals.present(command, Vector3.ZERO, true, false, 1.0 / 60.0)
		flow.emit_milk(Vector3(0, 1.0, -2), Vector3(0, 0, 18), 1, Vector3(0, 1, -2))
		await physics_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-sword-reflection.png")
	game.queue_free()
	await process_frame
	quit()

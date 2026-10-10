extends SceneTree
## Moving shoulder view: compare every rendered mount/rider/camera interpolation sample.
class FlightInput extends PlayerCommandSource:
	func sample(_at: Vector3) -> PlayerCommand:
		var command := PlayerCommand.new()
		command.move = Vector2.UP
		return command
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(1280, 720)
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.weather.set_physics_process(false)
	game.weather.set_phase(0)
	game.cycle.set_process(false)
	game.cycle.phase = 0.43
	game.cycle._process(0)
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	var input := FlightInput.new()
	game.player.add_child(input)
	game.player.command_source = input
	game.player.relocate(game.parrot_travel.perches.stations[1].global_position + Vector3.UP * 0.1)
	if not game.parrot_travel.start(game.player):
		quit(1)
		return
	game.camera.set_shoulder(true)
	game.camera.pitch = 0.15
	var worst_mount: float = 0.0
	var worst_camera: float = 0.0
	for frame in 300:
		await RenderingServer.frame_post_draw
		var mount: ParrotArt = game.parrot_travel.mounts.riders.get(game.player)
		if mount == null: continue
		var rider := game.player.presentation.ground_position
		worst_mount = maxf(worst_mount, (mount.global_position + Vector3.UP * ParrotTravel.SADDLE_HEIGHT).distance_to(rider))
		worst_camera = maxf(worst_camera, game.camera._view_target.distance_to(rider))
		if frame in [90, 180, 270]: root.get_texture().get_image().save_png("/tmp/tofufu-parrot-motion-%d.png" % frame)
	print("Moving rear-view mount/rider error: ", worst_mount, "m / camera error: ", worst_camera, "m")
	game.queue_free()
	await process_frame
	quit(0 if worst_mount < 0.001 and worst_camera < 0.001 else 1)

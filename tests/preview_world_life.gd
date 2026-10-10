extends SceneTree
## Render the actual world with resting birds, a startled flock and wet landings.

class MotionInput extends PlayerCommandSource:
	var movement := Vector2.ZERO
	var jump_pressed: bool = false
	var jump_held: bool = false
	var dash_pressed: bool = false
	func sample(_at: Vector3) -> PlayerCommand:
		var command := PlayerCommand.new()
		command.move = movement
		command.aim = Vector2.RIGHT
		command.jump_pressed = jump_pressed
		command.jump_held = jump_held
		command.dash_pressed = dash_pressed
		command.dash_direction = Vector2.RIGHT
		jump_pressed = false
		dash_pressed = false
		return command

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.hud.hide()
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	game.camera.set_physics_process(false)
	game.camera.set_process(false)
	game.cycle.phase = 0.43
	game.cycle.set_process(false)
	game.cycle._process(0.0)
	game.weather.set_physics_process(false)
	var life := game.get_node("WorldLife") as WorldLife
	life.birds.set_process(false)
	var center := game.world.ground_point(-12, -14)
	game.player.relocate(center + Vector3(2.8, 0.1, 1.6))
	game.player.set_physics_process(false)
	for i in 8:
		var flight := life.birds.flights[i]
		flight.at = game.world.ground_point(-12 + (i % 4) * 0.8 - 1.2, -14 + (i / 4) * 1.4)
		flight.resting = 20.0
		life.birds.birds[i].position = flight.at
		life.birds.birds[i].present(1.0, false, Vector3.FORWARD)
	game.camera.position = center + Vector3(4.2, 4.5, 8.0)
	game.camera.look_at(center + Vector3.UP * 0.6)
	await _capture("resting")
	life.birds.observers.clear()
	life.birds.scatter(center, 8.0)
	life.birds._process(0.4)
	life.particles.burst(center, Vector3.ZERO, 24, false, 1.2)
	life.particles._process(0.12)
	life.particles.set_process(false)
	await _capture("flight")
	game.weather.set_phase(0.45)
	game.cycle.cloud_cover = 1.0
	game.cycle._process(5.0)
	life.particles.burst(game.player.position, Vector3.ZERO, 30, true, 1.5)
	life.particles._process(0.12)
	await _capture("rain")
	life.particles.set_process(true)
	var source := MotionInput.new()
	game.player.add_child(source)
	game.player.command_source = source
	game.player.set_physics_process(true)
	for frame in 15: await physics_frame
	source.jump_pressed = true
	source.jump_held = true
	for frame in 22: await physics_frame
	source.jump_held = false
	var feet := game.player.get_node("PlayerFootsteps") as PlayerFootsteps
	await feet.landed
	await _capture("landing")
	source.dash_pressed = true
	for frame in 5: await physics_frame
	game.player.set_physics_process(false)
	await _capture("dash")
	game.queue_free()
	await process_frame
	quit()

func _capture(label: String) -> void:
	for frame in 10: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-life-" + label + ".png")

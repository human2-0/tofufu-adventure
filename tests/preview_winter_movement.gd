extends SceneTree
## Actual-game snowfall, low running reserve, exhausted reserve and charged SP hints.

class MovementInput extends PlayerCommandSource:
	var run_held: bool = false
	var move := Vector2.ZERO
	func sample(_at: Vector3) -> PlayerCommand:
		var command := PlayerCommand.new()
		command.move = move
		command.run_held = run_held
		command.aim = Vector2.DOWN
		return command

func _initialize() -> void:
	call_deferred("_render")

func _render() -> void:
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	game.camera.set_physics_process(false)
	game.camera.set_process(false)
	game.cycle.phase = 0.43
	game.cycle.set_process(false)
	game.cycle._process(0.0)
	game.weather.set_physics_process(false)
	game.hud.announce("")
	var source := MovementInput.new()
	game.player.add_child(source)
	game.player.command_source = source
	game.player.relocate(game.world.ground_point(0, -280, 0.15))
	game.weather.set_phase(0.45)
	for frame in 10: await physics_frame
	game.cycle._process(4.0)
	game.weather_particles._process(3.0)
	game.camera.position = game.player.position + Vector3(4, 4.3, 8)
	game.camera.look_at(game.player.position + Vector3.UP * 0.9)
	await _save("winter-snow")
	game.weather.set_phase(0.1)
	for frame in 25: await physics_frame
	game.cycle._process(4.0)
	game.weather_particles._process(2.0)
	await _save("winter-gust")
	game.player.relocate(game.world.ground_point(-34, 7, 0.15))
	game.weather.set_phase(0)
	source.run_held = true
	source.move = Vector2.RIGHT
	for frame in 242: await physics_frame
	game.camera.position = game.player.position + Vector3(4, 4.3, 8)
	game.camera.look_at(game.player.position + Vector3.UP * 0.9)
	game.player.set_physics_process(false)
	await _save("run-low")
	game.player.set_physics_process(true)
	for frame in 96: await physics_frame
	game.player.set_physics_process(false)
	game.camera.position = game.player.position + Vector3(4, 4.3, 8)
	game.camera.look_at(game.player.position + Vector3.UP * 0.9)
	await _save("run-exhausted")
	game.hud.show_stamina(10, 100, 0)
	game.hud.show_charge(1.0)
	await _save("charged-low-sp")
	game.queue_free()
	await process_frame
	print("Winter and running renderer previews saved to /tmp/tofufu-*.png")
	quit()

func _save(name: String) -> void:
	for frame in 12: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-" + name + ".png")

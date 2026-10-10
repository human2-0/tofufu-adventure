extends SceneTree
## Actual renderer: fine grass, wind, a walked trail and recovery from the same view.

class WalkInput extends PlayerCommandSource:
	var movement := Vector2.ZERO
	func sample(_at: Vector3) -> PlayerCommand:
		var command := PlayerCommand.new()
		command.move = movement
		command.aim = Vector2.RIGHT
		return command

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.hud.hide()
	game.weather_view.hide()
	game.chat.view.hide()
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	game.camera.set_physics_process(false)
	game.camera.set_process(false)
	game.weather.set_physics_process(false)
	for node in game.get_children():
		if node is WeatherFlow: node.set_physics_process(false)
	game.cycle.phase = 0.43
	game.cycle.set_process(false)
	game.cycle._process(0.0)
	var center := game.world.ground_point(-5, -16)
	game.player.relocate(center + Vector3(-2, 0.1, 0))
	game.camera.position = center + Vector3(2.0, 4.4, 6.2)
	game.camera.look_at(center + Vector3.UP * 0.25)
	var source := WalkInput.new()
	game.player.add_child(source)
	game.player.command_source = source
	for frame in 25: await physics_frame
	await _capture("resting")
	source.movement = Vector2.RIGHT
	for frame in 75: await physics_frame
	source.movement = Vector2.ZERO
	await _capture("walked")
	var life := game.get_node("WorldLife") as WorldLife
	life.grass.set_physics_process(false)
	game.player.set_physics_process(false)
	game.world.grass_material.set_shader_parameter("wind_strength", 0.85)
	game.world.grass_material.set_shader_parameter("wind_direction", Vector2(0.6, 0.8))
	await _capture("wind")
	game.world.grass_imprint.recover(6.0)
	game.world.grass_imprint.upload()
	await _capture("recovered")
	game.world.grass_material.set_shader_parameter("wetness", 1.0)
	await _capture("wet")
	game.world.grass_material.set_shader_parameter("wetness", 0.0)
	# Close ground-level view exposes blade curvature and rooted terrain contact.
	game.camera.position = center + Vector3(0, 1.15, 2.8)
	game.camera.look_at(center + Vector3.UP * 0.3)
	await _capture("close")
	game.camera.position = game.player.position + game.camera.offset
	game.camera._update_camera_orientation()
	await _capture("gameplay")
	print("Grass renderer: ", RenderingServer.get_video_adapter_name())
	var calls := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var triangles := Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	game.world.get_node("WildGrass").hide()
	for frame in 4: await process_frame
	await RenderingServer.frame_post_draw
	print("Gameplay grass draw calls: ", calls - Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	print("Gameplay grass triangles: ", triangles - Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	game.queue_free()
	await process_frame
	quit()

func _capture(label: String) -> void:
	for frame in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-grass-" + label + ".png")

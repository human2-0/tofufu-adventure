extends SceneTree
## Short showers, sheltered floors, open rooftops and sea-surface precipitation.
var failures: int = 0
func _initialize() -> void: call_deferred("_run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	var clock := WeatherCycle.new()
	var rainy := 0
	for sample in 1000:
		clock.set_phase(sample / 1000.0)
		if clock.condition == WeatherCycle.Condition.RAIN: rainy += 1
	check(rainy == 100 and clock.cycle_seconds == 420, "a seven-minute cycle has only a forty-two-second shower")
	clock.free()
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.player.set_physics_process(false)
	game.camera.set_process(false)
	game.camera.set_physics_process(false)
	game.weather.set_physics_process(false)
	game.weather.set_phase(0.45)
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	var life := game.get_node("WorldLife") as WorldLife
	var castle := game.world.volcanic.castle
	for deck in 3:
		game.player.global_position = castle.to_global(Vector3(0, deck * 8 + 1, 0))
		game.camera.global_position = game.player.global_position + Vector3.UP
		life._physics_process(0.016)
		game.weather_particles._process(2)
		check(game.weather_particles.sheltered and not game.weather_particles._rain.visible, "covered castle deck stays dry")
	check(not WeatherExposure.covered(game, castle.to_global(Vector3(0, 1, 45))), "open castle approach remains exposed to the sky")
	var rooftop := WeatherExposure.precipitation_floor(316, 334, 0, game)
	check(is_equal_approx(rooftop.y, LavaCastle.BASE_HEIGHT + 24.0), "exterior rain terminates on the royal roof rather than leaking through maze floors")
	game.player.global_position = castle.to_global(Vector3(0, 25, 0))
	game.camera.global_position = game.player.global_position + Vector3.UP
	life._physics_process(0.016)
	game.weather_particles._process(2)
	check(not game.weather_particles.sheltered and game.weather_particles._rain.visible, "open royal rooftop receives outdoor rain")
	var sea := game.world.ground_point(0, -140, 0.1)
	game.player.global_position = sea
	game.camera.global_position = sea + Vector3.UP
	life._physics_process(0.016)
	game.weather_particles._process(2)
	check(WeatherExposure.submerged(game, sea) and not game.weather_particles._rain.visible and not game.weather_particles._leaves.visible, "submerged presentation excludes rain and blowing leaves")
	var floor_at := WeatherExposure.precipitation_floor(0, -140, 0, game)
	check(is_equal_approx(floor_at.y, OceanTerrain.WATER_LEVEL), "rain ends at the sea surface, above the seabed")
	game.player.global_position = game.world.ground_point(-30, 15, 0.1)
	game.camera.global_position = sea
	life._physics_process(0.016)
	game.weather_particles._process(2)
	check(not game.weather_particles._rain.visible, "a submerged camera also suppresses precipitation")
	game.camera.global_position = game.player.global_position + Vector3.UP * 3
	life._physics_process(0.016)
	game.weather_particles._process(2)
	check(game.weather_particles._rain.visible and game.weather.condition == WeatherCycle.Condition.RAIN, "leaving shelter restores the same shared rain spell")
	game.queue_free()
	await process_frame
	print("Weather exposure: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

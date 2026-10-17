extends SceneTree
## Flight-level continuity, cropped city roles and saved local effects in both locales.

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.player.set_physics_process(false)
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	game.hud.hide()
	game.weather_view.hide()
	game.weather.set_physics_process(false)
	game.weather.set_phase(0)
	game.cycle.set_process(false)
	game.cycle.phase = 0.45
	game.cycle._process(0)
	game.camera.set_physics_process(false)
	game.camera.set_process(false)
	for pair: Array in [
		[Vector3(170, 100, 140), Vector3(35, 0, 125), "flight-meadow"],
		[Vector3(145, 115, 180), Vector3(5, 2, 285), "flight-jungle"],
		[Vector3(220, 90, -85), Vector3(105, 0, -4), "district"],
		[Vector3(-1050, 120, 260), Vector3(-825, 12, 100), "highlands"]
	]:
		game.player.position = pair[1]
		game.camera.position = pair[0]
		game.camera.look_at(pair[1])
		await capture(pair[2])
	var gallery := Node3D.new()
	game.add_child(gallery)
	gallery.position = Vector3(0, 45, 0)
	for role in 4:
		for direction in 5:
			var sprite := DofufuCityArt.new()
			sprite.role = role
			gallery.add_child(sprite)
			sprite.position = Vector3(direction * 2.6, 0, role * 3.2)
			sprite.set_process(false)
			sprite.present_direction([2, 1, 0, 7, 6][direction])
	game.camera.position = Vector3(5.2, 58, 24)
	game.camera.look_at(Vector3(5.2, 46, 4.8))
	await capture("city-atlas")
	game.queue_free()
	await process_frame
	var app: Node = load("res://game/app/bootstrap/launch.tscn").instantiate()
	app.preferences.path = "user://graphics-preview.cfg"
	root.add_child(app)
	for locale in ["en", "pl"]:
		app.preferences.apply_language(locale)
		app.settings.show_settings()
		for tick in 4: await process_frame
		var option := app.settings.panel.find_child("Effect_audio", true, false) as Control
		app.menu._scroll.ensure_control_visible(option)
		await capture("settings-" + locale)
	app.queue_free()
	await process_frame
	quit()

func capture(label: String) -> void:
	for tick in 10: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-fixes-" + label + ".png")

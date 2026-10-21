extends SceneTree
## Actual city room cutaways, generated surfaces and bilingual chest interaction.

func _initialize() -> void: call_deferred("run")

func run() -> void:
	root.size = Vector2i(1600, 1000)
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	for tick in 4: await physics_frame
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	game.player.set_physics_process(false)
	game.camera.set_physics_process(false)
	game.camera.set_process(false)
	game.city_loot.set_process(false)
	game.cycle.set_process(false)
	game.cycle.phase = 0.42
	game.cycle._process(0)
	game.cycle.world_environment.environment.fog_enabled = false
	game.hud.visible = false
	game.chat.view.visible = false
	game.weather_view.visible = false
	game.weather_particles.visible = false
	var views := [
		{"id": "home-en", "site": 5, "offset": Vector3(14, 15, 18), "open": false, "locale": "en"},
		{"id": "home-pl", "site": 5, "offset": Vector3(14, 15, 18), "open": false, "locale": "pl"},
		{"id": "home-open", "site": 5, "offset": Vector3(14, 15, 18), "open": true, "locale": "en"},
		{"id": "warehouse", "site": 8, "offset": Vector3(31, 24, 39), "open": false, "locale": "en"},
		{"id": "clock-lobby", "site": 15, "offset": Vector3(-18, 18, 24), "open": false, "locale": "en"},
		{"id": "legacy-home", "site": 0, "offset": Vector3(17, 18, 21), "open": false, "locale": "en"}
	]
	for view in views:
		TranslationServer.set_locale(view.locale)
		var chest := game.city_loot.chests[view.site]
		game.player.relocate(chest.global_position + Vector3(0, 0.08, 2))
		game.camera.position = chest.global_position + view.offset
		game.camera.look_at(chest.global_position + Vector3.UP * 0.8)
		if view.open: game.city_loot.perform(game.player, view.site)
		chest.present(view.open, not view.open, "E")
		for frame in 20: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/tofufu-city-loot-" + view.id + ".png")
	game.queue_free()
	for frame in 4: await process_frame
	quit()

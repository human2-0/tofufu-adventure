extends SceneTree
## Native bilingual match menu and local graphics panel at desktop/compact sizes.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	GamePreferences.install_translations(self)
	var output := ProjectSettings.globalize_path("res://.codex/visualizations/2026/10/23/royale-performance")
	DirAccess.make_dir_recursive_absolute(output)
	var room := BattleRoom.new()
	room.options = [1, 1]
	root.add_child(room)
	room.practice()
	room.epoch = "b".repeat(24)
	var game := BattleRoyaleGame.new()
	game.room = room
	game.preferences.path = "user://graphics-preview-%d.cfg" % Time.get_ticks_usec()
	root.add_child(game)
	while not game.composed: await physics_frame
	BattleTestDeployment.finish(game)
	game.set_physics_process(false)
	game.combat.process_mode = Node.PROCESS_MODE_DISABLED
	game.settings._performance()
	for child in game.get_children():
		if child is BattleAimView:
			child.set_process(false)
			child.set_process_unhandled_input(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await create_timer(1.5).timeout # Let the FPS monitor discard the map-loading frame.
	for locale in ["en", "pl"]:
		TranslationServer.set_locale(locale)
		for dimensions in [Vector2i(1280, 720), Vector2i(640, 360)]:
			root.size = dimensions
			root.content_scale_size = dimensions
			game.settings.open()
			for frame in 10: await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output + "/graphics-%s-%d.png" % [locale, dimensions.x])
			game.settings.panel.hide()
			for frame in 5: await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output + "/match-menu-%s-%d.png" % [locale, dimensions.x])
	DirAccess.remove_absolute(game.preferences.path)
	game.queue_free()
	room.queue_free()
	await process_frame
	quit()

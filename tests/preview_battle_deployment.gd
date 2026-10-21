extends SceneTree
## Native desktop/compact English and Polish plant selection and emergence.
const OUTPUT := ".codex/visualizations/2026/10/21/battle-plants"
var output: String

func _initialize() -> void:
	call_deferred("_run")

func _shot(title: String) -> void:
	for frame in 12: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(title + ".png"))

func _run() -> void:
	output = ProjectSettings.globalize_path("res://").path_join(OUTPUT)
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	var app: Node = load("res://game/app/bootstrap/launch.tscn").instantiate()
	app.preferences.path = "user://battle-plant-preview.cfg"
	root.add_child(app)
	await process_frame
	app.battle.show_lobby()
	var settings: BattleCPUOptions = app.battle.panel.cpu_options
	settings.mode.select(1)
	settings.mode.item_selected.emit(1)
	for locale in ["en", "pl"]:
		TranslationServer.set_locale(locale)
		await _shot("duos-lobby-" + locale)
	root.size = Vector2i(640, 360)
	root.content_scale_size = root.size
	for locale in ["en", "pl"]:
		TranslationServer.set_locale(locale)
		settings.mode.grab_focus()
		await _shot("duos-lobby-compact-" + locale)
	app.battle._practice()
	while app.battle.game == null or not app.battle.game.composed: await physics_frame
	var game: BattleRoyaleGame = app.battle.game
	game.set_physics_process(false)
	game.match_state.deployment.remaining = 24
	BattleDeploymentState.choose(game.match_state.deployment, game.room.options, 0, 0, false)
	BattleDeploymentState.choose(game.match_state.deployment, game.room.options, 1, 1, false)
	BattleDeploymentState.choose(game.match_state.deployment, game.room.options, 2, 3, true)
	for dimensions in [Vector2i(1280, 720), Vector2i(640, 360)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		for locale in ["en", "pl"]:
			TranslationServer.set_locale(locale)
			game.deployment.update()
			await _shot("choose-%dx%d-%s" % [dimensions.x, dimensions.y, locale])
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	game.hud.exit_panel.show()
	game.deployment.update()
	for locale in ["en", "pl"]:
		TranslationServer.set_locale(locale)
		game._update_hud()
		await _shot("selection-exit-" + locale)
	game.hud.exit_panel.hide()
	game.match_state.deployment.choices[1] = 0
	BattleDeploymentState.complete(game.match_state.deployment, game.room.options)
	assert(BattlePlantLayout.emerge(game))
	game.match_state.deployment.remaining = 1.8
	game.deployment.update()
	game._update_hud()
	for frame in 35: await process_frame
	await _shot("emergence-pl")
	game.match_state.deployment.stage = 2
	game.match_state.deployment.remaining = 0
	game.match_state.time = 13
	game.combat.sync()
	for locale in ["en", "pl"]:
		TranslationServer.set_locale(locale)
		game._update_hud()
		await _shot("duos-game-" + locale)
	root.size = Vector2i(640, 360)
	root.content_scale_size = root.size
	for locale in ["en", "pl"]:
		TranslationServer.set_locale(locale)
		game._update_hud()
		await _shot("duos-game-compact-" + locale)
		if game.hud._header.get_global_rect().end.y >= game.hud.radar.get_global_rect().position.y:
			printerr("FAIL: Compact duo stats overlap the radar/player area.")
			quit(1)
			return
	app.battle.leave()
	app.queue_free()
	await process_frame
	quit()

extends SceneTree
## Render actual English/Polish battle lobby and a live twenty-actor CPU match.

func _initialize() -> void:
	call_deferred("_run")

func _shot(path: String) -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var app: Node = load("res://game/app/bootstrap/launch.tscn").instantiate()
	app.preferences.path = "user://battle-preview.cfg"
	root.add_child(app)
	await process_frame
	app.battle.show_lobby()
	TranslationServer.set_locale("en")
	await _shot("/tmp/tofufu-battle-lobby-en.png")
	TranslationServer.set_locale("pl")
	await _shot("/tmp/tofufu-battle-lobby-pl.png")
	root.size = Vector2i(640, 360)
	root.content_scale_size = Vector2i(640, 360)
	await _shot("/tmp/tofufu-battle-lobby-compact-pl.png")
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	app.battle._select_skin(3)
	app.battle._practice()
	while not is_instance_valid(app.battle.game) or not app.battle.game.composed: await physics_frame
	var game: BattleRoyaleGame = app.battle.game
	game.match_state.time = 14
	game.bodies[0].position = game.world.ground_point(-22, -22, 0.1)
	game.camera.reset_follow()
	for i in 90: await physics_frame
	await _shot("/tmp/tofufu-battle-game-pl.png")
	TranslationServer.set_locale("en")
	game._update_hud()
	await _shot("/tmp/tofufu-battle-game-en.png")
	game.hud.exit_panel.show()
	await _shot("/tmp/tofufu-battle-pause-en.png")
	game.hud.exit_panel.hide()
	root.size = Vector2i(640, 360)
	root.content_scale_size = Vector2i(640, 360)
	await _shot("/tmp/tofufu-battle-game-compact-en.png")
	TranslationServer.set_locale("pl")
	game._update_hud()
	await _shot("/tmp/tofufu-battle-game-compact-pl.png")
	app.battle.leave()
	app.queue_free()
	await process_frame
	quit()

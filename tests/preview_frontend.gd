extends SceneTree
## Renders shared-theme landing/loading and real gameplay windows.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var app: Node = load("res://game/app/bootstrap/launch.tscn").instantiate()
	app.store.directory = "user://frontend-preview"
	app.preferences.path = "user://frontend-preview.cfg"
	root.add_child(app)
	app.menu.quit_game.disconnect(app._quit)
	await _capture("landing")
	app.loader.view.begin("A little bean's big adventure", false)
	app.loader.view.stage("Gathering the world…", 42)
	await _capture("loading")
	app.loader.view.fail("The world could not be loaded. Return to title and try again.")
	await _capture("load-error")
	app._loading_back()
	root.content_scale_size = Vector2i(640, 360)
	root.size = Vector2i(640, 360)
	await _capture("compact")
	app.menu.settings.emit()
	await _capture("compact-settings")
	app.menu.show_home()
	app.loader.view.begin("A little bean sets out on a great new adventure", true)
	app.loader.view.stage("Restoring your adventure…", 95)
	await _capture("compact-loading")
	app._loading_back()
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	print("Starting rendered adventure")
	await app._start(0, {"name": "Preview", "opening_complete": true})
	print("Rendered adventure ready")
	app.game.player.position = Vector3(5, 0.2, -3)
	await _capture("hud")
	# Freeze world interaction closures while presenting windows for visual QA.
	app.game.process_mode = Node.PROCESS_MODE_DISABLED
	app.game.inventory_window.open()
	await _capture("inventory")
	app.game.inventory_window.close()
	app.game.merchant.window.open()
	await _capture("shop")
	app.game.merchant.window.close()
	app.game.seed_storage.window.open()
	await _capture("chest")
	app.game.seed_storage.window.close()
	app.game.quest_giver._refresh_window()
	app.game.quest_giver.window.open()
	await _capture("quests")
	app.game.quest_giver.window.close()
	app.menu.show()
	app._home()
	await _capture("pause")
	app.store.remove_slot(0)
	DirAccess.remove_absolute(app.store.directory)
	DirAccess.remove_absolute(app.preferences.path)
	app.queue_free()
	await process_frame
	quit()

func _capture(label: String) -> void:
	for frame in 10: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-frontend-" + label + ".png")

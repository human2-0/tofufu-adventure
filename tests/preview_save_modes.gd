extends SceneTree
## Render separate save lists and failure choices with isolated slots and a fake transport.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var app: Node = load("res://game/app/bootstrap/launch.tscn").instantiate()
	preload("res://tests/lobby_test_transport.gd").inject(app)
	var directory := "user://save-modes-preview-%d" % Time.get_ticks_usec()
	app.store.directory = directory
	app.preferences.path = directory + ".cfg"
	root.add_child(app)
	var record: Dictionary = preload("res://tests/test_save_modes.gd").fixture()
	record.name = "My solo adventure"
	app.store.write_slot(0, record)
	app.lobby.show_lobby()
	app.lobby._host_world(-1)
	while app.loader.busy: await process_frame
	app._return_title()
	await process_frame
	app.saves.show_saves()
	await _capture("solo")
	app.saves.show_saves(true)
	await _capture("coop")
	app.lobby.show_lobby()
	await _capture("lobby")
	app.menu.show_home(true)
	app.menu.note.text = "Could not write the save. Check available disk space."
	LaunchExit._failed(app, false)
	await _capture("save-failed")
	var dialog: ConfirmationDialog = app.menu.get_node("SaveFailure")
	dialog.canceled.emit()
	root.content_scale_size = Vector2i(640, 360)
	root.size = Vector2i(640, 360)
	app.menu.show()
	app.saves.show_saves(true)
	await _capture("coop-compact")
	app.menu.note.text = "Could not write the save. Check available disk space."
	LaunchExit._failed(app, false)
	await _capture("save-failed-compact")
	app.menu.get_node("SaveFailure").canceled.emit()
	app.store.remove_slot(0)
	app.coop_store.remove_slot(0)
	for mode in ["solo", "coop"]: DirAccess.remove_absolute(directory.path_join(mode))
	DirAccess.remove_absolute(directory)
	DirAccess.remove_absolute(app.preferences.path)
	app.queue_free()
	await process_frame
	quit()

func _capture(label: String) -> void:
	for frame in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-save-" + label + ".png")

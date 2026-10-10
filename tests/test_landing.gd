extends SceneTree
## Landing responsiveness, honest loading, failure recovery and cancelled starts.
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	var app: Node = load("res://game/app/bootstrap/launch.tscn").instantiate()
	var fake: SessionTransport = preload("res://tests/lobby_test_transport.gd").inject(app)
	app.store.directory = "user://landing-%d" % Time.get_ticks_usec()
	app.preferences.path = app.store.directory + ".cfg"
	root.add_child(app)
	await process_frame
	check(app.menu.visible and not app.loader.view.visible and app.game == null, "landing appears before world creation")
	check(not ResourceLoader.has_cached(AdventureLoader.WORLD_PATH), "landing does not preload the world scene")
	check(fake.starts == 0, "landing leaves peer discovery opt-in")
	for dimensions in [Vector2i(1280, 720), Vector2i(960, 540), Vector2i(640, 360)]:
		root.content_scale_size = dimensions
		root.size = dimensions
		app.menu.show_home()
		for frame in 3: await process_frame
		check(app.menu.size.x <= dimensions.x, "menu fits viewport width")
		var focus := root.gui_get_focus_owner()
		check(focus != null and focus.is_visible_in_tree(), "home focuses an available action")
		if dimensions.y == 360:
			check(focus.get_global_rect().end.y < dimensions.y - 24, "compact primary action is fully visible")
		app.saves.show_new()
		for frame in 3: await process_frame
		check(app.menu.content.size.x <= dimensions.x - 40, "new-adventure content fits compact viewport")
	var view: LoadingView = app.loader.view
	view.begin("A new chapter", false)
	view.stage("Restoring your adventure…", 95)
	for frame in 3: await process_frame
	check(view._card.get_global_rect().end.y <= 360, "loading card fits compact height")
	check(view.visible and view.progress.value == 95 and view.status.text.begins_with("Restoring"), "view displays explicit progress and stage")
	view.stage("Clamped", 200)
	check(view.progress.value == 100, "progress stays bounded")
	app.loader.cancel()
	var missing: AdventureGame = await app.loader.open(app, app.preferences, {}, false, "user://missing-adventure.tscn")
	check(missing == null and not app.loader.busy and view.visible, "missing world presents recoverable error")
	view.back_requested.emit()
	check(not view.visible and app.menu.visible, "error returns to title")
	app._start(0, {"name": "Cancelled"})
	check(app.loader.busy and view.visible and not app.menu.visible, "start shows loading and hides menu immediately")
	app._start(1, {"name": "Duplicate"})
	check(app._slot == 0, "duplicate start cannot replace the selected save")
	app.loader.cancel()
	for frame in 4: await process_frame
	check(app.game == null, "cancelled load cannot create gameplay")
	app._loading_back()
	app._start_coop(true, [], "")
	check(app.loader.busy, "co-op also uses loading view")
	app._coop_ended("Disconnected during loading")
	for frame in 4: await process_frame
	check(not app.loader.busy and app.game == null and app.menu.visible, "co-op disconnect cancels pending world creation")
	DirAccess.remove_absolute(app.preferences.path)
	app.queue_free()
	await process_frame
	print("Landing/loading tests: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

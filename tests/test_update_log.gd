extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	GamePreferences.install_translations(self)
	var app: Node = load("res://game/app/bootstrap/launch.tscn").instantiate()
	preload("res://tests/lobby_test_transport.gd").inject(app)
	app.preferences.path = "user://update-log-%d.cfg" % Time.get_ticks_usec()
	root.add_child(app)
	await process_frame
	check(is_instance_valid(app.updates.panel), "first launch presents unread updates")
	check(app.updates.seen == 0, "displaying updates alone does not acknowledge them")
	check(UpdateLog.since(0).size() == UpdateLog.ENTRIES.size(), "skipped releases are accumulated")
	check(UpdateLog.since(1).size() == UpdateLog.ENTRIES.size() - 1, "previous release only sees newer batches")
	var previous := 0
	var polish := preload("res://game/settings/localization/pl.po")
	for entry in UpdateLog.ENTRIES:
		check(entry.id > previous, "release IDs are unique and increasing")
		previous = entry.id
		for source: String in entry.bullets:
			check(not polish.get_message(source).is_empty(), "each summary has Polish copy")
	for locale in ["en", "pl"]:
		TranslationServer.set_locale(locale)
		app.updates.show_history()
		await process_frame
		var text := _bilingual_text(app.updates.panel)
		check(text.contains(UpdateLog.ENTRIES[0].bullets[0]), "English stays English in either locale")
		check(text.contains(String(polish.get_message(UpdateLog.ENTRIES[0].bullets[0]))), "Polish is present in either locale")
	for dimensions in [Vector2i(1280, 720), Vector2i(640, 360)]:
		root.content_scale_size = dimensions
		root.size = dimensions
		app.updates.show_history()
		for frame in 4: await process_frame
		check(app.menu.heading.get_global_rect().position.y >= 0, "long journal starts within the viewport")
		check(app.updates.panel.close_button.get_global_rect().end.y <= dimensions.y, "journal back action is accessible at both sizes")
	app.updates.panel.closed.emit()
	check(app.updates.seen == UpdateLog.latest_id(), "closing acknowledges the displayed releases")
	var restored := UpdateLogFlow.new()
	restored.path = app.updates.path
	restored.load_seen()
	check(restored.seen == UpdateLog.latest_id(), "acknowledgement persists across launches")
	check(UpdateLog.since(restored.seen).is_empty(), "read updates do not repeat")
	check(UpdateLog.since(restored.seen + 1).is_empty(), "older builds do not repeat already read releases")
	app.menu.show_home(true)
	app.menu.updates.emit()
	check(is_instance_valid(app.updates.panel), "pause menu can reopen full history")
	var good_path: String = app.updates.path
	app.updates.path = "user://missing-update-dir-%d/updates.cfg" % Time.get_ticks_usec()
	app.updates.seen = 0
	app.updates.panel.closed.emit()
	check(app.updates.seen == 0 and app.menu.note.text.contains("Could not remember"), "failed acknowledgement remains unread and reports failure")
	DirAccess.remove_absolute(good_path)
	app.queue_free()
	await process_frame
	TranslationServer.set_locale("en")
	print("Update journal tests: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _bilingual_text(node: Node) -> String:
	var text := ""
	if node is Label and node.auto_translate_mode == Node.AUTO_TRANSLATE_MODE_DISABLED:
		text += node.text + "\n"
	for child in node.get_children(): text += _bilingual_text(child)
	return text

extends SceneTree
## Real menu composition, persistent nickname and bounded, automatic discovery.
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	var app: Node = load("res://game/app/bootstrap/launch.tscn").instantiate()
	var fake = preload("res://tests/lobby_test_transport.gd").inject(app)
	fake.announce_ready = false
	app.store.directory = "user://lobby-test-%d" % Time.get_ticks_usec()
	app.preferences.path = app.store.directory + ".cfg"
	root.add_child(app)
	check(fake.starts == 0, "offline startup keeps discovery stopped")
	app.lobby.show_lobby()
	var first_name: String = app.preferences.nickname
	check(not first_name.is_empty() and fake.nickname == first_name, "co-op supplies a nickname without asking")
	check(fake.starts == 1 and app.lobby.panel.pulse.active and app.lobby.panel._host.disabled, "startup pulses and waits for authenticated readiness")
	app.menu.hide()
	check(not app.lobby.panel.pulse.is_processing(), "hidden menus suspend the activity animation")
	app.menu.show()
	check(app.lobby.panel.pulse.is_processing(), "visible discovery resumes its activity animation")
	app.lobby.show_lobby()
	check(fake.starts == 1, "rebuilding an in-flight lobby does not restart discovery")
	fake.event_received.emit({"type": "ready", "key": fake.key, "name": fake.nickname})
	check(not app.lobby.panel._host.disabled and app.lobby.panel.pulse.active, "ready identity permits hosting while finding friends")
	app.lobby.panel.identity._open()
	app.lobby.panel.identity._submit("  Miso\n Bean  ")
	check(app.preferences.nickname == "Miso Bean" and fake.nickname == "Miso Bean" and fake.starts == 2, "explicit rename saves and restarts discovery once")
	app.lobby.panel.identity._submit("Miso Bean")
	check(fake.starts == 2, "unchanged nickname does not restart discovery")
	var persisted := ConfigFile.new()
	check(persisted.load(app.preferences.path) == OK and persisted.get_value("profile", "nickname") == "Miso Bean", "nickname survives a new configuration reader")
	app.preferences.nickname = ""
	app.preferences.load_preferences()
	check(app.preferences.nickname == "Miso Bean", "new launch preferences reload the nickname")
	check(GamePreferences.clean_nickname("豆".repeat(40)).length() == 24, "nickname bounds preserve Unicode characters")
	var malformed := ConfigFile.new()
	malformed.set_value("profile", "nickname", {"invalid": true})
	var malformed_path: String = app.preferences.path + ".bad"
	malformed.save(malformed_path)
	var reloaded := GamePreferences.new()
	reloaded.path = malformed_path
	reloaded.load_preferences()
	check(reloaded.nickname.is_empty(), "malformed stored nicknames fall back safely")
	DirAccess.remove_absolute(malformed_path)
	fake.event_received.emit({"type": "error", "message": "Service unavailable"})
	check(not app.lobby.panel.pulse.active and app.lobby.panel._discover.visible and app.lobby.panel.status.text == "Service unavailable", "errors stop pulse and show an actionable retry")
	app.lobby.show_lobby()
	check(fake.starts == 2, "rebuilding failed lobby does not loop connection attempts")
	fake.announce_ready = true
	app.lobby.panel.discover.emit(app.preferences.nickname)
	check(fake.starts == 3 and not app.lobby.panel._discover.visible, "explicit retry restarts and clears failure")
	var friend := "b".repeat(64)
	fake.event_received.emit({"type": "peer", "key": friend, "name": "Friend"})
	fake.event_received.emit({"type": "packet", "key": friend, "data": {"type": "presence", "hosting": true, "busy": true}})
	var join_button: Button = app.lobby.panel._peers.get_child(0).get_child(1)
	check(join_button.text == "Join world" and not join_button.disabled, "reachable running worlds offer one join action")
	join_button.pressed.emit()
	check(app.room.pending_host() == friend and app.lobby.panel.identity._edit.disabled and app.lobby.panel.pulse.active, "joining locks nickname and indicates activity")
	app.lobby.panel.leave.emit()
	check(app.room.pending_host().is_empty() and fake.active, "cancel join preserves friend discovery")
	app.preferences.path = "user://missing-profile-directory/preferences.cfg"
	app.lobby.panel.identity._submit("Another bean")
	check(app.lobby.panel.status.text.contains("could not be saved"), "failed nickname persistence is visible")
	app.preferences.path = app.store.directory + ".cfg"
	var starts_before_save: int = fake.starts
	app.lobby.panel.identity._submit("Another bean")
	check(not app.lobby.panel.status.text.contains("could not be saved") and fake.starts == starts_before_save, "retrying nickname persistence does not restart discovery")
	app.lobby.panel.host.emit(-1)
	check(app.room.hosting and app.room.playing and app.loader.busy, "one Host world action starts the shared adventure")
	app.loader.cancel()
	for frame in 4: await process_frame
	app.connection.disconnect_session()
	check(not fake.active and app.room.local_key.is_empty(), "disconnect closes transport and clears identity")
	app.lobby.show_lobby()
	check(fake.active and fake.nickname == "Another bean", "returning to co-op reuses current nickname")
	app.lobby.panel.back.emit()
	check(not fake.active and app.menu.visible, "back to title closes discovery")
	await app.connection.select_transport(app.server_transport)
	app.lobby.show_lobby()
	check(app.server_transport.is_closed() and not app.lobby.panel.can_host, "dedicated mode remains explicitly connected")
	for dimensions in [Vector2i(1280, 720), Vector2i(960, 540), Vector2i(640, 360)]:
		root.content_scale_size = dimensions
		root.size = dimensions
		app.lobby.show_lobby()
		for frame in 3: await process_frame
		check(app.menu.content.size.x < dimensions.x, "lobby fits viewport width")
		check(app.lobby.panel.identity.size.x <= app.menu.content.size.x, "nickname and edit controls fit their column")
	DirAccess.remove_absolute(app.preferences.path)
	app.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	print("Co-op lobby: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

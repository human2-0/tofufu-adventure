extends SceneTree
## Persistent name claims, failed writes, stolen names and real public-menu admission.

var directory := "user://public-test-%d" % Time.get_ticks_usec()

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(directory)
	var characters := PublicCharacters.new()
	characters.path = directory.path_join("characters.json")
	assert(characters.load_records())
	var identity := characters.admit("a".repeat(64), "MisoBean", true)
	assert(identity == "a".repeat(64).sha256_text())
	assert(characters.admit("b".repeat(64), "misobean", true).is_empty())
	assert(characters.error.contains("taken"))
	assert(characters.admit("a".repeat(64), "Impostor", true).is_empty())
	assert(characters.admit("b".repeat(64), "../secret", true).is_empty())
	assert(characters.admit("c".repeat(64), "OtherBean", false).is_empty())
	var restored := PublicCharacters.new()
	restored.path = characters.path
	assert(restored.load_records())
	assert(restored.admit("a".repeat(64), "MisoBean", false) == identity)
	var stored := FileAccess.get_file_as_string(characters.path)
	assert(not stored.contains("a".repeat(64)), "server stores digests only")
	assert(not CoopCheckpoint.valid({"version": 2, "party": 1, "maps": {identity: {}}}), "malformed map owner records fail closed")
	var corrupt := PublicCharacters.new()
	corrupt.path = directory.path_join("broken.json")
	var broken := FileAccess.open(corrupt.path, FileAccess.WRITE)
	broken.store_string("{invalid")
	broken.close()
	assert(not corrupt.load_records(), "corrupt name registry cannot be replaced")
	var denied := PublicCharacters.new()
	denied.path = corrupt.path.path_join("characters.json")
	assert(denied.admit("e".repeat(64), "ValidBean", true).is_empty())
	assert(denied.records.is_empty() and denied.error.contains("could not save"), "failed writes cannot reserve a character")
	var profile := PublicProfile.new()
	profile.path = directory.path_join("client.json")
	assert(profile.load_profile() and profile.prepare("TestBean"))
	var token: String = profile.data.token
	assert(token.length() == 64 and profile.confirm())
	assert(profile.load_profile() and profile.data.token == token)
	assert(not profile.prepare("NewName"), "registered name cannot be changed")
	var transport := OracleTransport.new()
	transport.server_mode = true
	transport.port = 0
	transport.credentials = {"server_id": "f".repeat(64), "players": [], "public_registration": true, "characters_file": characters.path}
	var server := DedicatedServer.new()
	server.state_directory = directory.path_join("world")
	server.transport = transport
	server.add_child(transport)
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	root.add_child(viewport)
	viewport.add_child(server)
	assert(server.room.playing)
	var endpoint := "ws://127.0.0.1:%d" % transport._listener.get_local_port()
	OS.set_environment("TOFUFU_PUBLIC_ENDPOINT", endpoint)
	var app: Node = load("res://game/app/bootstrap/launch.tscn").instantiate()
	app.preferences.path = directory.path_join("preferences.cfg")
	app.public_play.profile = profile
	root.add_child(app)
	await app.public_play.show_public()
	assert(app.public_play.panel.name_field.text == "TestBean")
	app.public_play.panel.connect_requested.emit("TestBean")
	var deadline := Time.get_ticks_msec() + 45000
	while not is_instance_valid(app._coop) or not app._coop._synchronized:
		assert(Time.get_ticks_msec() < deadline, "public menu joins the world")
		await process_frame
	var key: String = app.room.local_key
	assert(app._coop.public_mode and not app._coop.authority, "public entry creates a guest view of the central authority")
	assert(key == token.sha256_text() and server.room.names[key] == "TestBean")
	for frame in 30: await physics_frame
	assert(server.session.personal_maps.maps.has(key))
	var before: float = server.game.cycle.phase
	server.session.roster.party[key].time_requested.emit()
	assert(server.game.cycle.phase == before, "public users cannot skip shared time")
	server.session.roster.party[key].progression.progress.award_experience(321)
	var progress: CharacterProgress = server.session.roster.party[key].progression.progress
	var points: int = progress.stat_points
	assert(points > 0)
	app.game.hud.stat_point_allocated.emit("sword")
	for frame in 10: await physics_frame
	assert(progress.stat_points == points - 1 and progress.stats.sword == 1, "guest allocation spends server-owned points")
	app.room.send_game(server.room.local_key, {"type": "allocate_stat", "skill": "sword", "sequence": 1})
	app.room.send_game(server.room.local_key, {"type": "allocate_stat", "skill": "sword", "sequence": 1000000})
	for frame in 10: await physics_frame
	assert(progress.stats.sword == 1, "replayed and future allocation requests cannot spend twice")
	assert(server.save_world())
	var checkpoint: Dictionary = server.store.read_slot(0)
	assert(checkpoint.coop.maps.has(key))
	assert(checkpoint.coop.party[key].progression.experience == 321)
	if DisplayServer.get_name() != "headless":
		for frame in 12: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/tofufu-public-world.png")
	# Another device cannot claim an existing name, including capitalization variants.
	var intruder := OracleTransport.new()
	intruder.public_mode = true
	intruder.credentials = {"endpoint": endpoint, "token": "b".repeat(64)}
	var rejected: Array[String] = []
	intruder.event_received.connect(func(event: Dictionary) -> void:
		if event.get("type") == "error": rejected.append(event.message))
	root.add_child(intruder)
	intruder.start("testbean")
	while rejected.is_empty(): await process_frame
	assert(rejected[0].contains("taken"))
	assert(key in server.room.members)
	app.connection.disconnect_session()
	while key in server.room.members: await process_frame
	assert(server.store.read_slot(0).coop.party[key].progression.experience == 321)
	app._online = false
	app._clear_game()
	app.public_play._back()
	assert(not app.server_transport.public_mode)
	OS.set_environment("TOFUFU_PUBLIC_ENDPOINT", "")
	app.queue_free()
	intruder.queue_free()
	viewport.queue_free()
	await process_frame
	print("Public name-only creation, private identity, menu join, map/save and impersonation guards: PASS")
	quit()

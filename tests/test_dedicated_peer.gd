extends SceneTree
## Separate-process launcher client; invoked by tools/verify_dedicated.py only.

var app: Node
var closing: bool = false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var deadline := create_timer(20)
	deadline.timeout.connect(func() -> void:
		push_error("Dedicated client timed out")
		quit(1))
	app = load("res://game/app/bootstrap/oracle_launch.tscn").instantiate()
	app.preferences.path = "user://dedicated-nickname-test-%d.cfg" % Time.get_ticks_usec()
	root.add_child(app)
	app.room.ended.connect(func(reason: String) -> void:
		if not closing:
			push_error("Unexpected disconnect: " + reason)
			quit(1))
	app.lobby.show_lobby()
	app.lobby.panel.discover.emit("Process tester")
	while app.room.peers.is_empty(): await process_frame
	print("CLIENT_READY")
	var server_key: String = app.room.peers.keys()[0]
	while not app.room.peers[server_key].hosting: await process_frame
	app.lobby.panel.join.emit(server_key)
	print("CLIENT_JOIN_WORLD")
	while app._coop == null or not app._coop._synchronized: await physics_frame
	print("CLIENT_WORLD_SYNCED")
	while app._coop.roster.party.size() < 2: await physics_frame
	assert(app.room.dedicated and not app._coop.authority)
	assert(server_key not in app._coop.roster.party)
	var member: CoopActor = app._coop.roster.party[app.room.local_key]
	var initial := member.actor.position
	var source := CoopTestInput.new()
	root.add_child(source)
	app._coop.roster.local_input = source
	# Distinct directions avoid colliding with the other player at spawn.
	source.move = Vector2.RIGHT
	for other: CoopActor in app._coop.roster.party.values():
		if other != member and other.actor.position.x > initial.x: source.move = Vector2.LEFT
	for tick in 45: await physics_frame
	source.move = Vector2.ZERO
	for tick in 20: await physics_frame
	assert(member.actor.position.distance_to(initial) > 0.3, "real server applies remote movement")
	assert(member.target_state.position.size() == 3)
	var result := {"identity": app.room.local_key, "position": member.target_state.position, "initial": [initial.x, initial.y, initial.z]}
	var path := OS.get_environment("TOFUFU_TEST_RESULT")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(result))
	file.close()
	# Coordinator releases both clients together after both have received state.
	while not FileAccess.file_exists(path.get_base_dir().path_join("release")): await process_frame
	closing = true
	app._return_title()
	assert(app.room.local_key.is_empty() and app.game == null)
	await app.connection.shutdown()
	DirAccess.remove_absolute(app.preferences.path)
	app.queue_free()
	source.queue_free()
	await process_frame
	print("Dedicated launcher process: PASS")
	quit()

extends SceneTree
## Actual launcher: isolated solo/co-op slots, host saves, exit recovery and resume.

var failures: int = 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var app: Node = load("res://game/app/bootstrap/launch.tscn").instantiate()
	var fake: SessionTransport = preload("res://tests/lobby_test_transport.gd").inject(app)
	var directory := "user://coop-launch-%d" % Time.get_ticks_usec()
	app.store.directory = directory
	app.preferences.path = directory + ".cfg"
	root.add_child(app)
	var host_key := "a".repeat(64)
	var guest_key := "b".repeat(64)
	app.room.local_key = host_key
	app.room.peers[guest_key] = {"name": "Friend", "hosting": false, "busy": false}
	await app._start(0, {"name": "Solo stays solo"})
	for hit in 27: app.game.progression.progress.weapon_hit("sword")
	app._return_title()
	await process_frame
	app.lobby.show_lobby()
	var solo_before := FileAccess.get_file_as_bytes(SaveSlotFiles.path(directory, "solo", 0))
	app.lobby._host(0)
	check(not app.room.hosting and app.lobby.save_data.is_empty(), "co-op refuses a solo slot")
	check(app.lobby.panel._adventures.item_count == 1, "solo adventure is absent from co-op selector")
	app.lobby._host(-1)
	check(not app.lobby.panel._begin.disabled, "solo host can start exploring from lobby")
	app.room.begin()
	check(app.room.playing and app.room.members.size() == 1, "actual launch starts meadow without a guest")
	app.room.receive({"type": "packet", "key": guest_key, "data": {"type": "join", "version": PlaytestRoom.GAME_VERSION}})
	app.room.receive({"type": "packet", "key": guest_key, "data": {"type": "ready", "epoch": app.room.epoch}})
	await _loaded(app)
	check(app._coop._ready_peers.has(guest_key), "guest readiness survives a slower host load")
	check(app.game != null and app._online and not app.menu.visible, "host menu launches shared adventure")
	check(app.game.progression.progress.practice.sword == 0, "new co-op world begins with independent character skills")
	app.game.opening.rules.pushes = 2
	app._coop.roster.party[guest_key].health.current = 66
	app._coop.roster.party[guest_key].progression.progress.mana_spent(37)
	app.game.progression.progress.award_experience(300)
	app.game.encounters.prop_nodes[0].target.damage(999)
	check(app._save(), "host menu saves full co-op state")
	var saved: Dictionary = app.coop_store.read_slot(0)
	check(not saved.is_empty(), "co-op save is readable")
	if saved.is_empty(): quit(1); return
	check(saved.coop.party[guest_key].health == 66, "save includes friend's health")
	var large := saved.duplicate(true)
	large.coop.maps = {}
	for index in 32:
		var key := "%064x" % (index + 1)
		large.coop.party[key] = saved.coop.party[host_key].duplicate(true)
		large.coop.maps[key] = app.game.map.exploration.capture()
	large.coop.party.erase(host_key)
	large.coop.party.erase(guest_key)
	check(JSON.stringify(large).to_utf8_buffer().size() > 98304, "full saved party exceeds the old save cap")
	check(app.coop_store.write_slot(1, large) and app.coop_store.read_slot(1).coop.maps.size() == 32, "bounded 32-character maps round-trip without blocking saves")
	app.coop_store.remove_slot(1)
	# Celestial items used to validate live but prevent disk saving and exiting.
	app.game.world_items.pool.restore([[1, "celestial_sword", 1, 100, 3, 0.5, 2]])
	check(app._save(), "celestial world drops can be saved")
	var good_file := FileAccess.get_file_as_bytes(SaveSlotFiles.path(directory, "coop", 0))
	app.coop_store.size_limit = 1
	await app._quit()
	check(not app._quitting and app.menu.has_node("SaveFailure"), "window close failure offers recovery before quitting")
	check(app.menu.get_node("SaveFailure").get_ok_button().text == "Quit without saving", "quit recovery explains the discard action")
	app.menu.get_node("SaveFailure").canceled.emit()
	check(not app.menu.visible and app.game != null, "keep playing cancels a failed quit without losing the world")
	app._return_title()
	check(app.game != null and app.menu.has_node("SaveFailure"), "failed save offers recovery without unloading progress")
	check(good_file == FileAccess.get_file_as_bytes(SaveSlotFiles.path(directory, "coop", 0)), "failed save preserves previous co-op file")
	app.coop_store.size_limit = 4194304
	var dialog: ConfirmationDialog = app.menu.get_node("SaveFailure")
	for button: Node in dialog.get_ok_button().get_parent().get_children():
		if button is Button and button.text == "Retry save": button.pressed.emit(); break
	await process_frame
	check(app.game == null and not app.room.playing and not fake.active, "retry saves and fully leaves the session")
	check(solo_before == FileAccess.get_file_as_bytes(SaveSlotFiles.path(directory, "solo", 0)), "co-op writes never alter solo progress")
	check(app.store.read_slot(0).progression.practice.sword == 27, "solo training survives co-op save and exit")
	check(app.store.list_saves().size() == 1 and app.coop_store.list_saves().size() == 1, "mode lists contain separate adventures at the same slot")
	await app.saves._continue(0, saved, true)
	check(app.game == null and app.lobby.panel._adventures.get_selected_id() == 0, "Co-op Continue selects shared adventure in lobby")
	app.room.local_key = host_key
	app.room.peers[guest_key] = {"name": "Friend", "hosting": false, "busy": false}
	app.lobby._host(0)
	app.room.members.append(guest_key)
	app.room.begin()
	await _loaded(app)
	check(app.game.opening.rules.pushes == 2, "hosting a save resumes the shared opening")
	check(app._coop.roster.party[guest_key].health.current == 66, "friend's state restores by identity")
	check(app._coop.roster.party[guest_key].progression.progress.practice.magic == 37, "friend skills restore from a previous host session")
	check(app.game.progression.progress.experience == 300, "host character EXP restores independently of adventure totals")
	check(app.game.encounters.prop_nodes[0].visible and app.game.encounters.prop_nodes[0].target.current == 0,
		"harvest state restores as a visible growing soy plant")
	check(app.game.encounters.pickups.size() == 1 and app.game.encounters.pickups.values()[0].count == 2, "uncollected two-bean stack restores")
	app.coop_store.size_limit = 1
	app._return_title()
	check(app.menu.has_node("SaveFailure"), "failed return offers an explicit discard choice")
	app.menu.get_node("SaveFailure").confirmed.emit()
	await process_frame
	check(app.game == null and not app.room.playing and not fake.active, "confirmed discard exits and closes the session")
	app.coop_store.size_limit = 4194304
	var identities := {host_key: saved.coop.party[host_key]}
	for index in 30: identities["%064x" % index] = saved.coop.party[host_key]
	app.lobby.save_data = {"coop": {"party": identities}}
	app.room.members = [host_key, guest_key]
	check(not app.lobby._can_admit("c".repeat(64)), "pending lobby guests count toward saved identity capacity")
	check(app.lobby._can_admit(guest_key), "existing lobby member remains admissible at capacity")
	identities[guest_key] = saved.coop.party[guest_key]
	app.room.members.clear()
	check(not app.lobby._can_admit("c".repeat(64)), "full saved party rejects a new host identity")
	check(app.lobby._can_admit(host_key), "original host can continue a full saved party")
	var waiting_room := PlaytestRoom.new()
	waiting_room.playing = true
	waiting_room.host_key = host_key
	waiting_room.send_packet = func(_key: String, _data: Dictionary) -> void: pass
	var waiting_guest := CoopSession.new()
	waiting_guest.room = waiting_room
	waiting_guest._silence = 11
	waiting_guest._physics_process(0.01)
	check(waiting_room.playing, "initial sync tolerates slower host world construction")
	waiting_guest._synchronized = true
	waiting_guest._physics_process(0.01)
	check(not waiting_room.playing, "synchronized guests retain ten-second host timeout")
	waiting_guest.roster.free()
	waiting_guest.opening.free()
	waiting_guest.free()
	waiting_room.free()
	app.store.remove_slot(0)
	app.coop_store.remove_slot(0)
	DirAccess.remove_absolute(directory.path_join("solo"))
	DirAccess.remove_absolute(directory.path_join("coop"))
	DirAccess.remove_absolute(directory)
	if FileAccess.file_exists(app.preferences.path): DirAccess.remove_absolute(app.preferences.path)
	app.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	print("Co-op launch: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)

func _loaded(app: Node) -> void:
	var deadline := Time.get_ticks_msec() + 30000
	while app.loader.busy and Time.get_ticks_msec() < deadline:
		await process_frame
	check(not app.loader.busy and app.game != null, "co-op world finishes loading")

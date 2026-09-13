extends SceneTree
## Actual launch/menu composition: new shared adventure, save, Continue, host again.

var failures: int = 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var app: Node = load("res://game/app/launch.tscn").instantiate()
	var directory := "user://coop-launch-%d" % Time.get_ticks_usec()
	app.store.directory = directory
	app.preferences.path = directory + ".cfg"
	root.add_child(app)
	var host_key := "a".repeat(64)
	var guest_key := "b".repeat(64)
	app.room.local_key = host_key
	app.room.peers[guest_key] = {"name": "Friend", "hosting": false, "busy": false}
	app._start(0, {"name": "Solo into co-op"})
	for hit in 27: app.game.progression.progress.weapon_hit("sword")
	app._return_title()
	await process_frame
	app.lobby.show_lobby()
	app.lobby._host(0)
	check(not app.lobby.panel._begin.disabled, "solo host can start exploring from lobby")
	app.room.begin()
	check(app.room.playing and app.room.members.size() == 1, "actual launch starts meadow without a guest")
	app.room.receive({"type": "packet", "key": guest_key, "data": {"type": "join", "version": PlaytestRoom.GAME_VERSION}})
	await process_frame
	check(app.game != null and app._online and not app.menu.visible, "host menu launches shared adventure")
	check(app.game.progression.progress.practice.sword == 27, "hosting a solo adventure retains trained skills")
	app.game.opening.rules.pushes = 2
	app._coop.roster.party[guest_key].health.current = 66
	app._coop.roster.party[guest_key].progression.progress.mana_spent(37)
	app.game.progression.progress.award_experience(300)
	app.game.encounters.prop_nodes[0].target.damage(999)
	check(app._save(), "host menu saves full co-op state")
	var saved: Dictionary = app.store.read_slot(0)
	check(not saved.is_empty(), "co-op save is readable")
	if saved.is_empty(): quit(1); return
	check(saved.coop.party[guest_key].health == 66, "save includes friend's health")
	app._return_title()
	await process_frame
	app._start(0, saved)
	check(app.game == null and app.lobby.panel != null, "Continue routes shared save to co-op lobby")
	app.room.local_key = host_key
	app.room.peers[guest_key] = {"name": "Friend", "hosting": false, "busy": false}
	app.lobby._host(0)
	app.room.members.append(guest_key)
	app.room.begin()
	await process_frame
	check(app.game.opening.rules.pushes == 2, "hosting a save resumes the shared opening")
	check(app._coop.roster.party[guest_key].health.current == 66, "friend's state restores by identity")
	check(app._coop.roster.party[guest_key].progression.progress.practice.magic == 37, "friend skills restore from a previous host session")
	check(app.game.progression.progress.experience == 300, "host character EXP restores independently of adventure totals")
	check(not app.game.encounters.prop_nodes[0].visible, "harvest state restores")
	check(app.game.encounters.pickups.size() == 2, "uncollected loot restores")
	app._return_title()
	await process_frame
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
	app.store.remove_slot(0)
	DirAccess.remove_absolute(directory)
	if FileAccess.file_exists(app.preferences.path): DirAccess.remove_absolute(app.preferences.path)
	app.queue_free()
	await process_frame
	print("Co-op launch: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)

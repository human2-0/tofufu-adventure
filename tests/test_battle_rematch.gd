extends SceneTree
## Real independent match worlds: recap, agreed replay, fresh state and replay after migration.
class FixtureApp extends Node:
	var menu := Control.new()
	var preferences := GamePreferences.new()
	var _menu_layer := CanvasLayer.new()
	func _ready() -> void:
		add_child(menu)
		menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(_menu_layer)
	func _home() -> void:
		menu.show()

var failures: int = 0
var flows: Array[BattleRoyaleFlow] = []
var rooms: Array[BattleRoom] = []
var viewports: Array[SubViewport] = []
var dropped: bool = false

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	if ok: return
	failures += 1
	printerr("FAIL: ", label)

func _run() -> void:
	for index in 2: _fixture(index)
	for index in 2:
		rooms[index].receive({"type": "peer", "key": rooms[1-index].local_key, "name": "Friend"})
	rooms[0].host()
	rooms[0].configure([2, 1, 1])
	rooms[1].join(rooms[0].local_key)
	rooms[0].begin()
	await _loaded([0, 1])
	var host := flows[0].game
	var guest := flows[1].game
	check(host != null and guest != null and host.composed and guest.composed, "both match compositions load")
	check(host.preferences == flows[0].app.preferences and guest.preferences == flows[1].app.preferences and host.preferences != guest.preferences, "each real friend match uses its own device graphics preferences")
	for game in [host, guest]: BattleTestDeployment.finish(game)
	host.replication._publish()
	guest.local_input.focus_point = guest.bodies[1].position + Vector3(1, 0, 0)
	var mark := InputEventKey.new()
	mark.physical_keycode = KEY_H
	mark.pressed = true
	guest._unhandled_input(mark)
	check(host.hud.radar.squad_pings.size() == 1 and guest.hud.radar.squad_pings.size() == 1, "real friend callout passes host validation and reaches both duo views")
	_storm_sites(host)
	_finish(host)
	check(guest.match_state.circle.is_equal_approx(host.match_state.circle) and _same_stats(guest.match_state.stats, host.match_state.stats), "guest receives route and authoritative achievements")
	for flow in flows:
		flow.game._update_hud()
		check(flow.game.match_view.results.visible and not flow.game.match_view.results.replay.disabled, "both friends get a usable team result and replay action")
	flows[1].rounds.request()
	flows[0].rounds.update(0.25)
	check(rooms[0].phase == "playing" and flows[0].rounds.votes.size() == 1, "one ready friend cannot force everyone into another round")
	var original := rooms[0].epoch
	flows[0].rounds.receive(rooms[1].local_key, {"kind": "br_round", "epoch": original, "term": 0, "next": "c".repeat(24), "members": rooms[0].members})
	check(rooms[0].epoch == original, "a guest cannot issue a new-round instruction")
	flows[0].rounds.receive(rooms[1].local_key, {"kind": "br_rematch", "epoch": "d".repeat(24), "term": 0, "ready": true})
	check(flows[0].rounds.votes.size() == 1, "stale epochs cannot add replay readiness")
	rooms[0].clock += 0.3
	flows[1].rounds.request()
	check(flows[0].rounds.votes.is_empty(), "a friend can cancel readiness")
	rooms[0].clock += 0.3
	flows[1].rounds.request()
	flows[0].rounds.request()
	var prior: WeakRef = weakref(host)
	flows[0].rounds.update(0.25)
	await _loaded([0, 1])
	check(rooms[0].epoch != original and rooms[0].epoch == rooms[1].epoch and rooms[0].phase == "playing", "all ready friends start a new epoch over the existing room")
	check(prior.get_ref() == null, "old match trees retire before replay")
	for flow in flows:
		var game := flow.game
		check(game.bodies.size() == 4 and game.match_state.deployment.stage == 0, "replay returns to soybean selection with the same duo and CPU count")
		check(game.match_state.chests.all(func(row: Array) -> bool: return row[4] == 0), "every chest is fresh in the next round")
		check(game.match_state.stats[0][0] == 0 and game.match_state.rows[0][12] == 0, "combat and goals never leak into the next round")
		check(flow.rounds.career.totals.peers[0] == 1 and flow.rounds.career.claimed.size() == 1, "replay banks the prior result once per friend")
		BattleTestDeployment.finish(game)
	host = flows[0].game
	guest = flows[1].game
	host.recovery.publish()
	var saved := BattleCheckpoint.decode(rooms[1].migration.checkpoint, rooms[1].members)
	check(not saved.is_empty(), "new epoch already has a resumable checkpoint")
	dropped = true
	rooms[1].receive({"type": "left", "key": rooms[0].local_key})
	for tick in 100: rooms[1]._process(0.05)
	check(rooms[1].authority() and rooms[1].phase == "playing" and guest.playing, "rematched guest can still become the replacement host")
	check(guest.match_state.stats == saved.stats and guest.match_state.circle.is_equal_approx(Vector2(saved.circle[0], saved.circle[1])), "migration retains goals, armour quiet time and circle route")
	_finish(guest)
	flows[1].rounds.update(0.25)
	flows[1].rounds.request()
	flows[1].rounds.update(0.25)
	await _loaded([1])
	check(rooms[1].phase == "playing" and rooms[1].members.size() == 1 and flows[1].game.bodies.size() == 4, "replacement host can replay with connected humans and configured CPU fill")
	check(flows[1].rounds.career.totals.peers[0] == 2, "second round awards once despite a host migration")
	var paths: Array[String] = []
	for flow in flows:
		paths.append(flow.rounds.career.path)
		paths.append(flow.app.preferences.path)
	for viewport in viewports: viewport.queue_free()
	await process_frame
	await process_frame
	await create_timer(0.25).timeout
	for path in paths:
		for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	print("Battle Royale rematch/recovery: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _fixture(index: int) -> void:
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.size = Vector2i(640, 360)
	root.add_child(viewport)
	viewports.append(viewport)
	var app := FixtureApp.new()
	app.preferences.path = "user://battle-replay-graphics-%d-%d.cfg" % [Time.get_ticks_usec(), index]
	viewport.add_child(app)
	var fake: SessionTransport = load("res://tests/lobby_test_transport.gd").new()
	app.add_child(fake)
	var flow := BattleRoyaleFlow.new()
	flow.app = app
	flow.transport = fake
	flow.rounds.career.path = "user://battle-replay-%d-%d.json" % [Time.get_ticks_usec(), index]
	app.add_child(flow)
	flow.set_process(false)
	flow.panel = BattleLobbyPanel.new()
	app.menu.add_child(flow.panel)
	var room := BattleRoom.new()
	room.local_key = "%064x" % (index + 1)
	room.options = [2, 1, 1]
	room.send_packet = func(key: String, packet: Dictionary) -> void: _deliver(room.local_key, key, packet)
	room.started.connect(flow._start)
	room.gameplay.connect(flow.rounds.receive)
	flow.add_child(room)
	room.set_process(false)
	flow.room = room
	flows.append(flow)
	rooms.append(room)

func _loaded(indices: Array) -> void:
	var deadline := Time.get_ticks_msec() + 120000
	while Time.get_ticks_msec() < deadline:
		var done := true
		for index: int in indices:
			var game := flows[index].game
			if game == null or not game.composed:
				done = false
				if game != null and not game.prepared.is_connected(game.set_physics_process.bind(false)):
					game.prepared.connect(game.set_physics_process.bind(false))
		if done:
			for index: int in indices:
				if flows[index].room.authority(): flows[index].game.replication._publish()
			return
		await physics_frame
	check(false, "bounded loading deadline")

func _finish(game: BattleRoyaleGame) -> void:
	BattleTestDeployment.finish(game)
	game.match_state.time = 13
	for slot in [2, 3]: game.match_state.hit(slot, 200, -1, true)
	game.match_state.step(0.01)
	game.replication._publish()
	game._update_hud()

func _storm_sites(game: BattleRoyaleGame) -> void:
	var original := game.room.epoch
	var seen: Dictionary = {}
	for seed in 8:
		game.room.epoch = "%024x" % (seed + 1)
		BattleStormLayout.choose(game)
		var circle := game.match_state.circle
		seen[circle] = true
		check(circle.distance_to(BattleRing.CENTER) <= BattleRing.MAX_ANCHOR and not game.world.is_water(game.world.ground_point(circle.x, circle.y, 0.08)), "finale seed selects supported dry terrain")
	game.room.epoch = original
	BattleStormLayout.choose(game)
	check(seen.size() > 1, "different match seeds vary the finale location")

func _deliver(sender: String, target: String, packet: Dictionary) -> void:
	if dropped: return
	for room in rooms:
		if room.local_key == target: room.receive({"type": "packet", "key": sender, "data": JSON.parse_string(JSON.stringify(packet))})

func _same_stats(left: Array, right: Array) -> bool:
	if left.size() != right.size(): return false
	for slot in left.size():
		for index in left[slot].size():
			if absf(float(left[slot][index]) - float(right[slot][index])) > 0.0011: return false
	return true

extends SceneTree
## Real smaller worlds, authenticated options, finite inventory and paused recovery.

var failures: int = 0
var rooms: Array[BattleRoom] = []
var games: Array[BattleRoyaleGame] = []
var host_lost: bool = false

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, label: String) -> void:
	if value: return
	failures += 1
	printerr("FAIL: ", label)

func _run() -> void:
	_rules()
	_difficulty()
	_codec()
	_cadence()
	await _lobby()
	await _worlds()
	for game in games: game.queue_free()
	for room in rooms: room.queue_free()
	await process_frame
	await process_frame
	await create_timer(0.25).timeout
	print("Battle CPU settings: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _rules() -> void:
	for invalid in [[], [51, 1], [-1, 1], [7, 3], [7, -1], [7.5, 1], [7, "1"], [7, NAN]]:
		check(not BattleOptions.valid(invalid), "invalid CPU settings rejected")
	var positions: Array[Vector3] = []
	for i in 70: positions.append(Vector3(i, 0, 0))
	for humans in range(1, 21):
		for count in 51:
			var options: Array = [count, count % 3]
			var expected := humans + count
			check(BattleOptions.seats(options, humans) == expected, "fifty CPUs coexist with every supported human roster")
			if expected < 2: continue
			var state := BattleMatch.new()
			state.initialize(positions, humans, options)
			check(state.rows.size() == expected and state.alive == expected, "only participating survivors exist")
			check(BattleProtocol.snapshot(state.capture()), "every supported roster serializes")
			state.time = 13
			for slot in range(1, expected): state.hit(slot, 200, 0, true)
			state.step(0.01)
			check(state.winner == 0 and state.rows[1][13] == expected, "placement and victory use actual survivor count")
	var room := BattleRoom.new()
	room.local_key = "a".repeat(64)
	room.host()
	room.configure([0, 2])
	room.begin()
	check(room.phase == "waiting", "one human with zero CPUs cannot accidentally win an empty match")
	room.members.append({"key": "b".repeat(64), "name": "Friend", "skin": 1})
	room.begin()
	check(room.phase == "loading", "zero CPU human-only game can start")
	room.configure([19, 0])
	check(room.options == [0, 2], "settings freeze at loading")
	room.free()

func _difficulty() -> void:
	var state := BattleMatch.new()
	var positions: Array[Vector3] = [Vector3.ZERO, Vector3(0, 0, 15)]
	state.initialize(positions, 1, [1, 1])
	state.rows[1][3] = 5.0
	var errors: Array[float] = []
	var firing: Array[int] = []
	for skill in 3:
		state.options[1] = skill
		var error := 0.0
		var shots := 0
		for tick in 240:
			state.time = 13 + tick * 0.1
			error += absf(Vector2.DOWN.angle_to(BattleBotSkill.aim(Vector2.DOWN, 0, state)))
			shots += int(BattleBotSkill.firing(0, state))
			check(BattleProtocol.command(BattleBot.command(0, state)), "all difficulty commands remain bounded")
		errors.append(error)
		firing.append(shots)
	check(errors[0] > errors[1] * 1.5 and errors[1] > errors[2] * 1.5, "higher skill measurably improves aim")
	check(firing[0] < firing[1] and firing[1] < firing[2], "higher skill reduces rest between attack bursts")
	state.options[1] = 0
	var easy := state.position_of(1).distance_to(BattleBotSkill.perceived(state, 1))
	state.options[1] = 2
	check(easy > state.position_of(1).distance_to(BattleBotSkill.perceived(state, 1)), "Easy reacts to older perceived positions")
	check(state.rows[0][8] == state.rows[1][8] and state.rows[0][9] == state.rows[1][9], "difficulty never modifies health or armour")

func _lobby() -> void:
	var app: Node = load("res://game/app/bootstrap/launch.tscn").instantiate()
	var fake: SessionTransport = load("res://tests/lobby_test_transport.gd").new()
	app.get_node("BattleTransport").free()
	app.add_child(fake)
	app.battle_transport = fake
	app.preferences.path = "user://battle-cpu-%d.cfg" % Time.get_ticks_usec()
	root.add_child(app)
	await process_frame
	app.battle.show_lobby()
	var controls: BattleCPUOptions = app.battle.panel.cpu_options
	check(controls.count.value == 7 and controls.difficulty.selected == 1, "UI defaults to seven Normal CPUs")
	controls.count.value = 0
	check(app.battle.panel.practice_button.disabled, "zero CPU solo practice explains why start needs an opponent")
	app.battle.panel.host_friends.emit()
	check(app.battle.room.options == [0, 1] and app.battle.panel.start_button.disabled, "private lobby uses selected count")
	controls.count.value = 4
	controls.difficulty.select(2)
	controls.difficulty.item_selected.emit(2)
	check(app.battle.room.options == [4, 2] and not app.battle.panel.start_button.disabled, "waiting host can edit count and difficulty")
	for locale in ["en", "pl"]:
		TranslationServer.set_locale(locale)
		await process_frame
		check(controls.summary.text.contains("4") and controls.summary.text.contains("5"), "summary survives live language switching without a room event")
	check(controls.summary.text.begins_with("CPU w meczu") and app.battle.panel.roster.text.begins_with("Gracze:"), "formatted summaries and player counts translate live")
	TranslationServer.set_locale("en")
	check(controls.summary.text.begins_with("CPUs this match") and app.battle.panel.roster.text.begins_with("Players:"), "formatted labels return to English")
	app.battle.leave()
	DirAccess.remove_absolute(app.preferences.path)
	app.queue_free()
	await process_frame

func _worlds() -> void:
	for i in 2:
		var room := BattleRoom.new()
		room.local_key = "%064x" % (i + 1)
		room.send_packet = func(key: String, packet: Dictionary) -> void: _deliver(room.local_key, key, packet)
		root.add_child(room)
		room.set_process(false)
		rooms.append(room)
	for i in 2:
		rooms[i].receive({"type": "peer", "key": rooms[1-i].local_key, "name": "Friend"})
	var host := rooms[0]
	var guest := rooms[1]
	host.host()
	host.configure([50, 2])
	guest.join(host.local_key)
	check(guest.options == [50, 2], "guest receives bounded authoritative settings")
	guest.configure([19, 0])
	check(guest.options == [50, 2], "guest cannot change lobby settings")
	var invalid := {"kind": "br_roster", "v": BattleProtocol.VERSION, "build": BattleProtocol.BUILD,
		"epoch": host.epoch, "members": host.members, "phase": "waiting", "options": [999, 2]}
	_deliver(host.local_key, guest.local_key, invalid)
	check(guest.options == [50, 2], "malformed roster cannot replace CPU settings")
	host.begin()
	for room in rooms:
		var viewport := SubViewport.new()
		viewport.own_world_3d = true
		viewport.size = Vector2i(640, 360)
		root.add_child(viewport)
		var game := BattleRoyaleGame.new()
		game.room = room
		viewport.add_child(game)
		games.append(game)
		while not game.composed: await physics_frame
		game.set_physics_process(false)
		check(game.bodies.size() == 52 and game.combat.fighters.size() == 52 and game.pack.healing.size() == 52, "fifty-CPU world instantiates 52 actor/combat/inventory instances")
	check(host.phase == "playing" and guest.phase == "playing", "fifty-CPU rosters synchronize readiness")
	_visibility(games[0])
	var authority := games[0]
	var replica := games[1]
	BattleTestDeployment.finish(authority)
	authority.match_state.time = 13
	authority.pack.healing[1].apple_duration_remaining = 60
	authority.pack.healing[1].active_heal_remaining = 4
	authority.replication._publish()
	check(replica.replication.snapshot_sequence > 0 and replica.match_state.rows.size() == 52, "first fifty-CPU keyframe is accepted")
	var sequence := replica.replication.snapshot_sequence
	authority.pack.healing[1].apple_duration_remaining = 59
	authority.replication._publish()
	check(replica.replication.snapshot_sequence > sequence and replica.pack.healing[1].apple_duration_remaining == 59, "52-actor combat and healing deltas apply")
	var bad := authority.match_state.capture()
	bad.combat.append(bad.combat[0])
	check(not BattleProtocol.snapshot(bad), "combat actor count mismatch rejected")
	authority.replication._input(guest.local_key, {"seq": 1, "inputs": [[69, [0, 0, 0, 1, 0]]]})
	check(authority.replication.last_sequences.is_empty(), "unused seat input rejected before indexing")
	authority.recovery.publish()
	check(guest.migration.checkpoint_seq > 0, "fifty-CPU checkpoint validates inventories and motors")
	var saved := guest.migration.checkpoint
	var wrong := BattleCheckpoint.decode(saved, guest.members)
	wrong.options = [49, 2]
	check(BattleCheckpoint.decode(JSON.stringify(wrong), guest.members).is_empty(), "checkpoint count must match frozen roster")
	wrong = BattleCheckpoint.decode(saved, guest.members)
	wrong.options[1] = 0
	wrong.seq += 100
	check(not guest.migration.remember(JSON.stringify(wrong)), "checkpoint cannot change selected difficulty")
	host_lost = true
	guest.receive({"type": "left", "key": host.local_key})
	var frozen := replica.match_state.time
	check(guest.phase == "recovering" and not replica.playing, "host loss pauses fifty-CPU match")
	for tick in 100: guest._process(0.05)
	check(guest.phase == "playing" and guest.authority() and guest.term == 1, "sole guest restores and becomes host")
	check(replica.bodies.size() == 52 and replica.match_state.time == frozen and replica.match_state.options == [50, 2], "migration preserves exact actor count, frozen time and difficulty")
	check(replica.match_state.rows[0][17] == 1 and replica.pack.healing[1].apple_duration_remaining == 59, "departed human becomes a CPU and ongoing healing survives")
	var worker := replica.replication.owner_of(4, replica.replication.workers())
	check(worker == guest.local_key, "new host inherits CPU workers without adding seats")
	replica.match_state.time = 13
	for i in 10:
		replica.replication.step(0.1, PlayerCommand.new())
		replica.simulation.step(0.1)
	check(replica.match_state.rows.size() == 52, "migrated fifty-CPU match continues simulation")
	for game in games: game.get_parent().queue_free()

func _deliver(from: String, to: String, packet: Dictionary) -> void:
	if host_lost and (from == rooms[0].local_key or to == rooms[0].local_key): return
	for room in rooms:
		if room.local_key == to:
			room.receive({"type": "packet", "key": from, "data": JSON.parse_string(JSON.stringify(packet))})
			return

func _codec() -> void:
	var value := {"kind": "br_state", "epoch": "a".repeat(24), "term": 0, "seq": 1, "values": []}
	for i in 1000: value.values.append([i, 1, 2, 3, 0.125])
	var packed := BattleWire.packet(value)
	check(JSON.stringify(packed).length() < JSON.stringify(value).length(), "compressed full state reduces wire size")
	var decoded := BattleWire.restore(packed)
	check(decoded.get("values", []).size() == 1000 and int(decoded.get("seq", 0)) == 1, "value-only state expands within bounds")
	packed.seq = 2
	check(BattleWire.restore(packed).is_empty(), "compressed inner/outer sequence mismatch rejected")
	for invalid in ["Z6:999999999:bad:AAAA", "Z6:100:" + "0".repeat(64) + ":@@@@", "Z6:100:" + "0".repeat(64) + ":eJwDAAAAAAE=", "Z6:" + "a".repeat(BattleWire.MAX_WIRE_BYTES)]:
		check(BattleWire.text(invalid).is_empty(), "oversized, malformed and damaged compressed payload rejected")

func _visibility(game: BattleRoyaleGame) -> void:
	var actor := game.bodies[-1]
	var fighter := game.combat.fighters[-1]
	var at := actor.position
	var hp: float = game.match_state.rows[-1][8]
	var ammo := fighter.combat.gun.magazine
	actor.position = game.camera.global_position + game.camera.global_basis.x * 200 - game.camera.global_basis.z * 10
	game.visibility._process(0)
	check(not actor.visuals.presentation_enabled and not fighter.combat.gun.visual.is_processing(), "offscreen sprite and held-model work sleeps")
	check(fighter.combat.gun.visual_muzzle.call().distance_to(fighter.combat.gun.muzzle_position(fighter.combat.gun.visual.facing)) < 0.001, "offscreen projectile visual starts at its current physical muzzle")
	check(game.match_state.rows[-1][8] == hp and fighter.combat.gun.magazine == ammo and actor.collision_mask != 0, "cosmetic culling preserves health, ammunition and collision")
	actor.position = game.camera.global_position - game.camera.global_basis.z * (BattleVisibility.COMBATANT_RANGE + 20)
	game.visibility._process(0)
	check(not actor.visuals.presentation_enabled and not fighter.combat.gun.visual.visible, "distant on-screen enemies cannot appear through culled scenery")
	actor.position = game.bodies[game.local_slot].position
	game.visibility._process(0)
	check(actor.visuals.presentation_enabled and fighter.combat.gun.visual.is_processing(), "visible actors immediately resume animated poses and weapons")
	actor.position = at
	game.visibility._process(0)

func _cadence() -> void:
	var game := BattleRoyaleGame.new()
	game.room = BattleRoom.new()
	game.room.local_key = "b".repeat(64)
	game.room.host_key = "a".repeat(64)
	game.room.members = [{"key": game.room.local_key, "name": "Worker", "skin": 0}]
	var positions: Array[Vector3] = []
	for i in 51: positions.append(Vector3(i, 0, 0))
	game.match_state.initialize(positions, 1, [50, 1])
	var body := Player.new()
	game.bodies.append(body)
	game.replication.game = game
	var counts: Dictionary = {}
	game.room.send_packet = func(_key: String, packet: Dictionary) -> void:
		check(packet.inputs.size() == 26, "each 20-Hz input frame carries only half of fifty CPUs")
		for input: Array in packet.inputs:
			if input[0] != 0: counts[input[0]] = int(counts.get(input[0], 0)) + 1
	for i in 10: game.replication.step(0.05, PlayerCommand.new())
	check(counts.size() == 50, "staggered steering reaches every CPU")
	for count: int in counts.values(): check(count == 5, "each CPU keeps ten decisions per simulated second")
	body.free()
	game.room.free()
	game.free()

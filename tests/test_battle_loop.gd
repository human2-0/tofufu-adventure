extends SceneTree
## Match pacing, fair recovery, achievements, isolated career persistence and cover AI.
var failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	if ok: return
	failures += 1
	printerr("FAIL: ", label)

func _run() -> void:
	_rings()
	_stats()
	_career()
	await _navigation()
	print("Battle Royale match loop: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _state() -> BattleMatch:
	var state := BattleMatch.new()
	var positions: Array[Vector3] = [Vector3.ZERO, Vector3(4, 0, 0), Vector3(8, 0, 0), Vector3(12, 0, 0)]
	state.initialize(positions, 1, [3, 1])
	state.time = 13
	return state

func _rings() -> void:
	for anchor: Vector2 in [Vector2(-180, -100), Vector2(170, 75), Vector2.ZERO, BattleRing.CENTER]:
		var previous := BattleRing.CENTER
		for tick in 4500:
			var time := tick / 10.0
			var center := BattleRing.center(time, anchor)
			var next := BattleRing.next_center(time, anchor)
			var radius := BattleRing.radius(time)
			var next_radius: float = BattleRing.RADII[BattleRing.stage(time) + 1]
			check(center.distance_to(next) + next_radius <= radius + 0.001, "announced next circle stays inside current safe circle")
			check(center.distance_to(previous) < 1, "moving circle has no stage-boundary teleport")
			previous = center
		check(BattleRing.center(430, anchor).is_equal_approx(anchor), "late circles finish at the chosen dry anchor")
	check(not BattleRing.closing(13) and BattleRing.closing(33), "hold and closing are separate readable phases")
	check(is_equal_approx(BattleRing.phase_remaining(13), 19), "hold warning uses time until movement, not end of closing")
	var finale := _state()
	finale.time = 432
	for tick in 400:
		if finale.winner != -2: break
		# Even unlimited milk plus apple regeneration cannot stall the closed circle.
		for row: Array in finale.rows:
			if row[8] > 0: row[8] = minf(100, float(row[8]) + 2.2)
		finale.step(0.1)
	check(finale.winner != -2 and finale.time < 470, "escalating final storm ends healing stalemates promptly")

func _stats() -> void:
	var state := _state()
	state.rows[0][9] = 0
	state.step(7)
	check(state.rows[0][9] == 0, "armour cannot regenerate during the quiet delay")
	state.step(1)
	state.step(2)
	check(state.rows[0][9] == 10, "quiet armour recovers at five per second")
	state.hit(0, 5, 1)
	state.step(1)
	check(state.rows[0][9] == 5 and state.stats[0][BattleRoundStats.QUIET] == 1, "fresh damage resets armour recovery")
	state.step(8)
	state.step(20)
	check(state.rows[0][9] == 50 and state.rows[0][8] == 100, "recovery caps at starting armour and adds no HP")
	state.hit(2, 1000, 0)
	check(state.stats[0][0] == 150 and state.stats[2][1] == 150, "damage stats count actual HP and armour rather than overkill")
	var seconds: float = state.stats[2][4]
	state.step(1)
	check(state.stats[2][4] == seconds, "survival achievement stops after elimination")
	state.stats[0][2] = 3
	state.stats[0][4] = 90
	state.hit(1, 1000, 0)
	state.hit(3, 1000, 0)
	state.step(0.01)
	var summary := BattleRoundStats.summary(state, 0)
	check(summary.won and summary.goals == 3 and summary.kills == 3 and summary.xp > 200, "winning and varied match goals have a bounded cosmetic reward")
	var packet := state.capture()
	check(BattleProtocol.snapshot(packet), "new circle and goal ledger validate over the battle wire")
	packet.stats[0][0] = NAN
	check(not BattleProtocol.snapshot(packet), "non-finite achievements are rejected")
	packet = state.capture()
	packet.circle = [300, 300]
	check(not BattleProtocol.snapshot(packet), "distant or unsafe route bounds cannot enter presentation")
	var duo := _state()
	duo.options = [3, 1, 1]
	duo.hit(1, 100, 0)
	check(duo.stats[0][0] == 0 and duo.stats[1][1] == 0, "teammates cannot farm damage goals or delay each other's armour")

func _career() -> void:
	var store := BattleCareer.new()
	store.path = "user://battle-career-test-%d.json" % Time.get_ticks_usec()
	var state := _state()
	for slot in [1, 2, 3]: state.hit(slot, 1000, 0)
	state.step(0.01)
	var summary := BattleRoundStats.summary(state, 0)
	var id := "a".repeat(24)
	check(store.award(id, summary, true), "finished local result is stored atomically")
	var earned := store.xp
	check(store.caption(summary.xp) != store.caption() and store.xp == earned, "projected level progress in the recap does not bank an unsettled result")
	check(not store.award(id, summary, true) and store.xp == earned, "reopening results or migration cannot double-claim an epoch")
	check(store.award("b".repeat(24), summary, false), "peer result has its own record category")
	var loaded := BattleCareer.new()
	loaded.path = store.path
	loaded.load_records()
	check(loaded.xp == store.xp and loaded.totals.practice[0] == 1 and loaded.totals.peers[0] == 1, "career survives reload without modifying match stats")
	var file := FileAccess.open(store.path, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	loaded.load_records()
	check(loaded.xp == earned, "corrupt main record recovers the last valid backup")
	check(loaded.award("c".repeat(24), summary, true), "recovered career can save again without losing its backup")
	for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(store.path + suffix))

func _navigation() -> void:
	var fixture := Node3D.new()
	root.add_child(fixture)
	for entry: Array in [[Vector3(30, 1, 30), Vector3(0, -0.5, 0)], [Vector3(4, 3, 0.4), Vector3(0, 1.5, 2)]]:
		var body := StaticBody3D.new()
		var collider := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = entry[0]
		collider.shape = box
		body.position = entry[1]
		body.add_child(collider)
		fixture.add_child(body)
	var actor := (load("res://game/player/player.tscn") as PackedScene).instantiate() as Player
	fixture.add_child(actor)
	actor.set_physics_process(false)
	await physics_frame
	actor.velocity = Vector3.DOWN
	actor.move_and_slide()
	var command := PlayerCommand.new()
	command.move = Vector2.DOWN
	command.aim_point = Vector3(0, 0.8, 10)
	command.attack_held = true
	var nav := BattleBotNavigation.new()
	nav.adjust(2, command, actor, _state(), 4)
	check(absf(command.move.x) > 0.9 and not command.attack_held, "CPU steers alongside cover and cannot fire through it")
	check(nav.queries <= 5, "cover and ground sensing stays bounded per ten-Hz decision")
	var count := nav.queries
	nav.adjust(2, command, actor, _state(), 5)
	check(nav.queries == count, "intervening physics ticks reuse cached sensing")
	nav.clear()
	check(nav._moves.is_empty() and nav._shoot.is_empty(), "migration clears stale CPU paths")
	fixture.queue_free()
	await process_frame

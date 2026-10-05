extends SceneTree
## Guest puzzle intents cross the fake-peer wire; the host owns each result.

const HOST := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
const GUEST := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
var rooms: Dictionary = {}
var failures: int = 0

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)

func ticks(count: int = 10) -> void:
	for index in count:
		await physics_frame
		await process_frame

func deliver(sender: String, recipient: String, data: Dictionary) -> void:
	rooms[recipient].receive({"type": "packet", "key": sender, "data": JSON.parse_string(JSON.stringify(data))})

func intent(dungeon: TofuDungeon, action: TofuPuzzleCommand.Action, target: String, object_id: String, sequence: int) -> TofuPuzzleCommand:
	var command := TofuPuzzleCommand.new()
	command.action = action
	command.target_id = target
	command.object_id = object_id
	command.run_id = dungeon.puzzle.run_id
	command.attempt_id = dungeon.puzzle.attempt_id
	command.sequence = sequence
	command.expected_revision = dungeon.puzzle.sorting.revision
	return command

func run() -> void:
	var sessions: Dictionary = {}
	for key in [HOST, GUEST]:
		var room := PlaytestRoom.new()
		room.local_key = key
		room.send_packet = func(recipient: String, data: Dictionary) -> void: deliver(key, recipient, data)
		rooms[key] = room
		root.add_child(room)
	rooms[HOST].peers[GUEST] = {"name": "Guest", "hosting": false, "busy": false}
	rooms[GUEST].peers[HOST] = {"name": "Host", "hosting": true, "busy": false}
	rooms[HOST].create_room()
	rooms[GUEST].join_room(HOST)
	rooms[HOST].begin()
	for key in [HOST, GUEST]:
		var viewport := SubViewport.new()
		viewport.own_world_3d = true
		viewport.size = Vector2i(960, 540)
		root.add_child(viewport)
		var game: Node3D = load("res://game/app/adventure/main.tscn").instantiate()
		game.play_opening = false
		viewport.add_child(game)
		var session := CoopSession.new()
		session.game = game
		session.room = rooms[key]
		game.add_child(session)
		sessions[key] = session
		game.shooting_view.local_input.enabled = false
	await ticks(20)
	var host: CoopSession = sessions[HOST]
	var guest: CoopSession = sessions[GUEST]
	check(guest._synchronized, "guest receives revised factory state")
	var actor: Player = host.roster.party[GUEST].actor
	actor.relocate(TofuFactory.EAST_ENTRANCE)
	await ticks(15)
	check(host.game.factory_dungeon.actor_in_run(actor), "host records guest membership")
	check(guest.game.factory_dungeon.actor_in_run(guest.game.player), "guest snapshot carries run membership")
	actor.relocate(TofuFactory.object_position("sack_mature") + Vector3(0, 0.05, 1.5))
	await ticks(3)
	var pick := intent(guest.game.factory_dungeon, TofuPuzzleCommand.Action.PICK_UP, "sack_mature", "", 1)
	guest.game.factory_dungeon.puzzle_command_requested.emit(pick)
	await ticks(6)
	check(host.game.factory_dungeon.puzzle.sorting.carried_by.has("sack_mature"), "guest pickup commits on host")
	actor.relocate(TofuFactory.object_position("intake_tofu") + Vector3(0, 0.05, 1.5))
	await ticks(3)
	var load_command := intent(guest.game.factory_dungeon, TofuPuzzleCommand.Action.LOAD_INTAKE, "intake_tofu", "sack_mature", 2)
	guest.game.factory_dungeon.puzzle_command_requested.emit(load_command)
	await ticks(6)
	check(host.game.factory_dungeon.puzzle.sorting.assignments.has("sack_mature"), "guest load commits once")
	var revision: int = host.game.factory_dungeon.puzzle.sorting.revision
	guest.game.factory_dungeon.puzzle_command_requested.emit(load_command)
	await ticks(6)
	check(host.game.factory_dungeon.puzzle.sorting.revision == revision and host.game.factory_dungeon.puzzle.mistakes == 0, "replayed guest packet creates no wave")
	await acceptance_cases(host, guest, actor)
	var collision_key: String = "bbbbbbb" + "c".repeat(57)
	var known_id: int = DungeonActorIdentity.get_id(host.game.factory_dungeon, GUEST)
	var collision_id: int = DungeonActorIdentity.get_id(host.game.factory_dungeon, collision_key)
	check(known_id > 1 and collision_id > 1 and known_id != collision_id, "same-prefix authenticated keys receive distinct puzzle IDs")
	await ticks(10)
	check(DungeonActorIdentity.get_id(guest.game.factory_dungeon, collision_key) == collision_id, "guest reads authority identity allocation")
	check(DungeonActorIdentity.get_id(guest.game.factory_dungeon, "d".repeat(64)) == 0, "guest cannot allocate authoritative puzzle identity")
	var checkpoint: Dictionary = JSON.parse_string(JSON.stringify(CoopCheckpoint.capture(host)))
	check(CoopCheckpoint.valid(checkpoint), "revised host checkpoint validates")
	var malformed: Dictionary = checkpoint.duplicate(true)
	malformed.world.factory.puzzle.sorting.assignments = {"sack_mature": "intake_freezer"}
	check(not CoopCheckpoint.valid(malformed), "checkpoint rejects semantically wrong sack assignment")
	malformed = checkpoint.duplicate(true)
	malformed.world.factory.puzzle.press.certificates = [true]
	check(not CoopCheckpoint.valid(malformed), "checkpoint rejects malformed certificate roster")
	var restored := TofuDungeonAttempt.new()
	check(restored.restore(checkpoint.world.factory.puzzle), "JSON checkpoint restores production state")
	check(restored.mistakes == host.game.factory_dungeon.puzzle.mistakes and restored.sorting.assignments == host.game.factory_dungeon.puzzle.sorting.assignments, "checkpoint retains mistakes and accepted assignment")
	await resumed_checkpoint(checkpoint)
	print("Tofu active co-op: ", "PASS" if failures == 0 else "FAIL")
	for child: Node in root.get_children(): child.queue_free()
	await process_frame
	for drain in 4:
		await physics_frame
		await process_frame
	quit(1 if failures else 0)

func acceptance_cases(host: CoopSession, guest: CoopSession, actor: Player) -> void:
	var dungeon: TofuDungeon = host.game.factory_dungeon
	var local: CoopActor = host.roster.party[HOST]
	local.actor.relocate(TofuFactory.EAST_ENTRANCE)
	await ticks(15)
	check(dungeon.actor_in_run(local.actor), "host enters same run")
	var sack_at: Vector3 = TofuFactory.object_position("sack_edamame") + Vector3(0, 0.05, 1.5)
	actor.relocate(sack_at)
	local.actor.relocate(sack_at + Vector3(0.8, 0, 0))
	await ticks(3)
	var contested := intent(guest.game.factory_dungeon, TofuPuzzleCommand.Action.PICK_UP, "sack_edamame", "", 3)
	var rival := intent(dungeon, TofuPuzzleCommand.Action.PICK_UP, "sack_edamame", "", 1)
	guest.game.factory_dungeon.puzzle_command_requested.emit(contested)
	dungeon.submit_puzzle(rival, local.actor)
	await ticks(6)
	check(dungeon.puzzle.sorting.carried_by.size() == 1 and dungeon.puzzle.sorting.carried_by.has("sack_edamame"), "simultaneous ownership claims reserve one sack")
	check(dungeon.puzzle.sorting.carried_by.get("sack_edamame") == DungeonMembership.actor_id(dungeon, actor), "first authenticated guest owns contested sack")
	var revision: int = dungeon.puzzle.sorting.revision
	var stale := intent(guest.game.factory_dungeon, TofuPuzzleCommand.Action.RETURN_PROP, "sack_edamame", "", 4)
	stale.expected_revision = revision - 1
	guest.game.factory_dungeon.puzzle_command_requested.emit(stale)
	await ticks(4)
	check(dungeon.puzzle.sorting.revision == revision and dungeon.puzzle.mistakes == 0, "stale revision cannot release sack or spawn enemies")
	var malicious: Dictionary = CoopPuzzleBridge.encode(stale)
	malicious["success"] = true
	rooms[GUEST].send_game(HOST, {"type": "tofu_puzzle", "command": malicious})
	await ticks(3)
	check(dungeon.puzzle.sorting.revision == revision and dungeon.puzzle.mistakes == 0 and dungeon._enemies.is_empty(), "client outcome flags are rejected without punishment")
	actor.relocate(TofuFactory.object_position("intake_oil") + Vector3(0, 0.05, 1.5))
	await ticks(3)
	var wrong := intent(guest.game.factory_dungeon, TofuPuzzleCommand.Action.LOAD_INTAKE, "intake_oil", "sack_edamame", 5)
	guest.game.factory_dungeon.puzzle_command_requested.emit(wrong)
	await ticks(6)
	check(dungeon.puzzle.mistakes == 1 and dungeon._enemies.size() == 3, "one committed error creates one fixed penalty roster")
	var encounter: String = dungeon.puzzle.encounter_id
	guest.game.factory_dungeon.puzzle_command_requested.emit(wrong)
	await ticks(4)
	check(dungeon.puzzle.mistakes == 1 and dungeon._enemies.size() == 3, "penalty replay cannot escalate or multiply wave")
	var member: CoopActor = host.roster.party[GUEST]
	var inventory: Array = member.inventory.capture()
	member.health.invulnerability = 0
	member.health.damage(100000)
	await ticks(2)
	check(member.spectating and member.health.current == 0, "individual dungeon death spectates without health reset")
	check(member.inventory.capture() == inventory, "dungeon death retains personal inventory")
	var blocked := intent(guest.game.factory_dungeon, TofuPuzzleCommand.Action.PICK_UP, "sack_edamame", "", 6)
	guest.game.factory_dungeon.puzzle_command_requested.emit(blocked)
	await ticks(3)
	check(dungeon.puzzle.sorting.carried_by.is_empty(), "dead actor cannot queue a production request")
	local.health.invulnerability = 0
	local.health.damage(100000)
	await ticks(4)
	check(not member.spectating and not local.spectating and member.health.current > 0, "full wipe restores encounter participants")
	check(dungeon.puzzle.encounter_id == encounter and dungeon.puzzle.mistakes == 1 and dungeon._enemies.size() == 3, "full wipe reuses encounter and preserves escalation")
	for enemy: FactoryBean in dungeon._enemies:
		check(enemy.target.current == enemy.target.maximum, "full wipe restarts full enemy health")
	for enemy: FactoryBean in dungeon._enemies.duplicate(): enemy.target.damage(100000)
	await ticks(4)
	check(dungeon.puzzle.phase == TofuPuzzleContract.Phase.READY, "wave clear releases production")
	await press_cases(host, guest, actor)
	actor.relocate(sack_at)
	dungeon._recovery.seed(GUEST, sack_at, 0)
	await ticks(3)
	var carry := intent(guest.game.factory_dungeon, TofuPuzzleCommand.Action.PICK_UP, "sack_edamame", "", 12)
	guest.game.factory_dungeon.puzzle_command_requested.emit(carry)
	await ticks(4)
	check(dungeon.puzzle.sorting.carried_by.has("sack_edamame"), "guest can resume after wipe")
	rooms[HOST].disconnect_member(GUEST, "QA disconnect")
	await ticks(4)
	check(dungeon.puzzle.sorting.carried_by.is_empty(), "disconnect returns carried quest sack to dock")
	check(GUEST in dungeon.state.run_members, "disconnect retains run membership")
	rooms[GUEST].join_room(HOST)
	rooms[GUEST].send_game(HOST, {"type": "ready"})
	await ticks(15)
	check(host.roster.party.has(GUEST), "same stable guest identity rejoins")
	check(guest.game.factory_dungeon.puzzle.mistakes == 1 and guest.game.factory_dungeon.puzzle.sorting.assignments.has("sack_mature"), "rejoin presents host puzzle and cumulative mistakes")
	if host.roster.party.has(GUEST):
		var returned: CoopActor = host.roster.party[GUEST]
		check(returned.inventory.capture() == inventory, "rejoin preserves retained inventory")
		check(dungeon.actor_in_run(returned.actor), "rejoin retains validated run membership")

func press_cases(host: CoopSession, guest: CoopSession, actor: Player) -> void:
	var dungeon: TofuDungeon = host.game.factory_dungeon
	# Build a cleared-station fixture; all operations below cross the real peer wire.
	var original: Dictionary = dungeon.puzzle.capture(true)
	dungeon.puzzle.sorting.assignments = {"sack_edamame": "intake_chilled", "sack_mature": "intake_tofu", "sack_high_fat": "intake_oil"}
	dungeon.puzzle.lab.opening_cleared = true
	dungeon.puzzle.stage = TofuPuzzleContract.Stage.LAB
	dungeon.state.stage = 1
	dungeon.factory.reset_gates(1)
	var terminal_at: Vector3 = TofuFactory.object_position("lab_terminal") + Vector3(0, 0.05, 1.5)
	actor.relocate(terminal_at)
	dungeon._recovery.seed(GUEST, terminal_at, 1)
	host.game.player.relocate(TofuFactory.recovery_anchor(1))
	dungeon._recovery.seed(HOST, host.game.player.global_position, 1)
	await ticks(12)
	var local_edge := PlayerCommand.new()
	local_edge.pickup_pressed = true
	CoopLocalMenus.sample(guest, local_edge)
	check(not local_edge.pickup_pressed and guest.game.factory_dungeon.puzzle_views.terminal.visible, "guest local E opens terminal and consumes shared pickup edge")
	await ticks(10)
	var terminal: DungeonTerminalView = guest.game.factory_dungeon.puzzle_views.terminal
	var before_password: int = dungeon.puzzle.mistakes
	terminal._field.text = "wrong operator"
	terminal._submit_password()
	await ticks(36)
	check(not terminal._submit.disabled and not dungeon.puzzle.lab.formula_unlocked and dungeon.puzzle.mistakes == before_password, "guest rejected password enables retry without a penalty")
	terminal._field.text = " ToFuFu "
	terminal._submit_password()
	await ticks(12)
	check(dungeon.puzzle.lab.formula_unlocked and guest.game.factory_dungeon.puzzle.lab.formula_unlocked, "guest terminal password commits only on host and returns through snapshot")
	check(terminal._formula.text.contains("Nigari"), "guest terminal presents authoritative unlocked formula")
	guest.game.factory_dungeon.puzzle_views.close()
	dungeon.puzzle.lab.formula_unlocked = true
	dungeon.puzzle.lab.complete = true
	dungeon.puzzle.stage = TofuPuzzleContract.Stage.PRESS
	dungeon.state.stage = 2
	dungeon.factory.reset_gates(2)
	var at: Vector3 = TofuFactory.object_position("traditional_press") + Vector3(0, 0.05, 1.5)
	actor.relocate(at)
	dungeon._recovery.seed(GUEST, at, 2)
	host.game.player.relocate(at + Vector3(1.2, 0, 0))
	dungeon._recovery.seed(HOST, host.game.player.global_position, 2)
	await ticks(10)
	var start := intent(guest.game.factory_dungeon, TofuPuzzleCommand.Action.START_PRESS, "traditional_press", "soft", 8)
	start.expected_revision = guest.game.factory_dungeon.puzzle.press.revision
	guest.game.factory_dungeon.puzzle_command_requested.emit(start)
	await ticks(10)
	var authority_press: TofuPressRules = dungeon.puzzle.press
	var replica_press: TofuPressRules = guest.game.factory_dungeon.puzzle.press
	check(authority_press.lease_actor == DungeonMembership.actor_id(dungeon, actor), "guest owns active station lease")
	check(replica_press.lease_actor == authority_press.lease_actor and replica_press.revision == authority_press.revision, "live guest snapshot retains press ownership and revision")
	var rival := intent(dungeon, TofuPuzzleCommand.Action.START_PRESS, "traditional_press", "firm", 2)
	rival.expected_revision = authority_press.revision
	check(not dungeon.submit_puzzle(rival, host.game.player).accepted, "second actor cannot replace active press lease")
	var stone := intent(guest.game.factory_dungeon, TofuPuzzleCommand.Action.PLACE_STONE, "traditional_press", "stone_1", 9)
	stone.expected_revision = replica_press.revision
	guest.game.factory_dungeon.puzzle_command_requested.emit(stone)
	await ticks(10)
	check(authority_press.stones == ["stone_1"], "guest places stone using replicated revision")
	var restored := TofuDungeonAttempt.new()
	check(restored.restore(JSON.parse_string(JSON.stringify(dungeon.puzzle.capture()))), "unfinished trial checkpoint is valid")
	check(restored.press.lease_actor == 0 and restored.press.active_sample == -1 and not restored.press.certificates[0], "reload cancels unfinished press without a certificate")
	dungeon.puzzle_runtime.release_actor(actor)
	check(authority_press.lease_actor == 0 and not authority_press.certificates[0], "release returns unfinished press curds")
	# Modern timing uses a controlled authority clock so packet latency is explicit.
	authority_press.certificates = [true, true, false]
	at = TofuFactory.object_position("modern_press") + Vector3(0, 0.05, 1.5)
	actor.relocate(at)
	dungeon._recovery.seed(GUEST, at, 2)
	await ticks(10)
	var modern := intent(guest.game.factory_dungeon, TofuPuzzleCommand.Action.START_PRESS, "modern_press", "", 10)
	modern.expected_revision = guest.game.factory_dungeon.puzzle.press.revision
	guest.game.factory_dungeon.puzzle_command_requested.emit(modern)
	await ticks(36)
	check(authority_press.active_sample == TofuPressRules.Sample.EXTRA_FIRM, "guest starts modern precision trial")
	dungeon.puzzle_clock = authority_press.started_at + 6.72
	var stop := intent(guest.game.factory_dungeon, TofuPuzzleCommand.Action.STOP_PRESS, "modern_press", "", 11)
	stop.expected_revision = guest.game.factory_dungeon.puzzle.press.revision
	guest.game.factory_dungeon.puzzle_command_requested.emit(stop)
	await ticks(8)
	check(authority_press.certificates[2] and dungeon.puzzle.stage == TofuPuzzleContract.Stage.CUT, "guest stop certifies using authority time")
	check(dungeon.puzzle.restore(original, true), "restore original sorting fixture after press checks")
	dungeon.state.stage = 0
	dungeon.factory.reset_gates(0)
	host.game.player.relocate(TofuFactory.HALL_ARRIVAL)
	dungeon._recovery.seed(HOST, TofuFactory.HALL_ARRIVAL, 0)

func resumed_checkpoint(checkpoint: Dictionary) -> void:
	var room := PlaytestRoom.new()
	room.local_key = HOST
	room.host_key = HOST
	room.hosting = true
	room.playing = true
	room.epoch = "0123456789abcdef0123456789abcdef"
	room.members = [HOST, GUEST]
	room.send_packet = func(_recipient: String, _data: Dictionary) -> void: pass
	root.add_child(room)
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.size = Vector2i(960, 540)
	root.add_child(viewport)
	var game: Node3D = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	viewport.add_child(game)
	var session := CoopSession.new()
	session.game = game
	session.room = room
	session.checkpoint = checkpoint
	game.add_child(session)
	await ticks(6)
	check(game.factory_dungeon.puzzle.mistakes == 1 and game.factory_dungeon.puzzle.sorting.assignments.has("sack_mature"), "fresh host composition resumes committed puzzle checkpoint")
	var ledger: Dictionary = game.factory_dungeon.rewards.capture()
	check(ledger.paid == checkpoint.world.factory.reward_ledger.paid and ledger.entitled == checkpoint.world.factory.reward_ledger.entitled and int(ledger.version) == int(checkpoint.world.factory.reward_ledger.version), "resumed host retains persistent reward claim ledger")
	check(game.factory_dungeon.actor_in_run(session.roster.party[GUEST].actor), "restored character keeps run membership")
	for key: String in checkpoint.world.factory.actor_ids:
		check(int(game.factory_dungeon.actor_ids.get(key, 0)) == int(checkpoint.world.factory.actor_ids[key]), "resumed host preserves allocated identity " + key.left(8))
	check(session.roster.party[GUEST].inventory.capture() == checkpoint.party[GUEST].inventory, "resumed checkpoint preserves guest bag")

extends SceneTree
## Real fake-peer boss membership, full wipe, late join and durable entitlements.

const HOST := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
const GUEST := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
const LATE := "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"
var rooms: Dictionary = {}
var sessions: Dictionary = {}
var failures: int = 0

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)

func ticks(count: int) -> void:
	for tick in count:
		await physics_frame
		await process_frame

func deliver(sender: String, recipient: String, data: Dictionary) -> void:
	rooms[recipient].receive({"type": "packet", "key": sender, "data": JSON.parse_string(JSON.stringify(data))})

func add_world(key: String) -> void:
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.size = Vector2i(960, 540)
	root.add_child(viewport)
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	viewport.add_child(game)
	var session := CoopSession.new()
	session.game = game
	session.room = rooms[key]
	game.add_child(session)
	sessions[key] = session
	game.shooting_view.local_input.enabled = false

func boss_fixture(dungeon: TofuDungeon, attempt: int) -> void:
	dungeon.puzzle_flow.reset_encounter(dungeon)
	dungeon.puzzle.configure(1, attempt, 42)
	dungeon.puzzle.sorting.assignments = {"sack_edamame": "intake_chilled", "sack_mature": "intake_tofu", "sack_high_fat": "intake_oil"}
	dungeon.puzzle.lab.opening_cleared = true
	dungeon.puzzle.lab.formula_unlocked = true
	dungeon.puzzle.lab.complete = true
	dungeon.puzzle.press.certificates = [true, true, true]
	dungeon.puzzle.cut.issue_block(dungeon.puzzle.batch_id + "_block", 6.0)
	dungeon.puzzle.cut.commit(dungeon.puzzle.cut.block_id, [1.0, 2.0, 3.0, 4.0, 5.0], dungeon.puzzle.cut.revision)
	dungeon.puzzle.pack.begin_batch(dungeon.puzzle.batch_id)
	for index in 6:
		dungeon.puzzle.pack.reserve(index, 1, dungeon.puzzle.pack.revision)
		dungeon.puzzle.pack.place(index, index, 1, dungeon.puzzle.pack.revision)
		dungeon.puzzle.pack.seal(index, dungeon.puzzle.pack.revision)
	dungeon.puzzle.stage = TofuPuzzleContract.Stage.BOSS
	dungeon.puzzle.phase = TofuPuzzleContract.Phase.COMBAT
	dungeon.puzzle.encounter_id = "dofufu_boss"
	dungeon.state.stage = 5
	dungeon.state.completed = false
	dungeon.state.active = true
	dungeon.boss_members.clear()
	dungeon.factory.reset_gates(5)
	DungeonArena.enter(dungeon)

func boss(dungeon: TofuDungeon) -> Dofufu:
	return dungeon._enemies[0] as Dofufu if dungeon._enemies.size() == 1 else null

func run() -> void:
	for key: String in [HOST, GUEST, LATE]:
		var room := PlaytestRoom.new()
		room.local_key = key
		room.send_packet = func(recipient: String, data: Dictionary) -> void: deliver(key, recipient, data)
		rooms[key] = room
		root.add_child(room)
	for key: String in [GUEST, LATE]:
		rooms[HOST].peers[key] = {"name": key.left(8), "hosting": false, "busy": false}
		rooms[key].peers[HOST] = {"name": "Host", "hosting": true, "busy": false}
	rooms[HOST].create_room()
	rooms[GUEST].join_room(HOST)
	rooms[HOST].begin()
	add_world(HOST)
	add_world(GUEST)
	await ticks(15)
	var host: CoopSession = sessions[HOST]
	var dungeon: TofuDungeon = host.game.factory_dungeon
	dungeon.factory.ensure_interior()
	for key: String in [HOST, GUEST]:
		DungeonMembership.enter(dungeon, host.roster.party[key].actor)
	boss_fixture(dungeon, 1)
	await ticks(5)
	check(boss(dungeon) != null and boss(dungeon).target.maximum == 1200, "initial two participants freeze boss at1200HP")
	rooms[LATE].join_room(HOST)
	add_world(LATE)
	await ticks(15)
	var late: CoopActor = host.roster.party[LATE]
	late.actor.relocate(TofuFactory.EAST_ENTRANCE)
	await ticks(8)
	check(not dungeon.actor_in_run(late.actor) and LATE not in dungeon.boss_members, "late guest waits outside active boss")
	check(boss(dungeon).target.maximum == 1200 and dungeon.boss_members.size() == 2, "late join cannot change existing boss scale")
	rooms[HOST].disconnect_member(GUEST, "Boss participant disconnected")
	await ticks(5)
	check(GUEST in dungeon.boss_members, "disconnect retains frozen boss entitlement identity")
	boss(dungeon).target.invulnerability = 0
	boss(dungeon).target.damage(100000)
	await ticks(8)
	check(dungeon.rewards.refinery_unlocked(HOST) and dungeon.rewards.refinery_unlocked(GUEST), "confirmed defeat unlocks disconnected participant")
	check(not dungeon.rewards.refinery_unlocked(LATE) and not sessions[LATE].game.inventory.refining_unlocked, "uninvolved late join receives no refinery entitlement")
	var checkpoint: Dictionary = JSON.parse_string(JSON.stringify(CoopCheckpoint.capture(host)))
	check(CoopCheckpoint.valid(checkpoint), "completed boss participant entitlement checkpoint validates")
	var ledger := TofuRewardLedger.new()
	check(ledger.restore(checkpoint.world.factory.reward_ledger) and ledger.refinery_unlocked(GUEST), "disconnected unlock persists in host checkpoint")
	# Rejoining the entitled guest reads host state through the actual room wire.
	rooms[GUEST].join_room(HOST)
	rooms[GUEST].send_game(HOST, {"type": "ready"})
	await ticks(15)
	check(host.roster.party[GUEST].inventory.refining_unlocked and sessions[GUEST].game.inventory.refining_unlocked, "rejoined completed participant restores refinery unlock")
	rooms[HOST].disconnect_member(GUEST, "Wipe fixture uses host and waiting guest")
	await ticks(4)
	# Remove the waiting actor from any completed-run portal admission.
	DungeonMembership.exit(dungeon, late.actor)
	late.actor.relocate(TofuFactory.EAST_ENTRANCE)
	boss_fixture(dungeon, 2)
	await ticks(5)
	check(boss(dungeon).target.maximum == 800 and dungeon.boss_members == [HOST], "new solo encounter starts at800HP")
	check(not dungeon.actor_in_run(late.actor), "waiting peer remains outside restarted active encounter")
	var hp := host.roster.party[HOST].health as Damageable
	hp.invulnerability = 0
	hp.damage(100000)
	await ticks(6)
	check(dungeon.actor_in_run(late.actor) and HOST in dungeon.boss_members and LATE in dungeon.boss_members, "full wipe admits waiting alive guest into new fight")
	check(boss(dungeon) != null and boss(dungeon).target.maximum == 1200 and boss(dungeon).target.current == 1200, "new encounter freezes fresh two-person scaling at fullHP")
	check(not dungeon.rewards.refinery_unlocked(LATE), "admitted guest must complete restarted boss to unlock")
	var host_exp: int = host.roster.party[HOST].progression.progress.experience
	var late_exp: int = late.progression.progress.experience
	boss(dungeon).target.damage(100000)
	await ticks(8)
	check(host.roster.party[HOST].progression.progress.experience == host_exp and late.progression.progress.experience == late_exp, "paid boss rematch grants no repeated EXP")
	check(dungeon.rewards.refinery_unlocked(LATE), "new participating guest gains unlock after confirmed defeat")
	var count: int = 0
	for drop: WorldItemDrop in host.game.world_items.pool.drops.values():
		if drop.item_id == "mature_bean": count += drop.count
	check(count == 10, "paid boss rematch cannot mint a second shared currency stack")
	print("Tofu boss co-op participants: ", "PASS" if failures == 0 else "FAIL")
	for child: Node in root.get_children(): child.queue_free()
	await process_frame
	# Audio playback releases its stream on the mixer thread after nodes leave.
	for drain in 4:
		await physics_frame
		await process_frame
	quit(1 if failures else 0)

extends SceneTree
## Actual JSON-wire host/guest intent, late state, spells and one-time reward ownership.

class QuietInput extends PlayerCommandSource:
	func sample(_position: Vector3) -> PlayerCommand: return PlayerCommand.new()

const HOST := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
const GUEST := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func ticks(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func scene(room: PlaytestRoom) -> CoopSession:
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	root.add_child(viewport)
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	viewport.add_child(game)
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	var session := CoopSession.new()
	session.game = game
	session.room = room
	game.add_child(session)
	return session

func _run() -> void:
	var host := PlaytestRoom.new()
	var guest := PlaytestRoom.new()
	root.add_child(host)
	root.add_child(guest)
	host.local_key = HOST
	guest.local_key = GUEST
	host.peers[GUEST] = {"name": "Guest", "hosting": false, "busy": false}
	guest.peers[HOST] = {"name": "Host", "hosting": true, "busy": false}
	host.send_packet = func(_key: String, data: Dictionary) -> void: guest.receive({"type": "packet", "key": HOST, "data": JSON.parse_string(JSON.stringify(data))})
	guest.send_packet = func(_key: String, data: Dictionary) -> void: host.receive({"type": "packet", "key": GUEST, "data": JSON.parse_string(JSON.stringify(data))})
	host.create_room()
	guest.join_room(HOST)
	host.begin()
	var hs := scene(host)
	var gs := scene(guest)
	hs.roster.local_input.enabled = false
	var quiet := QuietInput.new()
	root.add_child(quiet)
	gs.roster.local_input = quiet
	await ticks(18)
	var castle: CastleAdventure = hs.game.castle_adventure
	var replica: CastleAdventure = gs.game.castle_adventure
	var member: CoopActor = hs.roster.party[GUEST]
	for guard in castle.encounter.guards:
		guard.set_physics_process(false)
		guard.spells.set_physics_process(false)
	var chest := castle.treasure.chest(0)
	member.actor.relocate(chest.global_position + chest.global_basis.z * 1.8 + Vector3.UP * 0.1)
	await ticks(10)
	var treasure_command := PlayerCommand.new()
	treasure_command.pickup_pressed = true
	treasure_command.castle_action = 13
	treasure_command.castle_revision = castle.state.revision
	var treasure_wire := CoopValues.input(treasure_command, hs._sequence + 1, 0)
	hs._packet(GUEST, JSON.parse_string(JSON.stringify(treasure_wire)))
	await ticks(30)
	check(member.inventory.count_item("golden_tofu_chunk") == 3, "authenticated guest chest intent grants three chunks on the host")
	check(replica.state.opened_chests == 1 and replica.state.treasure_claimed(GUEST, 0) and replica.treasure.chest(0).opened, "shared opening and per-character treasure entitlement synchronize")
	check(gs.roster.party[GUEST].inventory.count_item("golden_tofu_chunk") == 3, "guest inventory receives its authoritative treasure grant")
	treasure_wire.sequence = hs._sequence + 1
	hs._packet(GUEST, treasure_wire)
	await ticks(3)
	check(member.inventory.count_item("golden_tofu_chunk") == 3, "replayed chest command cannot duplicate loot")
	hs.game.player.relocate(chest.global_position + chest.global_basis.z * 1.8 + Vector3.UP * 0.1)
	await ticks(2)
	check(castle.treasure.claim(hs.game.player, 0), "another living adventurer can claim their own share of an already opened chest")
	castle.present_state()
	var personal := castle.capture()
	var solo_state := CastleTrialState.new()
	solo_state.restore(personal.trial)
	check(solo_state.treasure_claimed("solo", 0) and not solo_state.claim_treasure("solo", 0), "personal save preserves claimed treasure when returning from co-op to offline play")
	check(castle.state.treasure_claimed(HOST, 0) and not castle.state.treasure_claims.has("solo"), "personal serialization leaves the live world identity ledger intact")
	check(CastleSaveValidation.valid(personal), "canonical personal treasure ledger remains save-valid")
	for actor_member: CoopActor in hs.roster.party.values():
		check(castle.encounter.king.target in actor_member.combat.targets and castle.encounter.guards[0].target in actor_member.combat.targets, "world registration retains castle targets for every party member")
	member.actor.relocate(castle.focus_position(0) - Vector3.UP + Vector3(0, 0.1, 1))
	await ticks(10)
	var command := PlayerCommand.new()
	command.pickup_pressed = true
	command.castle_action = 0
	command.castle_revision = castle.state.revision
	var wire := CoopValues.input(command, hs._sequence + 1, 0)
	hs._packet(GUEST, JSON.parse_string(JSON.stringify(wire)))
	await ticks(3)
	check(castle.state.lever_bits == 3, "authenticated guest castle input changes the host puzzle")
	await ticks(6)
	check(replica.castle.floors[0].trial.feedback.pulse > 0 and replica.castle.floors[0].trial.feedback.selected == 0, "guest sees the pressed glyph acknowledgement after the initial join")
	await ticks(28)
	check(replica.state.lever_bits == 3, "royal wards synchronize over world snapshots")
	check(replica.state.last_action == 0 and replica.state.accepted and replica.state.feedback_revision == castle.state.feedback_revision, "acknowledged glyph press synchronizes with its dedicated feedback revision")
	wire.sequence = hs._sequence + 1
	hs._packet(GUEST, wire)
	await ticks(3)
	check(castle.state.lever_bits == 3, "a fresh packet with stale puzzle revision is rejected")
	var sentinel := castle.encounter.guards[0]
	sentinel.tactics.shield = 0.5
	sentinel.tactics.dash_direction = Vector3.RIGHT
	sentinel.tactics.dash_cooldown = 2
	sentinel.spells.bolt(sentinel.global_position + Vector3.UP * 1.15, Vector3.BACK, 18)
	await ticks(35)
	check(replica.encounter.guards[0].tactics.shield == 0.5 and replica.encounter.guards[0].spells.bolts.size() == 1, "guardian combat stance and ranged spell records synchronize")
	check(not replica.encounter.guards[0].authoritative and not replica.encounter.guards[0].spells.authoritative, "guest guardian spells remain cosmetic")
	for action in [1, 6, 4, 7, 5, 8, 9, 9, 10, 10, 10, 11]: castle.state.operate(action)
	for guard in castle.encounter.guards: guard.target.damage(1000)
	castle.present_state()
	for player: Player in [hs.game.player, member.actor]: player.relocate(castle.castle.to_global(Vector3(0, 24.1, 17)))
	castle.state.introduced = true
	castle.encounter.begin()
	await ticks(75)
	check(CastleProtocol.valid(castle.capture(true), true), "active authority castle schema is valid")
	check(replica.state.message == castle.state.message, "king narrative and puzzle feedback synchronize to all participants")
	check(replica.state.all_open() and replica.encounter.king.active, "late world application opens all seals and presents the running king battle")
	check(castle.state.participants.size() == 2 and castle.encounter.king.target.maximum == 1760, "co-op challenge scales once for its two fixed participants")
	castle.encounter.king.set_physics_process(false)
	castle.encounter.king.spells.set_physics_process(false)
	castle.encounter.king.spells.clear()
	castle.encounter.king.cycle = 4
	castle.encounter.king._windup(Vector3.FORWARD)
	castle.encounter.king._release()
	castle.encounter.king._physics_process(0.01)
	await ticks(35)
	check(replica.encounter.king.skill == 4 and replica.encounter.king.burst == 2 and replica.encounter.king.spells.bolts.size() == 1 and replica.encounter.king.spells.bolts[0][7] == 1, "locked rapid chunk burst and chunk visuals synchronize through the real JSON transport")
	member.health.invulnerability = 0
	castle.party.hurt(member.actor, 1, castle.encounter.king.global_position, true)
	await ticks(75)
	check(replica.party.burns.has(GUEST) and not replica.encounter.king.is_physics_processing(), "host-owned burning synchronizes without guest combat simulation")
	check(CoopCheckpoint.valid(CoopCheckpoint.capture(hs)), "active battle checkpoint contains bounded castle state")
	var health := replica.encounter.king.target.current
	check(not replica.encounter.king.target.damage(500) and replica.encounter.king.target.current == health, "guest king damage target rejects local outcomes")
	castle.encounter.king.target.invulnerability = 0
	castle.encounter.king.target.damage(5000)
	await ticks(75)
	check(replica.state.completed and replica.encounter.king.pose == "defeat", "victory and kneeling art synchronize to the guest")
	check(castle.party.claim(member.actor) and not castle.party.claim(member.actor), "only an entitled participant can claim once")
	check(member.inventory.count_item("golden_tofu_chunk") == 4, "royal reward adds once to the guest's previously collected treasure")
	await ticks(75)
	check(replica.state.rewarded == [GUEST] and gs.roster.party[GUEST].inventory.count_item("golden_tofu_chunk") == 4, "claim ledger and inventory synchronize together")
	hs.get_parent().queue_free()
	gs.get_parent().queue_free()
	host.queue_free()
	guest.queue_free()
	quiet.queue_free()
	await ticks(4)
	print("Co-op castle: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

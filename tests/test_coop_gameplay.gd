extends SceneTree
## Guest commands cross the room boundary; only host collision/health rules run.

var failures: int = 0
var host: PlaytestRoom
var guest: PlaytestRoom
var host_game: Node3D
var guest_game: Node3D
var host_session: CoopSession
var guest_session: CoopSession
var input: CoopTestInput
const HOST := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
const GUEST := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	host = PlaytestRoom.new()
	guest = PlaytestRoom.new()
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
	host_session = _game(host)
	guest_session = _game(guest)
	host_game = host_session.game
	guest_game = guest_session.game
	input = CoopTestInput.new()
	root.add_child(input)
	guest_session.roster.local_input = input
	(host_session.roster.local_input as LocalPlayerInput).enabled = false
	await ticks(15)
	var remote := host_session.roster.party[GUEST]
	var replica := guest_session.roster.party[GUEST]
	# Guest intent must collide on the host, then converge to that stopped pose.
	host_game.player.position = Vector3(0, 0.05, 2)
	remote.actor.position = Vector3(-2, 0.05, 2)
	remote.actor.velocity = Vector3.ZERO
	input.move = Vector2.RIGHT
	await ticks(50)
	check(remote.actor.position.x < host_game.player.position.x - 0.79, "guest movement cannot pass through host player")
	input.move = Vector2.ZERO
	await ticks(15)
	check(replica.actor.position.distance_to(remote.actor.position) < 0.15, "guest view converges to authoritative blocked position")
	host_game.player.position = Vector3(0, 0.05, 0)
	var dummy: PracticeDummy = host_game.encounters.dummy_nodes[0]
	remote.actor.position = dummy.position + Vector3(0, 0.05, 1.4)
	remote.actor.velocity = Vector3.ZERO
	await ticks(15)
	input.attack = true
	await ticks(12)
	input.attack = false
	await ticks(35)
	check(remote.progression.progress.practice.sword == 1 and replica.progression.progress.practice.sword == 1, "host awards guest sword practice and replicates it")
	check(host_game.progression.progress.practice.sword == 0, "guest practice does not train host")
	check(dummy.hit_count == 1, "guest knife hits exactly once through host collision queries")
	check(guest_game.encounters.dummy_nodes[0].target.current == dummy.target.current, "dummy health replicates")
	input.punch = true
	await ticks(4)
	input.punch = false
	await ticks(10)
	check(dummy.hit_count == 2, "guest punch runs on host")
	check(remote.progression.progress.practice.fist == 1 and replica.progression.progress.practice.fist == 1, "guest fist practice replicates")
	input.guard = true
	await ticks(30)
	remote.hurt(12, remote.actor.position + Vector3(0, 0, -1))
	check(remote.health.current == 100, "guest forward guard blocks damage")
	remote.hurt(12, remote.actor.position + Vector3(0, 0, 1))
	await ticks(10)
	check(remote.progression.progress.practice.defence == 1 and replica.progression.progress.practice.defence == 1, "only the successful guard trains defence")
	check(remote.health.current == 88 and replica.health.current == 88, "rear damage reaches guest health/HUD")
	input.guard = false
	input.drop = true
	await ticks(10)
	check(not remote.combat.equipment.knife_owned and is_instance_valid(replica.combat.equipment.dropped), "guest dropped knife appears on both peers")
	input.pickup = true
	await ticks(10)
	check(remote.combat.equipment.knife_owned and replica.combat.equipment.knife_owned, "guest retrieves own knife")
	var prop: HarvestProp = host_game.encounters.prop_nodes[0]
	prop.target.damage(999)
	await ticks(10)
	check(not guest_game.encounters.prop_nodes[0].visible and guest_game.encounters.props == 1, "shared harvest and world visibility")
	var bean: SoybeanPickup = host_game.encounters.add_pickup(host_game.encounters.next_pickup_id, remote.actor.position)
	bean._age = 1
	await ticks(35)
	check(remote.health.current == 100 and host_game.encounters.beans == 1, "nearest guest collects and heals exactly once")
	check(guest_game.encounters.beans == 1 and replica.health.current == 100, "loot outcome replicates")
	host_game.encounters.mob_nodes[0].target.damage(999)
	await ticks(10)
	check(guest_game.encounters.experience == 25 and not guest_game.encounters.mob_nodes[0].visible, "shared enemy death and EXP")
	check(remote.progression.progress.experience == 25 and host_game.progression.progress.experience == 25, "party EXP awards every active character once")
	check(replica.progression.progress.experience == 25, "guest character EXP survives world snapshot application")
	remote.health.invulnerability = 0
	remote.health.damage(999)
	await ticks(10)
	check(remote.health.current == 100 and remote.actor.position.x < 1, "guest defeat respawns safely")
	# Both directions of gun friendly fire cross real room JSON and host physics.
	remote = host_session.roster.party[GUEST]
	replica = guest_session.roster.party[GUEST]
	host_game.player.position = Vector3(0, 0.2, 2)
	remote.actor.position = Vector3(0, 0.2, -3)
	host_game.health.current = 100
	host_game.health.invulnerability = 0
	remote.health.current = 100
	remote.health.invulnerability = 0
	await ticks(12)
	input.aim = Vector2.DOWN
	input.aim_point = host_game.player.position + Vector3.UP * 0.55
	input.slot = 3
	input.guard = true
	input.attack = true
	await ticks(7)
	input.attack = false
	await ticks(15)
	check(host_game.health.current == 80, "guest soybean damages host for 20")
	check(guest_session.roster.party[HOST].health.current == 80, "host friendly-fire health replicates to guest")
	check(replica.combat.gun.selected, "guest gun slot is replicated")
	host_game.combat.gun.selected = true
	host_game.combat.equipment.knife_selected = false
	host_game.combat.gun.tuning.aim_spread_degrees = 0
	host_game.combat.gun.step(true, true, Vector2.UP, remote.actor.position + Vector3.UP * 0.98, 0.02)
	await ticks(18)
	check(remote.health.current == 60 and replica.health.current == 60, "host headshot damages guest for 40 and replicates")
	var saved := CoopCheckpoint.capture(host_session)
	check(CoopCheckpoint.valid(saved), "full checkpoint validates")
	var store := SaveStore.new()
	store.extra_validator = CoopCheckpoint.valid
	store.directory = "user://coop-test-%d" % Time.get_ticks_usec()
	var record := AdventureSnapshot.capture(host_game, "Co-op test", 12)
	record.coop = saved
	check(store.write_slot(0, record), "co-op checkpoint atomically saves")
	var loaded_progress := CharacterProgress.new()
	loaded_progress.restore(store.read_slot(0).coop.party[GUEST].progression)
	check(loaded_progress.capture() == remote.progression.progress.capture(), "guest skills and partial practice survive disk round trip")
	check(store.read_slot(0).coop.world.experience == 25, "co-op progress survives disk round trip")
	host_game.encounters.experience = 0
	CoopWorld.apply(host_game, saved.world, false)
	check(host_game.encounters.experience == 25, "world progress restores")
	var old_position := remote.actor.position
	guest.leave()
	await ticks(3)
	check(not host_session.roster.party.has(GUEST) and host_session.roster.saved_states.has(GUEST), "disconnect preserves character checkpoint")
	guest.join_room(HOST)
	await ticks(3)
	check(guest.playing and host_session.roster.party.has(GUEST), "join-in-progress accepted")
	check(host_session.roster.party[GUEST].progression.progress.capture() == saved.party[GUEST].progression, "rejoining restores guest progression without duplicate EXP")
	check(host_session.roster.actors[GUEST].position.distance_to(old_position) < 0.5, "reconnecting identity restores position")
	store.remove_slot(0)
	DirAccess.remove_absolute(store.directory)
	host.leave()
	check(not guest.playing, "host departure ends session")
	for child in root.get_children(): child.queue_free()
	await process_frame
	print("Co-op gameplay: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _game(room: PlaytestRoom) -> CoopSession:
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	root.add_child(viewport)
	var game: Node3D = load("res://game/app/main.tscn").instantiate()
	game.play_opening = false
	viewport.add_child(game)
	var session := CoopSession.new()
	session.game = game
	session.room = room
	game.add_child(session)
	return session

func ticks(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame

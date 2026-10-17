extends SceneTree
## JSON-wire personal claims on a player host and dedicated authority.

const HOST := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
const ONE := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
var failures: int = 0
var rooms: Dictionary = {}
var sessions: Dictionary = {}
var views: Array[SubViewport] = []

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func ticks(count: int = 8) -> void:
	for i in count:
		await physics_frame
		await process_frame

func deliver(sender: String, recipient: String, data: Dictionary) -> void:
	rooms[recipient].receive({"type": "packet", "key": sender, "data": JSON.parse_string(JSON.stringify(data))})

func run() -> void:
	for dedicated in [false, true]: await scenario(dedicated)
	print("Co-op soybean save spots: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func scenario(dedicated: bool) -> void:
	for key in [HOST, ONE]:
		var room := PlaytestRoom.new()
		room.local_key = key
		room.dedicated = dedicated and key == HOST
		room.send_packet = func(recipient: String, data: Dictionary) -> void: deliver(key, recipient, data)
		rooms[key] = room
		root.add_child(room)
	for key: String in rooms:
		for peer: String in rooms:
			if key != peer: rooms[key].peers[peer] = {"name": peer.left(1), "hosting": peer == HOST, "busy": false}
	rooms[HOST].create_room()
	rooms[ONE].join_room(HOST)
	rooms[HOST].begin()
	for key: String in rooms:
		var viewport := SubViewport.new()
		viewport.own_world_3d = true
		viewport.size = Vector2i(1280, 720)
		root.add_child(viewport)
		views.append(viewport)
		var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
		game.play_opening = false
		viewport.add_child(game)
		var session := CoopSession.new()
		session.game = game
		session.room = rooms[key]
		game.add_child(session)
		sessions[key] = session
		game.shooting_view.local_input.enabled = false
	await ticks(15)
	var host: CoopSession = sessions[HOST]
	var guest: CoopSession = sessions[ONE]
	var member: CoopActor = host.roster.party[ONE]
	var adapter := guest.get_node("SoySaveSpotSync") as CoopSoySaveSpots
	check(guest._synchronized, "guest synchronized")
	adapter.request(10)
	await ticks()
	check(member.soy_spots.mask == 0, "distant request grants no ownership")
	var at: Vector3 = host.game.soy_spots.spots[0].global_position
	member.actor.relocate(at + Vector3(0, 0.1, 1.6))
	await ticks()
	adapter.request(0)
	check(guest.game.soy_spots.ownership.mask == 0, "guest does not speculate ownership")
	await ticks()
	check(member.soy_spots.owns(0) and guest.game.soy_spots.ownership.owns(0), "authority grants and replicates the requester's unlock")
	check(host.game.soy_spots.ownership.mask == 0, "guest claim leaves the host's personal plants unowned")
	check(guest.game.soy_spots.spots[0].owned and not host.game.soy_spots.spots[0].owned, "each viewport presents its local personal state")
	var sync := host.get_node("SoySaveSpotSync") as CoopSoySaveSpots
	sync._packet(ONE, {"type": "soy_spot_claim", "sequence": 1, "spot": 1})
	await ticks()
	check(member.soy_spots.mask == 1, "replayed sequence cannot claim another spot")
	member.spectating = true
	member.actor.relocate(host.game.soy_spots.spots[1].position + Vector3(0, 0.1, 1.6))
	adapter.request(1)
	await ticks()
	check(member.soy_spots.mask == 1, "spectators cannot claim")
	member.spectating = false
	member.die()
	check(member.soy_spots.mask == 1, "co-op defeat preserves ownership")
	var checkpoint: Dictionary = JSON.parse_string(JSON.stringify(CoopCheckpoint.capture(host)))
	check(CoopCheckpoint.valid(checkpoint) and checkpoint.party[ONE].soy_spots == 1, "host checkpoint retains each personal unlock")
	member.soy_spots.mask = 0
	member.restore(checkpoint.party[ONE])
	check(member.soy_spots.mask == 1, "saved/rejoining party character restores ownership")
	var state: Dictionary = checkpoint.party[ONE].duplicate(true)
	state.erase("soy_spots")
	check(ExplorationProtocol.actor(state), "legacy actor record remains valid")
	member.restore(state)
	check(member.soy_spots.mask == 0, "legacy actor defaults to no ownership")
	for invalid in [-1, 2048, 0.5, "1", true]:
		state.soy_spots = invalid
		check(not ExplorationProtocol.actor(state), "malformed ownership rejected at actor boundary")
	for viewport in views: viewport.queue_free()
	for room: PlaytestRoom in rooms.values(): room.queue_free()
	await ticks(2)
	views.clear()
	rooms.clear()
	sessions.clear()

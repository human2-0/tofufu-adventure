extends SceneTree
## Two real worlds, JSON-wire admission, hostile intents and shared finite loot.

const HOST := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
const GUEST := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
var failures: int = 0
var rooms: Dictionary = {}
var sessions: Dictionary = {}
var viewports: Array[SubViewport] = []

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	if ok: return
	failures += 1
	printerr("FAIL: ", message)

func ticks(count: int = 12) -> void:
	for tick in count:
		await physics_frame
		await process_frame

func deliver(sender: String, recipient: String, data: Dictionary) -> void:
	rooms[recipient].receive({"type": "packet", "key": sender, "data": JSON.parse_string(JSON.stringify(data))})

func run() -> void:
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
		root.add_child(viewport)
		viewports.append(viewport)
		var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
		game.play_opening = false
		viewport.add_child(game)
		game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
		game.shooting_view.local_input.enabled = false
		var session := CoopSession.new()
		session.game = game
		session.room = rooms[key]
		game.add_child(session)
		sessions[key] = session
	await ticks(20)
	var host: CoopSession = sessions[HOST]
	var guest: CoopSession = sessions[GUEST]
	var member: CoopActor = host.roster.party[GUEST]
	var sync: CoopCityLoot
	var remote: CoopCityLoot
	for child in host.get_children():
		if child is CoopCityLoot: sync = child
	for child in guest.get_children():
		if child is CoopCityLoot: remote = child
	check(guest._synchronized and sync != null and remote != null, "real guest receives city interaction adapter")
	var chest: GigalopolisChest = host.game.city_loot.chests[5]
	remote.request(5)
	await ticks()
	check(host.game.city_loot.opened == 0, "distant authenticated guest request is rejected")
	member.actor.relocate(chest.global_position + Vector3(0, 0.08, 2))
	await ticks()
	check(not guest.game.city_loot.perform(guest.game.player, 5), "replica cannot mint loot locally")
	var count: int = host.game.world_items.pool.drops.size()
	remote.request(5)
	check(guest.game.city_loot.opened == 0, "guest does not speculate a chest opening")
	await ticks(25)
	check(host.game.city_loot.opened == (1 << 5) and guest.game.city_loot.opened == (1 << 5), "host opening synchronizes the shared mask")
	check(host.game.world_items.pool.drops.size() == count + 2, "guest intent creates exactly two host-owned supply stacks")
	check(guest.game.world_items.pool.drops.size() == host.game.world_items.pool.drops.size(), "guest receives the same remaining loot count")
	for id: int in host.game.world_items.pool.drops:
		var actual: WorldItemDrop = host.game.world_items.pool.drops[id]
		var replica: WorldItemDrop = guest.game.world_items.pool.drops.get(id)
		check(replica != null and replica.item_id == actual.item_id and replica.count == actual.count, "guest receives the exact shared item stacks")
	remote.request(5)
	sync._packet(GUEST, {"type": "city_chest_open", "sequence": 2, "chest": 5})
	await ticks()
	check(host.game.world_items.pool.drops.size() == count + 2, "duplicate/replayed claims cannot pay twice")
	member.actor.relocate(host.game.city_loot.chests[6].global_position + Vector3(0, 0.08, 2))
	await ticks()
	sync._packet("spoofed", {"type": "city_chest_open", "sequence": 100, "chest": 6})
	for invalid in [-1, 18, 0.5, "6", true, NAN]:
		sync._packet(GUEST, {"type": "city_chest_open", "sequence": 100, "chest": invalid})
	await ticks()
	check(host.game.city_loot.opened == (1 << 5), "invalid indices and unknown senders never mutate claims")
	member.spectating = true
	remote.request(6)
	await ticks()
	check(host.game.city_loot.opened == (1 << 5), "spectators cannot open city chests")
	member.spectating = false
	# Both members attempt the same second chest before the next authority tick.
	host.game.player.relocate(host.game.city_loot.chests[6].global_position + Vector3(1.4, 0.08, 1.8))
	sync.request(6)
	remote.request(6)
	await ticks(25)
	check(host.game.city_loot.opened == ((1 << 5) | (1 << 6)), "simultaneous requests open the shared chest once")
	check(host.game.world_items.pool.drops.size() == count + 4, "simultaneous requests create one supply allocation")
	var checkpoint: Dictionary = JSON.parse_string(JSON.stringify(CoopCheckpoint.capture(host)))
	check(CoopCheckpoint.valid(checkpoint) and checkpoint.world.city_loot == host.game.city_loot.opened, "host checkpoint validates and retains city claims")
	host.game.city_loot.restore(0)
	CoopWorld.apply(host.game, checkpoint.world, false)
	check(host.game.city_loot.opened == checkpoint.world.city_loot, "shared checkpoint restoration cannot respawn claimed supplies")
	var legacy: Dictionary = checkpoint.world.duplicate(true)
	legacy.erase("city_loot")
	check(WorldProtocol.valid(legacy), "older shared saves without city masks remain valid")
	for viewport in viewports: viewport.queue_free()
	for room: PlaytestRoom in rooms.values(): room.queue_free()
	await ticks(3)
	print("Co-op city supply chests: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

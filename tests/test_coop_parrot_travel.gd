extends SceneTree
## JSON-wire free flight, movement prediction, replay rejection and safe checkpoints.

const HOST := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
const GUEST := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if ok: return
	failures += 1
	printerr("FAIL: ", message)

func ticks(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame

func scene(room: PlaytestRoom) -> CoopSession:
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	root.add_child(viewport)
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	viewport.add_child(game)
	var session := CoopSession.new()
	session.game = game
	session.room = room
	game.add_child(session)
	return session

func _run() -> void:
	# Route lengths count physics ticks while also awaiting network presentation.
	Engine.max_physics_steps_per_frame = 1
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
	(hs.roster.local_input as LocalPlayerInput).enabled = false
	(gs.roster.local_input as LocalPlayerInput).enabled = false
	await ticks(15)
	var remote: CoopActor = hs.roster.party[GUEST]
	var replica: CoopActor = gs.roster.party[GUEST]
	var adapter := hs.get_node("CoopParrotTravel") as CoopParrotTravel
	gs.game.parrot_travel.controls.request_action.call("mount")
	await ticks(3)
	check(not remote.actor.transport_active, "host rejects boarding away from a parrot")
	var royal_shop: CloudResident = hs.game.world.cloud_realm.court.merchant
	remote.actor.relocate(royal_shop.global_position + Vector3(0, 0.1, 2))
	await ticks(15)
	var gear_before: int = remote.inventory.count_item("knife")
	gs.inventory_sync.request_purchase("knife")
	await ticks(15)
	check(remote.inventory.count_item("knife") == gear_before + 1, "host accepts a guest equipment purchase at the royal cloud merchant")
	check(replica.inventory.count_item("knife") == remote.inventory.count_item("knife"), "royal shop inventory replicates to the guest")
	remote.actor.relocate(hs.game.world.ground_point(royal_shop.position.x, royal_shop.position.z, 0.1))
	await ticks(15)
	gs.inventory_sync.request_purchase("knife")
	await ticks(10)
	check(remote.inventory.count_item("knife") == gear_before + 1, "host rejects cloud merchant purchases from directly below in the jungle")
	remote.actor.relocate(hs.game.parrot_travel.perches.stations[1].global_position + Vector3(0, 0.1, 3))
	await ticks(12)
	var origin := remote.actor.position
	var input := CoopTestInput.new()
	root.add_child(input)
	gs.roster.local_input = input
	gs.game.parrot_travel.controls.request_action.call("mount")
	await ticks(65)
	check(remote.actor.transport_active and replica.actor.transport_active, "boarding synchronizes the ridden parrot")
	input.move = Vector2.RIGHT
	var before := remote.actor.position
	await ticks(35)
	check(remote.actor.position.x > before.x + 8, "authenticated guest movement freely steers on the host")
	input.move = Vector2.UP
	await ticks(40)
	check(remote.actor.position.z < before.z - 5, "guest can change flight direction")
	input.move = Vector2.ZERO
	await ticks(20)
	check(replica.prediction.suspended and replica.actor.position.distance_to(remote.actor.position) < 5, "guest follows host-owned flying movement")
	check(gs.game.parrot_travel.flights.is_empty(), "guest cannot simulate authority flight outcomes")
	var saved := CoopCheckpoint.capture(hs)
	check(CoopCheckpoint.valid(saved) and CoopValues.vector3(saved.party[GUEST].position).is_equal_approx(origin), "mid-flight checkpoints keep safe ground")
	gs.game.parrot_travel.controls.request_action.call("land")
	await ticks(140)
	check(not remote.actor.transport_active and not replica.actor.transport_active and not replica.prediction.suspended, "landing restores host walking and guest prediction, host %s, outdoor %s, surface %s" % [remote.actor.position, ParrotLanding.outdoor(hs.game, remote.actor.global_position), ParrotLanding.surface(hs.game, remote.actor)])
	check(remote.actor.parrot_rest.is_finite() and replica.actor.parrot_rest.is_equal_approx(remote.actor.parrot_rest), "parked parrot position synchronizes")
	check(CoopCheckpoint.valid(CoopCheckpoint.capture(hs)), "parked parrot checkpoints are bounded and valid")
	var sequence: int = adapter._seen.get(GUEST, 0)
	adapter._packet(GUEST, {"type": "parrot_action", "sequence": sequence, "action": "mount"})
	adapter._packet(GUEST, {"type": "parrot_action", "sequence": sequence + 1, "action": "warp"})
	await ticks(3)
	check(not remote.actor.transport_active, "replayed and malformed actions are rejected")
	# Setup at the elevated perch, then exercise authority landing and prediction.
	remote.actor.relocate(CloudTerrain.point(CloudTerrain.LANDING.x, CloudTerrain.LANDING.y, 0.1))
	await ticks(12)
	gs.game.parrot_travel.controls.request_action.call("mount")
	await ticks(65)
	check(remote.actor.transport_active and remote.actor.position.y > 62 and replica.actor.position.y > 62, "host and guest take off from the high cloud perch")
	check(replica.prediction.suspended, "cloud flight suspends guest walking prediction")
	gs.game.parrot_travel.controls.request_action.call("land")
	await ticks(160)
	check(not remote.actor.transport_active and remote.actor.is_on_floor() and remote.actor.position.y > 57, "host validates cloud landing")
	check(not replica.actor.transport_active and not replica.prediction.suspended and replica.actor.position.y > 57, "guest resumes walking at cloud elevation")
	check(CoopCheckpoint.valid(CoopCheckpoint.capture(hs)), "cloud parked state and checkpoint remain valid")
	gs.game.parrot_travel.controls.request_action.call("mount")
	await ticks(10)
	check(remote.actor.transport_active, "guest remounts the parked bird away from a station")
	guest.leave()
	await ticks(4)
	check(hs.game.parrot_travel.flights.is_empty(), "departure cleans up free-flight state")
	check(CoopValues.vector3(hs.roster.saved_states[GUEST].position).y > 57 and CoopValues.vector3(hs.roster.saved_states[GUEST].position).y < 61, "disconnect checkpoints retain the grounded cloud departure")
	host.leave()
	for child in root.get_children(): child.queue_free()
	await process_frame
	print("Co-op parrot free flight: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

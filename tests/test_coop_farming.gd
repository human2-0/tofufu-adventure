extends SceneTree
## JSON-wire farming on participating hosts and dedicated authority, plus facing replication.
const HOST := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
const ONE := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
const TWO := "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"
var failures: int = 0
var rooms: Dictionary = {}
var sessions: Dictionary = {}
var views: Array[SubViewport] = []

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("FAIL: " + message)

func ticks(count: int = 10) -> void:
	for i in count:
		await physics_frame
		await process_frame

func run() -> void:
	for dedicated in [false, true]:
		await scenario(dedicated)
	print("Co-op farming/facing: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func deliver(sender: String, recipient: String, data: Dictionary) -> void:
	rooms[recipient].receive({"type": "packet", "key": sender, "data": JSON.parse_string(JSON.stringify(data))})

func scenario(dedicated: bool) -> void:
	for key in [HOST, ONE, TWO]:
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
	rooms[TWO].join_room(HOST)
	rooms[HOST].begin()
	for key: String in rooms:
		var viewport := SubViewport.new()
		viewport.own_world_3d = true
		viewport.size = Vector2i(1280, 720)
		root.add_child(viewport)
		views.append(viewport)
		var game: Node3D = load("res://game/app/main.tscn").instantiate()
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
	var one: CoopSession = sessions[ONE]
	var two: CoopSession = sessions[TWO]
	var farm: SoybeanFarming = host.game.farming
	var member: CoopActor = host.roster.party[ONE]
	var other: CoopActor = host.roster.party[TWO]
	check(one._synchronized and two._synchronized, "both guests synchronized")
	check(host.roster.party.has(HOST) != dedicated, "dedicated authority has no player actor")
	# Requests must not mutate the guest and must fail when too far away.
	one.farming.request(0, 0, "plant")
	await ticks()
	check(not farm.plots[0].crop.planted, "host rejects out-of-range planting")
	member.actor.relocate(farm.plots[0].position + Vector3(0, 0.1, 1.2))
	await ticks()
	one.farming.request(0, 0, "plant")
	check(not one.game.farming.plots[0].crop.planted, "no speculative guest mutation")
	await ticks()
	check(farm.plots[0].crop.planted and two.game.farming.plots[0].crop.planted, "plant visible to all guests")
	check(farm.plots[0].crop.age > 0, "authority advances crop clock")
	var crop: SoybeanCrop = farm.plots[0].crop
	crop.step(30)
	other.actor.relocate(farm.plots[0].position + Vector3(1.2, 0.1, 0))
	await ticks()
	var revision := crop.revision
	one.farming.request(0, revision, "harvest")
	two.farming.request(0, revision, "harvest")
	await ticks()
	check(host.game.encounters.pickups.size() == 3, "simultaneous harvest creates one ground yield")
	check(two.game.farming.plots[0].crop.phase() == SoybeanCrop.Phase.HARVEST, "harvest animation replicated")
	await ticks(90)
	check(member.inventory.count_item("edamame") + other.inventory.count_item("edamame") == 3, "simultaneous harvest grants exactly one yield")
	check(one.game.inventory.count_item("edamame") + two.game.inventory.count_item("edamame") == 3, "winner inventory replicated")
	host.farming._packet(ONE, {"type": "farm_action", "sequence": 2, "plot": 0, "revision": revision, "action": "harvest"})
	crop.step(2)
	one.farming.request(0, revision, "plant")
	await ticks()
	check(not crop.planted, "stale revision cannot replant cleared soil")
	one.farming.request(0, crop.revision, "plant")
	await ticks()
	check(crop.planted, "fresh replant accepted")
	crop.step(30)
	for i in PlayerInventory.CAPACITY: member.inventory.set_slot(i, ItemStack.new(InventoryItem.create_edamame(), 100))
	one.farming.request(0, crop.revision, "harvest")
	await ticks()
	check(crop.phase() == SoybeanCrop.Phase.HARVEST and host.game.encounters.pickups.size() == 3, "full bag leaves harvested beans on ground")
	var checkpoint: Dictionary = JSON.parse_string(JSON.stringify(CoopCheckpoint.capture(host)))
	check(CoopCheckpoint.valid(checkpoint), "crop checkpoint JSON validates")
	var saved := farm.capture()
	crop.harvest()
	CoopWorld.apply(host.game, checkpoint.world, false)
	for i in 4:
		var restored: Array = farm.capture()[i]
		check(restored[0] == saved[i][0] and is_equal_approx(restored[1], saved[i][1]) and is_equal_approx(restored[2], saved[i][2]) and restored[3] == saved[i][3], "checkpoint restores crop age and revision")
	var bad := saved.duplicate(true)
	bad[0][1] = -1
	check(not WorldProtocol.farming(bad), "negative growth rejected")
	bad = saved.duplicate(true)
	bad[0][0] = true
	bad[0][2] = 1
	check(not WorldProtocol.farming(bad), "inconsistent crop phase rejected")
	# First-person aim is sampled locally, sent to authority, then viewed by another guest.
	var source: LocalPlayerInput = one.game.shooting_view.local_input
	source.enabled = true
	one.game.shooting_view.cycle_mode()
	one.game.shooting_view.cycle_mode()
	one.game.camera.yaw = PI * 0.5
	one.game.camera.pitch = 0
	one.game.camera._follow_first_person(1)
	Input.action_press("move_right")
	await ticks(15)
	check(member.last_command.face_aim, "first-person facing intent reaches authority")
	check(member.last_command.aim.x < -0.9, "first-person mouse look reaches authority")
	var observer: CoopActor = two.roster.party[ONE]
	check(observer.target_state.get("facing_locked", false), "third player receives facing lock")
	check(observer.actor.visuals.attack_facing.x < -0.9, "replica faces aim while strafing")
	var previous_facing := observer.actor.visuals.current_facing
	Input.action_release("move_right")
	one.game.camera.yaw = -PI * 0.5
	await ticks(15)
	check(observer.actor.visuals.attack_facing.x > 0.9, "stationary mouse turn changes remote facing")
	check(observer.actor.visuals.current_facing != previous_facing, "remote directional sprite changes with idle look")
	if DisplayServer.get_name() != "headless":
		member.actor.relocate(host.game.world.ground_point(0, 10, 0.1))
		other.actor.relocate(host.game.world.ground_point(0, 14, 0.1))
		two.game.shooting_view.cycle_mode()
		two.game.shooting_view.cycle_mode()
		var camera: CameraFollow = two.game.camera
		camera.yaw = 0
		camera.pitch = 0
		views[2].render_target_update_mode = SubViewport.UPDATE_ALWAYS
		for turn in [0, 1]:
			one.game.camera.yaw = PI * 0.5 if turn == 0 else -PI * 0.5
			await ticks(25)
			await RenderingServer.frame_post_draw
			views[2].get_texture().get_image().save_png("/tmp/soy-coop-facing-%s-%d.png" % [dedicated, turn])
	rooms[HOST].leave()
	for viewport in views: viewport.queue_free()
	for room: PlaytestRoom in rooms.values(): room.queue_free()
	await process_frame
	views.clear()
	rooms.clear()
	sessions.clear()

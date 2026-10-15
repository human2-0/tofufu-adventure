extends SceneTree
## Personal deposits stay isolated and identical across bays over real JSON snapshots.

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
const OBSERVER := "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"

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
	host_game.inventory.set_slot(0, ItemStack.new(InventoryItem.create_edamame(), 11))
	remote.inventory.set_slot(0, ItemStack.new(InventoryItem.create_edamame(), 5))
	_place(host_game.player, 0)
	_place(remote.actor, 1)
	_place(guest_game.player, 1)
	await ticks(8)
	check(host_game.seed_storage.quick_transfer(host_game.player, host_game.inventory, "inventory", 0, 0) == "Stored in your personal deposit.", "host deposits at bay zero")
	guest_game.inventory_window.quick_transfer_handler.call("inventory", 0)
	await ticks(12)
	check(host_game.seed_storage.barn.personal(remote.actor).get_slot(0).count == 5, "guest deposit commits on host")
	check(guest_game.seed_storage.chest.get_slot(0).count == 5, "guest panel receives its own contents")
	check(host_game.seed_storage.chest.get_slot(0).count == 11, "host panel keeps its own contents")
	_place(remote.actor, 0)
	_place(guest_game.player, 0)
	await ticks(8)
	guest_game.inventory_window.quick_transfer_handler.call("chest", 0)
	await ticks(12)
	check(remote.inventory.count_item("edamame") == 5 and replica.inventory.count_item("edamame") == 5, "guest withdraws same deposit from host's bay")
	check(host_game.seed_storage.barn.personal(host_game.player).get_slot(0).count == 11, "guest cannot withdraw host items")
	var cloud_site: Node3D = host_game.world.cloud_realm.deposit_sites[1]
	remote.actor.relocate(cloud_site.global_position + Vector3(0, 0.1, 1.5))
	guest_game.player.relocate(cloud_site.global_position + Vector3(0, 0.1, 1.5))
	await ticks(8)
	check(host_game.seed_storage.bay_for(remote.actor) == 1, "host validates guest cloud chest access")
	guest_game.inventory_window.quick_transfer_handler.call("inventory", 0)
	await ticks(12)
	check(host_game.seed_storage.barn.personal(remote.actor).get_slot(0).count == 5, "guest cloud deposit commits through JSON intents")
	check(guest_game.seed_storage.chest.get_slot(0).count == 5, "cloud panel receives personal deposit snapshot")
	check(host_game.seed_storage.barn.personal(host_game.player).get_slot(0).count == 11, "cloud storage preserves host ownership")
	var dummy: PracticeDummy = host_game.encounters.dummy_nodes[3]
	dummy.target.damage(125)
	await ticks(12)
	check(guest_game.encounters.dummy_nodes[3].target.current == 375, "cloud target damage replicates from authority")
	var view_dummy: PracticeDummy = guest_game.encounters.dummy_nodes[3]
	check(not view_dummy.is_physics_processing(), "guest cannot run dummy recovery")
	dummy._physics_process(6.0)
	await ticks(12)
	check(view_dummy.target.current == 500, "cloud target recovery replicates from authority")
	var checkpoint := CoopWorld.capture(host_game)
	host_game.seed_storage.barn.banks[0].restore([])
	CoopWorld.apply(host_game, checkpoint, false)
	check(host_game.seed_storage.barn.personal(host_game.player).get_slot(0).count == 11, "personal deposit survives world restore")
	for child in root.get_children(): child.queue_free()
	for frame in 4: await process_frame
	print("Co-op storage: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _place(actor: Node3D, bay: int) -> void:
	actor.global_position = host_game.world.seed_bank.to_global(MeadowBarn.table_position(bay) + MeadowBarn.front(bay) * 1.1 + Vector3.DOWN * 0.7)

func _game(room: PlaytestRoom) -> CoopSession:
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	root.add_child(viewport)
	var game: Node3D = load("res://game/app/adventure/main.tscn").instantiate()
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

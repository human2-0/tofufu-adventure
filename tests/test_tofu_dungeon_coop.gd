extends SceneTree
## Host owns factory waves and refinement; guests receive factory visuals and unlock.

class FactoryInput extends PlayerCommandSource:
	var pickup: bool = false
	func sample(_at: Vector3) -> PlayerCommand:
		var command := PlayerCommand.new()
		command.pickup_pressed = pickup
		pickup = false
		return command

const HOST := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
const GUEST := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
var failures: int = 0
var rooms: Dictionary = {}

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	if ok: return
	failures += 1
	push_error("FAIL: " + message)

func ticks(count: int = 10) -> void:
	for i in count:
		await physics_frame
		await process_frame

func deliver(sender: String, recipient: String, data: Dictionary) -> void:
	rooms[recipient].receive({"type": "packet", "key": sender, "data": JSON.parse_string(JSON.stringify(data))})

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
		var game: Node3D = load("res://game/app/main.tscn").instantiate()
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
	var member: CoopActor = host.roster.party[GUEST]
	var guest_input := FactoryInput.new()
	guest.add_child(guest_input)
	guest.roster.local_input = guest_input
	check(guest._synchronized, "guest synchronizes factory world")
	member.actor.relocate(TofuFactory.EAST_ENTRANCE)
	await ticks(12)
	check(member.actor.position.x > 200 and guest.game.player.position.x > 200, "guest enters the factory on host authority")
	check(host.game.factory_dungeon._enemies.size() == 3 and guest.game.factory_dungeon._replica_enemies.size() == 3, "enemy wave appears on host and guest")
	host.game.factory_dungeon._crates[0].target.damage(100)
	await ticks(10)
	check(host.game.world_items.pool.drops.values().any(func(drop: WorldItemDrop) -> bool: return drop.item_id == "soy_milk"), "host creates soy milk from a marked crate")
	check(guest.game.world_items.pool.drops.values().any(func(drop: WorldItemDrop) -> bool: return drop.item_id == "soy_milk"), "guest sees the shared soy milk drop")
	for stage in TofuDungeonState.STATIONS.size():
		member.actor.relocate(TofuFactory.CENTERS[stage] + Vector3(0,0.2,4))
		await ticks(5)
		check(host.game.factory_dungeon._enemies.size() > 0 or stage == 3, "host creates stage %d wave" % stage)
		for enemy: FactoryBean in host.game.factory_dungeon._enemies.duplicate(): enemy.target.damage(999)
		check(not host.game.factory_dungeon.interact(member.actor), "station rejects distant interactions")
		for unit in host.game.factory_dungeon.state.required_units():
			host.game.factory_dungeon.state.step(1.1)
			if stage == 0 or stage == 2:
				member.actor.relocate(TofuFactory.bag(unit, stage) + Vector3.UP * 0.2)
				await ticks(5)
				guest_input.pickup = true
				await ticks(5)
				check(host.game.factory_dungeon._carrying.has(member.actor), "guest command picks up marked soy sack on host")
			member.actor.relocate(TofuFactory.station(stage) + Vector3(0,0.2,2))
			await ticks(5)
			guest_input.pickup = true
			await ticks(5)
			check(host.game.factory_dungeon.state.units == unit + 1, "guest command operates production station on host")
		if stage == 3:
			check(host.game.factory_dungeon._enemies.size() == 4 and host.game.factory_dungeon.state.process_remaining == 0, "coagulant triggers Dofu ambush before processing")
			for enemy: FactoryBean in host.game.factory_dungeon._enemies.duplicate(): enemy.target.damage(999)

		host.game.factory_dungeon._physics_process(TofuDungeonState.PROCESS_SECONDS + 0.1)
		for attempt in 30:
			if guest.game.factory_dungeon.state.stage == stage + 1: break
			await ticks(1)
		check(guest.game.factory_dungeon.state.stage == stage + 1, "stage %d completion replicates" % stage)
	check(member.inventory.refining_unlocked and guest.game.inventory.refining_unlocked, "host and guest unlock refinement together")
	check(CoopCheckpoint.valid(CoopCheckpoint.capture(host)), "completed dungeon remains a valid host checkpoint")
	member.inventory.set_slot(5, ItemStack.new(InventoryItem.create_edamame(), 100))
	await ticks(8)
	guest.game.inventory_window._request_conversion(5, "press_edamame")
	await ticks(8)
	check(member.inventory.get_slot(5).item.id == "edamame" and member.inventory.get_slot(5).count == 100, "host rejects obsolete direct-to-tofu recipe")
	guest.game.inventory_window._request_conversion(5, "edamame")
	await ticks(8)
	check(member.inventory.get_slot(5).item.id == "mature_bean" and guest.game.inventory.get_slot(5).item.id == "mature_bean", "host validates guest edamame refinement and replicates mature bean")
	guest.game.inventory_window._request_conversion(5, "mature_bean")
	await ticks(8)
	check(member.inventory.get_slot(5).item.id == "tofu_white_chunk" and guest.game.inventory.get_slot(5).item.id == "tofu_white_chunk", "host validates one-to-one white tofu refinement")
	print("Tofu Dungeon co-op: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures > 0 else 0)

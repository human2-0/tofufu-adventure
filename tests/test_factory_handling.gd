extends SceneTree
## Real factory anchors and fake-peer commands cover contextual cargo handling.

class ApproachInput extends PlayerCommandSource:
	var move := Vector2.ZERO
	func sample(_at: Vector3) -> PlayerCommand:
		var command := PlayerCommand.new()
		command.move = move
		return command

const HOST := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
const GUEST := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
var rooms: Dictionary = {}
var failures: int = 0
var host: CoopSession
var guest: CoopSession
var dungeon: TofuDungeon

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	if ok: return
	failures += 1
	push_error("FAIL: " + label)

func ticks(count: int = 4) -> void:
	for frame in count:
		await physics_frame
		await process_frame

func deliver(sender: String, recipient: String, packet: Dictionary) -> void:
	rooms[recipient].receive({"type": "packet", "key": sender, "data": JSON.parse_string(JSON.stringify(packet))})

func run() -> void:
	var sessions: Dictionary = {}
	for key in [HOST, GUEST]:
		var room := PlaytestRoom.new()
		room.local_key = key
		room.send_packet = func(recipient: String, packet: Dictionary) -> void: deliver(key, recipient, packet)
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
	host = sessions[HOST]
	guest = sessions[GUEST]
	dungeon = host.game.factory_dungeon
	check(guest._synchronized, "local guest receives factory protocol")
	var local: Player = host.game.player
	var remote: Player = host.roster.party[GUEST].actor
	local.relocate(TofuFactory.EAST_ENTRANCE)
	remote.relocate(TofuFactory.EAST_ENTRANCE)
	await ticks(20)
	check(dungeon.actor_in_run(local) and dungeon.actor_in_run(remote), "both actors enter the authoritative run")
	dungeon.journal.close()
	guest.game.factory_dungeon.journal.close()
	locked_stash_case(local)
	await sorting_cases(local, remote)
	await laboratory_cases(local, remote)
	await packaging_cases(local, remote)
	await stash_cases(local, remote)
	await encounter_spawn_cases()
	print("Factory handling: ", "PASS" if failures == 0 else "FAIL")
	for child: Node in root.get_children(): child.queue_free()
	for drain in 5:
		await physics_frame
		await process_frame
	quit(1 if failures else 0)

func place(actor: Player, id: String, offset := Vector3(0, 0.05, 1.5)) -> void:
	var at: Vector3 = FactoryHiddenChests.position_for(id) if id.begins_with("stash_") else TofuFactory.object_position(id)
	actor.relocate(at + offset)
	dungeon._recovery.seed(DungeonMembership.key_for(dungeon, actor), actor.global_position, TofuFactory.room_at(actor.global_position))

func direct(actor: Player, action: TofuPuzzleCommand.Action, target: String, object_id: String = "") -> Dictionary:
	var command: TofuPuzzleCommand = DungeonPuzzleIntent.build(dungeon.puzzle_flow, dungeon, actor, action, target, object_id)
	return dungeon.submit_puzzle(command, actor)

func wire(action: TofuPuzzleCommand.Action, target: String, object_id: String = "") -> TofuPuzzleCommand:
	var replica: TofuDungeon = guest.game.factory_dungeon
	var command: TofuPuzzleCommand = DungeonPuzzleIntent.build(replica.puzzle_flow, replica, guest.game.player, action, target, object_id)
	guest.game.factory_dungeon.puzzle_command_requested.emit(command)
	return command

func selected(actor: Player) -> Dictionary:
	return DungeonInteractionTargets.selected(dungeon, actor)

func sorting_cases(local: Player, remote: Player) -> void:
	place(remote, "sack_edamame")
	place(local, "sack_edamame", Vector3(0.8, 0.05, 1.5))
	await ticks(4)
	check(selected(local).get("id") == "sack_edamame", "focus points to the actual nearby unrouted sack")
	await ticks(30)
	var edge := PlayerCommand.new()
	edge.pickup_pressed = true
	CoopLocalMenus.sample(guest, edge)
	await ticks(6)
	check(not edge.pickup_pressed and guest.game.factory_dungeon.journal.visible, "actual guest E consumes the matching inspect intent and opens accepted clue")
	check(dungeon.puzzle_flow.observed.has("%d:sack_edamame" % DungeonMembership.actor_id(dungeon, remote)), "host records the authenticated guest inspection")
	guest.game.factory_dungeon.journal.close()
	var pickup: TofuPuzzleCommand = wire(TofuPuzzleCommand.Action.PICK_UP, "sack_edamame")
	var rival := direct(local, TofuPuzzleCommand.Action.PICK_UP, "sack_edamame")
	await ticks(6)
	check(dungeon.puzzle.sorting.carried_by.size() == 1 and not rival.accepted, "simultaneous fake-peer pickup reserves exactly one sack")
	check(selected(local).get("id", "") != "sack_edamame", "another actor's carried sack is not offered as a local pickup")
	place(remote, "intake_chilled")
	await ticks(30)
	var returned: TofuPuzzleCommand = wire(TofuPuzzleCommand.Action.RETURN_PROP, "sack_edamame")
	await ticks(5)
	check(dungeon.puzzle.sorting.carried_by.is_empty(), "guest returns a carried sack beside a machine far from its dock")
	var revision: int = dungeon.puzzle.sorting.revision
	guest.game.factory_dungeon.puzzle_command_requested.emit(returned)
	guest.game.factory_dungeon.puzzle_command_requested.emit(pickup)
	await ticks(4)
	check(dungeon.puzzle.sorting.revision == revision and dungeon.puzzle.mistakes == 0, "replayed cargo packets cannot release or duplicate props and cause no wave")
	place(local, "sack_edamame")
	await ticks()
	check(direct(local, TofuPuzzleCommand.Action.PICK_UP, "sack_edamame").accepted, "returned sack remains recoverable at its dock")
	place(local, "intake_chilled")
	await ticks()
	check(selected(local).get("id") == "intake_chilled", "carrying context focuses the selected machine")
	check(direct(local, TofuPuzzleCommand.Action.LOAD_INTAKE, "intake_chilled", "sack_edamame").accepted, "correctly routed sack supplies its line")
	place(local, "sack_edamame")
	await ticks()
	check(selected(local).get("id", "") != "sack_edamame", "supplied sack's original dock stops advertising pickup")
	place(local, "sack_mature")
	await ticks()
	check(direct(local, TofuPuzzleCommand.Action.PICK_UP, "sack_mature").accepted, "next sack can be carried")
	place(local, "intake_chilled")
	await ticks()
	var focused: Dictionary = selected(local)
	check(focused.get("action", -1) != TofuPuzzleCommand.Action.LOAD_INTAKE, "filled intake refuses loading without a harmful submission")
	check(direct(local, TofuPuzzleCommand.Action.RETURN_PROP, "sack_mature").accepted, "local return also works far from the original sack dock")
	await occlusion_case(local)
	check(dungeon.puzzle.mistakes == 0 and dungeon._enemies.is_empty(), "handling refusals and occluded interactions never create penalty enemies")

func occlusion_case(actor: Player) -> void:
	place(actor, "sack_high_fat", Vector3(0, 0.05, 2.2))
	var blocker := StaticBody3D.new()
	blocker.position = TofuFactory.object_position("sack_high_fat") + Vector3(0, 0.9, 1.0)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4.0, 2.5, 0.2)
	shape.shape = box
	blocker.add_child(shape)
	host.game.world.add_child(blocker)
	await ticks()
	check(selected(actor).get("id", "") != "sack_high_fat", "focus skips a sack hidden behind world collision")
	var before: int = dungeon.puzzle_flow.observed.size()
	dungeon.puzzle_flow.interact(dungeon, actor)
	check(dungeon.puzzle_flow.observed.size() == before and not dungeon.journal.visible, "occluded E cannot mark inspection or reveal its clue")
	blocker.queue_free()
	await ticks()

func laboratory_cases(local: Player, remote: Player) -> void:
	dungeon.puzzle.sorting.assignments = {"sack_edamame": "intake_chilled", "sack_mature": "intake_tofu", "sack_high_fat": "intake_oil"}
	dungeon.puzzle.lab.opening_cleared = true
	dungeon.puzzle.stage = TofuPuzzleContract.Stage.LAB
	dungeon.puzzle_runtime._sync_gates()
	place(local, "coagulation_tank")
	place(remote, "lab_terminal")
	await ticks(30)
	check(selected(local).get("id") == "coagulation_tank", "tank without a bottle offers its own inspection")
	check(direct(local, TofuPuzzleCommand.Action.INSPECT, "coagulation_tank").accepted, "advertised tank inspection is accepted by authority")
	check(not dungeon.puzzle.lab.formula_unlocked and dungeon.puzzle.mistakes == 0, "tank inspection neither reveals the recipe nor punishes exploration")
	place(local, "container_01", Vector3(0, 0.05, 2.3))
	await ticks()
	check(selected(local).get("id") == "container_01", "nearest reachable bottle wins over the farther nearby terminal")
	check(direct(local, TofuPuzzleCommand.Action.PICK_UP, "container_01").accepted, "rack bottle can be carried without the password")
	place(local, "coagulation_tank")
	await ticks()
	check(selected(local).get("action") == TofuPuzzleCommand.Action.POUR and selected(local).get("object_id") == "container_01", "carried bottle makes tank offer the explicit pour action")
	check(direct(local, TofuPuzzleCommand.Action.RETURN_PROP, "container_01").accepted, "bottle can return safely beside the tank far from its shelf")
	check(dungeon.puzzle.lab.carrier_id == 0 and dungeon.puzzle.mistakes == 0, "reversible bottle handling leaves no failed batch")

func packaging_cases(local: Player, remote: Player) -> void:
	# Cleared fixture preserves real stage prerequisites; all transfers still use authority commands.
	dungeon.puzzle.sorting.assignments = {"sack_edamame": "intake_chilled", "sack_mature": "intake_tofu", "sack_high_fat": "intake_oil"}
	dungeon.puzzle.lab.opening_cleared = true
	dungeon.puzzle.lab.complete = true
	dungeon.puzzle.press.certificates = [true, true, true]
	dungeon.puzzle.cut.issue_block(dungeon.puzzle.batch_id + "_block", 6.0)
	dungeon.puzzle.cut.commit(dungeon.puzzle.cut.block_id, [1.0, 2.0, 3.0, 4.0, 5.0], dungeon.puzzle.cut.revision)
	dungeon.puzzle.pack.begin_batch(dungeon.puzzle.batch_id)
	dungeon.puzzle.stage = TofuPuzzleContract.Stage.PACK
	dungeon.puzzle_runtime._sync_gates()
	place(local, "slab_0")
	place(remote, "slab_5")
	await ticks(30)
	check(selected(local).get("id") == "slab_0", "packaging points to available cut-room slabs")
	check(direct(local, TofuPuzzleCommand.Action.PICK_UP, "", "0").accepted, "one slab is reserved at its actual dock")
	check(selected(local).get("action", -1) == TofuPuzzleCommand.Action.RETURN_PROP, "carried slab has a safe return action away from packer")
	check(direct(local, TofuPuzzleCommand.Action.RETURN_PROP, "", "0").accepted, "unfinished slab can be returned without a mistake")
	check(direct(local, TofuPuzzleCommand.Action.PICK_UP, "", "0").accepted, "returned slab remains pickable")
	place(local, "package_0")
	await ticks()
	check(selected(local).get("id") == "package_0" and selected(local).get("action") == TofuPuzzleCommand.Action.PLACE_SLAB, "packer offers placement into the exact nearby empty slot")
	check(direct(local, TofuPuzzleCommand.Action.PLACE_SLAB, "0", "0").accepted, "owned slab transfers once into its dock")
	check(selected(local).get("action") == TofuPuzzleCommand.Action.SEAL_SLOT, "filled unsealed package offers the next physical action")
	check(direct(local, TofuPuzzleCommand.Action.SEAL_SLOT, "0").accepted, "package seals once")
	check(selected(local).get("action", -1) != TofuPuzzleCommand.Action.SEAL_SLOT, "sealed package does not advertise a repeated seal")
	place(local, "slab_0")
	await ticks()
	check(selected(local).get("id", "") != "slab_0", "moved slab is removed from its previous pickup location")
	place(local, "slab_1")
	await ticks()
	check(direct(local, TofuPuzzleCommand.Action.PICK_UP, "", "1").accepted, "second identifiable slab can be carried")
	place(local, "package_0")
	await ticks()
	var target: Dictionary = selected(local)
	check(target.get("id", "") != "package_0" or target.get("action", -1) != TofuPuzzleCommand.Action.PLACE_SLAB, "filled dock refuses extra input while preserving cargo")
	check(not direct(local, TofuPuzzleCommand.Action.PLACE_SLAB, "0", "1").accepted and dungeon.puzzle.pack.owners[1] == DungeonMembership.actor_id(dungeon, local), "blocked transfer loses no slab and causes no punishment")
	check(dungeon.puzzle.mistakes == 0 and dungeon.puzzle.pack.slot_slabs[0] == 0 and dungeon.puzzle.pack.sealed[0], "packaging preserves accepted contents and the mistake counter")

func locked_stash_case(actor: Player) -> void:
	# Deliberately forge a coordinate in a future room; neither coordinates nor intent can unlock it.
	place(actor, "stash_press")
	check(not direct(actor, TofuPuzzleCommand.Action.OPEN_STASH, "stash_press").accepted, "locked future manufacturing chest refuses early opening")
	check(dungeon.stashes.opened == 0 and toasted_count() == 0, "locked chest creates no claim or payout")
	actor.relocate(TofuFactory.HALL_ARRIVAL)
	dungeon._recovery.seed(HOST, actor.global_position, 0)

func toasted_count() -> int:
	var total: int = 0
	for member: CoopActor in host.roster.party.values():
		total += member.inventory.count_item("toasted_tofu_chunk")
	for drop: WorldItemDrop in host.game.world_items.pool.drops.values():
		if drop.item_id == "toasted_tofu_chunk": total += drop.count
	return total

func walk_to_stash(actor: Player, id: String, front_offset := Vector3(0, 0.0, 1.5)) -> void:
	var at: Vector3 = FactoryHiddenChests.position_for(id)
	var destination: Vector3 = at + front_offset
	place(actor, id, front_offset + Vector3(0, 0.05, 3.0))
	var previous: PlayerCommandSource = actor.command_source
	var source := ApproachInput.new()
	actor.add_child(source)
	actor.command_source = source
	for frame in 180:
		var offset := Vector2(destination.x - actor.global_position.x, destination.z - actor.global_position.z)
		if offset.length() < 0.12 and Vector2(actor.velocity.x, actor.velocity.z).length() < 0.5: break
		source.move = (offset * 2.0).limit_length()
		await physics_frame
	source.move = Vector2.ZERO
	await ticks(4)
	actor.command_source = previous
	source.queue_free()
	check(Vector2(actor.global_position.x - destination.x, actor.global_position.z - destination.z).length() < 0.5, "real motor walks the service aisle to " + id)

func open_stash_on_top(actor: Player, id: String) -> void:
	var at: Vector3 = FactoryHiddenChests.position_for(id)
	check(actor.relocate(at + Vector3.UP * 0.5), "collision-aware placement permits landing above the chest")
	await ticks(12)
	var horizontal := Vector2(actor.global_position.x - at.x, actor.global_position.z - at.z)
	check(horizontal.length_squared() < 0.001 and actor.is_on_floor() and actor.global_position.y > at.y + 0.3, "real capsule settles on the chest with zero horizontal reward direction")
	check(direct(actor, TofuPuzzleCommand.Action.OPEN_STASH, id).accepted, "actor standing on the chest can open it")
	var found: WorldItemDrop
	var pool: WorldItemPool = host.game.world_items.pool
	for drop: WorldItemDrop in pool.drops.values():
		if str(drop.get_meta("factory_stash", "")) == id: found = drop
	check(found != null, "on-top opening creates one identified shared drop")
	if found == null: return
	var offset := Vector2(found.global_position.x - at.x, found.global_position.z - at.z)
	check(offset.length() >= 0.85 and found.count == 1, "zero-direction fallback places one chunk outside the chest body")
	var query := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = WorldItemDrop.RADIUS
	query.shape = sphere
	query.transform = Transform3D(Basis.IDENTITY, found.global_position)
	query.collision_mask = 1
	check(actor.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty(), "spawned chunk has physical clearance from chest and machinery")
	check(pool.reachable(found, actor.global_position), "on-top actor can reach the chunk without an obstructed pickup ray")

func stash_cases(local: Player, remote: Player) -> void:
	check(direct(local, TofuPuzzleCommand.Action.RETURN_PROP, "", "1").accepted, "slab cargo returns before optional chest exploration")
	place(remote, "stash_mill", Vector3(0, 0.05, 1.3))
	await walk_to_stash(local, "stash_mill", Vector3(1.1, 0.0, 1.7))
	await ticks(30)
	check(selected(remote).get("id") == "stash_mill", "hidden mill chest becomes a nearby inspectable interaction")
	var mill_collider: CollisionShape3D = remote.get_node("CollisionShape3D")
	check(dungeon.factory.anchor_has_clearance(remote, mill_collider, remote.global_position, dungeon.state.stage), "mill chest approach keeps full capsule clearance")
	var opened: TofuPuzzleCommand = wire(TofuPuzzleCommand.Action.OPEN_STASH, "stash_mill")
	var rival: Dictionary = direct(local, TofuPuzzleCommand.Action.OPEN_STASH, "stash_mill")
	await ticks(6)
	check(not rival.accepted and not dungeon.stashes.available("stash_mill") and toasted_count() == 1, "simultaneous peers open one chest and receive one shared crispy tofu chunk")
	guest.game.factory_dungeon.puzzle_command_requested.emit(opened)
	check(not direct(local, TofuPuzzleCommand.Action.OPEN_STASH, "stash_mill").accepted, "other peer cannot reopen a claimed chest")
	await ticks(6)
	check(toasted_count() == 1 and dungeon.stashes.revision == 1, "duplicate and stale chest packets cannot mint a second chunk")
	var pool: WorldItemPool = host.game.world_items.pool
	var temporary_ids: Array[int] = []
	for index in WorldItemPool.LIMIT - pool.drops.size():
		var filler: WorldItemDrop = pool.spawn_at("edamame", 1, 100.0, Vector3(0, 0.2, -240))
		if filler != null: temporary_ids.append(filler.drop_id)
	place(local, "stash_press")
	check(pool.drops.size() == WorldItemPool.LIMIT, "shared drop pool is at its configured capacity")
	check(not direct(local, TofuPuzzleCommand.Action.OPEN_STASH, "stash_press").accepted and dungeon.stashes.available("stash_press"), "full drop pool leaves chest unclaimed for a later retry")
	for id: int in temporary_ids: pool.remove(id)
	await ticks(4)
	var checkpoint: Dictionary = JSON.parse_string(JSON.stringify(CoopCheckpoint.capture(host)))
	check(CoopCheckpoint.valid(checkpoint), "checkpoint contains the shared drop and its matching chest claim")
	var malformed: Dictionary = checkpoint.duplicate(true)
	malformed.world.factory.stashes = {"opened": 1, "revision": 0}
	check(not CoopCheckpoint.valid(malformed), "mismatched chest claim bitmap rejects the complete checkpoint")
	var saved_factory: Dictionary = JSON.parse_string(JSON.stringify(dungeon.capture()))
	dungeon.restore(saved_factory)
	check(not dungeon.stashes.available("stash_mill") and dungeon.stashes.available("stash_press"), "factory reload retains only the chest actually opened")
	for id in ["stash_press", "stash_pack"]:
		await walk_to_stash(local, id)
		check(selected(local).get("id") == id, "actual capsule has a reachable approach to " + id)
		var collider: CollisionShape3D = local.get_node("CollisionShape3D")
		check(dungeon.factory.anchor_has_clearance(local, collider, local.global_position, dungeon.state.stage), "chest approach keeps full capsule clearance: " + id)
		if id == "stash_press": await open_stash_on_top(local, id)
		else: check(direct(local, TofuPuzzleCommand.Action.OPEN_STASH, id).accepted, "manufacturing chest opens after its room is unlocked: " + id)
	check(dungeon.stashes.opened == 7 and dungeon.stashes.revision == 3 and toasted_count() == 3, "three physically reachable chests grant exactly three shared crispy chunks")
	var complete_claims: Dictionary = JSON.parse_string(JSON.stringify(dungeon.capture()))
	dungeon.restore(complete_claims)
	check(dungeon.stashes.opened == 7 and dungeon.stashes.revision == 3, "reload retains the full bounded chest ledger")
	dungeon.puzzle.phase = TofuPuzzleContract.Phase.LOCKED
	dungeon.puzzle.mistakes = TofuPuzzleContract.MAX_MISTAKES
	check(direct(local, TofuPuzzleCommand.Action.RESTART, "").accepted, "bounded attempt can restart after the chest checkpoint")
	check(dungeon.stashes.opened == 7 and dungeon.stashes.revision == 3 and toasted_count() == 3, "new production attempt cannot refresh permanent chest rewards")
	place(remote, "stash_mill")
	await ticks(30)
	wire(TofuPuzzleCommand.Action.OPEN_STASH, "stash_mill")
	await ticks(5)
	check(toasted_count() == 3 and dungeon.puzzle.mistakes == 0, "restarted guest chest request produces neither farming rewards nor punishment")

func encounter_spawn_cases() -> void:
	# Spawn geometry fixtures do not publish incomplete progression to either peer.
	host.set_physics_process(false)
	guest.set_physics_process(false)
	dungeon.set_physics_process(false)
	var before_rewards: Dictionary = dungeon.rewards.capture()
	var before_drops: int = host.game.world_items.pool.drops.size()
	for room in 6:
		var curds: bool = room == 5
		dungeon.puzzle.stage = TofuPuzzleContract.Stage.LAB if curds else room as TofuPuzzleContract.Stage
		dungeon.puzzle.phase = TofuPuzzleContract.Phase.COMBAT
		dungeon.puzzle.mistakes = 1
		dungeon.puzzle.encounter_id = "lab_curd" if curds else "penalty_01"
		dungeon.puzzle_runtime._sync_gates()
		dungeon.puzzle_flow._spawn(dungeon)
		for enemy: FactoryBean in dungeon._enemies:
			enemy.set_physics_process(false)
		await ticks(2)
		check(dungeon._enemies.size() == (4 if curds else 3), "factory spawn keeps the authored roster size: " + str(dungeon.puzzle.stage))
		for enemy: FactoryBean in dungeon._enemies:
			var collider: CollisionShape3D
			for child: Node in enemy.get_children():
				if child is CollisionShape3D: collider = child
			check(collider != null and collider.shape != null, "spawned enemy owns a real movement capsule")
			if collider == null or collider.shape == null: continue
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = collider.shape
			query.transform = collider.global_transform
			query.collision_mask = 1
			query.exclude = [enemy.get_rid()]
			var overlaps: Array[Dictionary] = enemy.get_world_3d().direct_space_state.intersect_shape(query, 8)
			check(overlaps.is_empty(), "enemy spawns clear of fixed machinery and world collision: room %d at %s" % [dungeon.puzzle.stage, enemy.global_position])
		dungeon.puzzle_flow.reset_encounter(dungeon)
		await ticks(2)
	check(dungeon.rewards.capture() == before_rewards and host.game.world_items.pool.drops.size() == before_drops, "spawn and cleanup tests invoke no defeat rewards or extra drops")

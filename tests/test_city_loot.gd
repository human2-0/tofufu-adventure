extends SceneTree
## Real doorway walking, cutaways, finite chest transactions and legacy saves.

class WalkInput extends PlayerCommandSource:
	var move := Vector2.ZERO
	func sample(_at: Vector3) -> PlayerCommand:
		var command := PlayerCommand.new()
		command.move = move
		return command

var failures: int = 0
var game: AdventureGame
var actor: Player
var input := WalkInput.new()

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	if ok: return
	failures += 1
	printerr("FAIL: ", message)

func ticks(count: int = 3) -> void:
	for tick in count: await physics_frame

func run() -> void:
	game = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	actor = game.player
	actor.command_source = input
	actor.add_child(input)
	await ticks()
	var before := AdventureSnapshot.capture(game, "Before city loot", 0)
	Engine.time_scale = 4
	check(game.world.city_rooms.size() >= 70, "every enclosed legacy and eastern structure has a real room")
	for room in game.world.city_rooms:
		var size: Vector3 = room.get_meta("city_size")
		var floor_y: float = room.get_meta("city_floor")
		var entry: Vector3 = room.get_meta("city_entry")
		var outside := room.to_global(entry + Vector3.BACK * 0.4)
		var start := game.world.ground_point(outside.x, outside.z, 0.08)
		actor.relocate(start)
		await ticks()
		var doorway := room.to_global(Vector3(0, floor_y, size.z / 2 - 1))
		var center := room.to_global(Vector3(0, floor_y, 0))
		await walk(doorway)
		await walk(center)
		check(actor.is_on_floor(), "room floor supports the capsule at " + str(room.global_position))
		await walk(doorway)
		await walk(start)
		check(actor.is_on_floor(), "room entrance ramp returns to the street")
	await cutaway()
	await transactions()
	for index in game.city_loot.chests.size():
		var chest := game.city_loot.chests[index]
		actor.relocate(chest.global_position + Vector3(0, 0.08, 2))
		await ticks()
		check(game.city_loot.reachable(actor, index), "supply chest has a clear interior approach %d" % index)
		var old_count := game.world_items.pool.drops.size()
		check(game.city_loot.perform(actor, index), "open a reachable chest %d" % index)
		check(game.world_items.pool.drops.size() == old_count + 2, "chest creates exactly two modest supply stacks")
		check(not game.city_loot.perform(actor, index), "one-time chest cannot be farmed by repeated interaction")
		check(game.world_items.pool.drops.size() == old_count + 2, "replay does not duplicate loot")
	check(game.city_loot.opened == CityLootSites.MASK, "all eighteen authored supplies are finite")
	var saved := AdventureSnapshot.capture(game, "City supplies", 0)
	check(SaveStore.valid(saved), "new chest state and remaining loot produce a valid adventure save")
	game.city_loot.restore(0)
	AdventureSnapshot.restore(game, saved)
	check(game.city_loot.opened == CityLootSites.MASK, "reload preserves all opened chests")
	for chest in game.city_loot.chests: check(chest.opened, "restored chest lid presents its saved state")
	var world := CoopWorld.capture(game)
	check(WorldProtocol.valid(world), "city mask coexists with the complete bounded world record")
	for invalid in [-1, 262144, 1.5, "1", true, NAN]:
		var bad := saved.duplicate(true)
		bad.city_loot = invalid
		check(not SaveStore.valid(bad), "reject invalid saved city chest mask")
		bad = world.duplicate(true)
		bad.city_loot = invalid
		check(not WorldProtocol.valid(bad), "reject invalid replicated city chest mask")
	before.erase("city_loot")
	check(SaveStore.valid(before), "old saves without city chest claims remain valid")
	AdventureSnapshot.restore(game, before)
	check(game.city_loot.opened == 0, "old saves start the newly supplied city unopened")
	Engine.time_scale = 1
	game.queue_free()
	await process_frame
	await process_frame
	print("Enterable city and finite supplies: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func cutaway() -> void:
	var room := game.world.city_rooms[0]
	var floor_y: float = room.get_meta("city_floor")
	var size: Vector3 = room.get_meta("city_size")
	actor.relocate(room.to_global(Vector3(0, floor_y + 0.05, 0)))
	await ticks()
	await process_frame
	for roof: MeshInstance3D in room.get_meta("interior_roofs"): check(not roof.visible, "room roof cuts away around its indoor actor")
	check(WeatherExposure.covered(game, actor.global_position) and not ParrotLanding.outdoor(game, actor.global_position), "interior shelters rain and rejects indoor parrot boarding")
	var ray := PhysicsRayQueryParameters3D.create(room.global_position + Vector3.UP * 40, actor.global_position, 1)
	var hit := game.get_world_3d().direct_space_state.intersect_ray(ray)
	check(not hit.is_empty() and hit.position.y >= room.global_position.y + size.y - 0.2, "hidden roof keeps real physical collision")
	actor.relocate(room.to_global(Vector3(4, size.y + 0.08, 2)))
	await ticks()
	await process_frame
	for roof: MeshInstance3D in room.get_meta("interior_roofs"): check(roof.visible, "standing on a rooftop never cuts it away")
	check(not WeatherExposure.covered(game, actor.global_position), "rooftop remains outdoors")

	# A neighbouring tall terrace must not hide the smaller room behind it.
	var chest := game.city_loot.chests[5]
	actor.relocate(chest.global_position + Vector3(0, 0.08, 2))
	game.camera.set_physics_process(false)
	game.camera.set_process(false)
	game.camera.position = chest.global_position + Vector3(14, 15, 18)
	game.camera.look_at(chest.global_position)
	await ticks()
	await process_frame
	var ray_to_actor := PhysicsRayQueryParameters3D.create(game.camera.global_position, actor.global_position + Vector3.UP, 1)
	var blocker := game.get_world_3d().direct_space_state.intersect_ray(ray_to_actor)
	check(not blocker.is_empty(), "terrace sightline exercises a real neighbouring building")
	var neighbouring_roof_hidden := false
	for adjacent in game.world.city_rooms:
		if absf(adjacent.global_position.x - 296) > 0.1 or absf(adjacent.global_position.z + 24) > 0.1: continue
		for roof: MeshInstance3D in adjacent.get_meta("interior_roofs"):
			neighbouring_roof_hidden = neighbouring_roof_hidden or not roof.visible
	check(neighbouring_roof_hidden, "neighbouring architecture cuts away when blocking an indoor actor")

func transactions() -> void:
	var loot := game.city_loot
	var chest := loot.chests[0]
	actor.relocate(game.world.ground_point(0, 0, 0.1))
	await ticks()
	check(not loot.perform(actor, 0), "remote chest opening is rejected")
	actor.relocate(chest.global_position + Vector3(0, 0.08, 2))
	await ticks()
	var wall := StaticBody3D.new()
	wall.position = chest.global_position + Vector3(0, 1.2, 1.1)
	root.add_child(wall)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2, 2.4, 0.1)
	shape.shape = box
	wall.add_child(shape)
	await ticks()
	check(not loot.perform(actor, 0) and loot.opened == 0, "a solid obstacle prevents looting through walls")
	wall.queue_free()
	await ticks()
	var pool := game.world_items.pool
	var temporary: Array[int] = []
	while pool.drops.size() < WorldItemPool.LIMIT:
		var drop := pool.spawn_at("apple", 1, 100, Vector3(0, 10, 0))
		temporary.append(drop.drop_id)
	check(not loot.perform(actor, 0) and loot.opened == 0, "full world pool leaves the chest closed and its loot safe")
	for id in temporary: pool.remove(id)
	await ticks()
	# A block at the second spill position forces rollback after the first spawn.
	wall = StaticBody3D.new()
	wall.position = chest.global_position + Vector3(0.6, 0.6, 1.5)
	root.add_child(wall)
	shape = CollisionShape3D.new()
	box = BoxShape3D.new()
	box.size = Vector3(0.5, 0.5, 0.5)
	shape.shape = box
	wall.add_child(shape)
	await ticks()
	var count := pool.drops.size()
	check(not loot.perform(actor, 0) and loot.opened == 0 and pool.drops.size() == count, "failed spill rolls back all spawned stacks atomically")
	wall.queue_free()
	await ticks()
	game.camera.position = actor.position + Vector3(10, 14, 16)
	game.camera.look_at(chest.global_position)
	game.camera.set_physics_process(false)
	game.camera.set_process(false)
	var source := game.shooting_view.local_input
	WorldInteractionFocus.select_focus(game.world_items, source, game.camera.unproject_position(chest.global_position + Vector3.UP * 1.2))
	check(game.world_items.focused_kind == "city_chest" and game.world_items.focused_plot == 0, "normal mouse targeting highlights the reachable chest")
	# Opening does not force inventory grants: a full bag leaves recoverable loot.
	var inventory := game.inventory.capture()
	for index in game.inventory.capacity: game.inventory.set_slot(index, ItemStack.new(InventoryItem.from_id("apple"), 50))
	check(loot.perform(actor, 0), "full personal bag still permits opening onto safe ground")
	var newest := pool.next_id - 1
	check(not game.world_items._pickup(newest, game.combat) and pool.drops.has(newest), "full bag never destroys uncollected chest supplies")
	for id in [newest, newest - 1]: pool.remove(id)
	game.inventory.restore(inventory)
	loot.restore(0)

func walk(target: Vector3) -> void:
	var reached := false
	for tick in 650:
		var offset := Vector2(target.x - actor.position.x, target.z - actor.position.z)
		if offset.length() < 0.2:
			reached = true
			break
		input.move = (offset * 1.8).limit_length()
		await physics_frame
	input.move = Vector2.ZERO
	await ticks()
	check(reached and absf(actor.position.y - target.y) < 0.4, "city doorway target %s reached at %s" % [target, actor.position])

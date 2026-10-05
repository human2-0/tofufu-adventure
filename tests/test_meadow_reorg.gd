extends SceneTree
## Farmstead acceptance: ownership, frontal displays, persistence and renewed food.

class WalkInput extends PlayerCommandSource:
	var movement := Vector2.UP
	func sample(_position: Vector3) -> PlayerCommand:
		var command := PlayerCommand.new()
		command.move = movement
		return command

var failures: int = 0
var game: AdventureGame

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if condition: return
	failures += 1
	printerr("FAIL: ", message)

func _run() -> void:
	game = preload("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.player.set_physics_process(false)
	game.encounters.set_physics_process(false)
	for mob in game.encounters.mob_nodes: mob.set_physics_process(false)
	await physics_frame
	game.player.position = game.world.quest_npc.position + Vector3(0, 0, -1.5)
	await physics_frame
	check(game.quest_giver.nearby(game.player), "Grandma is reachable from the courtyard side")
	var storage := game.seed_storage
	var barn := game.world.seed_bank
	var walk := WalkInput.new()
	game.player.add_child(walk)
	game.player.command_source = walk
	game.player.position = barn.to_global(Vector3(0, 0.1, 16.5))
	game.player.set_physics_process(true)
	for i in 100:
		await physics_frame
	game.player.set_physics_process(false)
	game.player.velocity = Vector3.ZERO
	check(barn.to_local(game.player.global_position).z < 13.5 and game.player.is_on_floor(), "real player walks up the ramp into the barn")
	walk.movement = Vector2.LEFT
	game.player.position = barn.to_global(Vector3(9.5, 0.1, 0))
	game.player.set_physics_process(true)
	for i in 100: await physics_frame
	game.player.set_physics_process(false)
	game.player.velocity = Vector3.ZERO
	check(barn.to_local(game.player.global_position).x < 2.8 and game.player.is_on_floor(), "courtyard entrance reaches central aisle without blocking chest dividers")
	check(storage.barn.banks.size() == 20, "twenty separate chest inventories")
	check(game.world.quest_npc.name == "GrandmaFufu" and game.world.weapon_merchant.name == "GrandpaFufu", "named billboard NPCs own village services")
	for npc: Node3D in [game.world.quest_npc, game.world.weapon_merchant]:
		var art := npc.get_node("DirectionalArt") as MeadowResidentArt
		art.set_process(false)
		for index in 5:
			art.present_direction([6, 7, 0, 1, 2][index])
			check(art.current_cell == index, "NPC has distinct north through south portraits")
			var body_height := art.texture.get_height() - 16
			check(is_equal_approx(body_height * art.pixel_size, 1.9), "NPC apparent height stays stable across views")
			var feet := (art.texture.get_height() * 0.5 - (art.texture.get_height() - 8) + art.offset.y) * art.pixel_size
			check(is_equal_approx(feet, 0.05), "NPC directional feet stay planted on the same baseline")
	game.camera.set_physics_process(false)
	for npc: Node3D in [game.world.quest_npc, game.world.weapon_merchant]:
		var art := npc.get_node("DirectionalArt") as MeadowResidentArt
		game.player.position = npc.global_position + Vector3.RIGHT * 2
		art._process(0)
		check(art.current_direction == 0 and not art.flip_h, "nearby player on the right receives an east-facing NPC view")
		game.player.position = npc.global_position + Vector3.LEFT * 2
		art._process(0)
		check(art.current_direction == 4 and art.flip_h, "NPC turns toward nearby player on the left")
	game.camera.set_physics_process(true)
	check(game.world.terrain.is_field(85, -64) and game.world.terrain.is_field(30, 40), "northeast soy and southern wheat fields")
	check(game.world.produce.size() == 36, "food beds and forest mushrooms composed")
	var locked: Node3D = game.world.get_node("D_WorkingUnits").get_child(1)
	var door_ray := PhysicsRayQueryParameters3D.create(locked.global_position + Vector3(0, 1, 5), locked.global_position + Vector3(0, 1, 0), 1)
	check(not game.get_world_3d().direct_space_state.intersect_ray(door_ray).is_empty(), "second unit has a solid locked door")
	for side in [-1.6, 1.6]:
		var side_ray := PhysicsRayQueryParameters3D.create(locked.global_position + Vector3(side, 1, 5), locked.global_position + Vector3(side, 1, 0), 1)
		check(not game.get_world_3d().direct_space_state.intersect_ray(side_ray).is_empty(), "locked door blocks side entry as well as center")
	var shed: Node3D = game.world.interiors[1]
	for side in [-4.2, 4.2]:
		var garage_ray := PhysicsRayQueryParameters3D.create(shed.global_position + Vector3(side, 1, 6), shed.global_position + Vector3(side, 1, 2.8), 1)
		check(game.get_world_3d().direct_space_state.intersect_ray(garage_ray).is_empty(), "wide garage front gives both tractors an entrance")
	check(MeadowVillageGround.lawn(Vector2(58, -15)) and MeadowGrass.habitat(game.world.terrain, 58, -15), "reactive fine grass covers village lawns")
	check(not MeadowGrass.habitat(game.world.terrain, 46, -24), "garden footpath stays clear of blades")
	var ceiling_ray := PhysicsRayQueryParameters3D.create(locked.global_position + Vector3(0, 8, 0), locked.global_position + Vector3(0, 1, 0), 1)
	check(not game.get_world_3d().direct_space_state.intersect_ray(ceiling_ray).is_empty(), "locked room cannot be entered by jumping through the roof")
	game.player.global_position = barn.to_global(MeadowBarn.table_position(0) + MeadowBarn.front(0) * 1.1 + Vector3.DOWN * 0.7)
	await physics_frame
	check(storage.bay_for(game.player) == 0, "first bay reachable from its front")
	game.inventory.set_slot(0, ItemStack.new(InventoryItem.create_edamame(), 17))
	check(storage.transfer(game.player, game.inventory, "inventory", 0, "chest", 0, 0), "deposit claims a personal bay")
	check(storage.barn.owners[0] == "solo" and storage.barn.banks[0].get_slot(0).count == 17, "ownership and whole stack retained")
	var other: Player = preload("res://game/player/player.tscn").instantiate()
	root.add_child(other)
	other.set_physics_process(false)
	other.global_position = game.player.global_position
	storage.barn.actor_key = func(actor: Node3D) -> String: return "solo" if actor == game.player else "b".repeat(64)
	var bag := PlayerInventory.new()
	check(not storage.transfer(other, bag, "chest", 0, "inventory", 0, 0), "another identity cannot withdraw")
	check(not storage.transfer(game.player, game.inventory, "chest", 0, "inventory", 0, 1), "stale bay request cannot access a different chest")
	game.inventory.set_slot(1, ItemStack.new(InventoryItem.create_edamame(), 4))
	check(game.world_items.drop_stack(game.combat, game.inventory, game.character_equipment, "inventory", 1), "dropping in bay places item on display table")
	var displayed: WorldItemDrop
	for drop in game.world_items.pool.drops.values():
		if drop.display_bay == 0: displayed = drop
	check(displayed != null, "table display exists")
	if displayed != null:
		check(not BarnDisplay.can_pickup(game.world_items, displayed, other), "visitors cannot steal an attended display")
		check(BarnDisplay.can_pickup(game.world_items, displayed, game.player), "owner retrieves from front")
		var at := displayed.global_position
		for i in 4: await physics_frame
		check(displayed.global_position.is_equal_approx(at), "display stays on table")
		var world := CoopWorld.capture(game)
		check(WorldProtocol.valid(world), "wire accepts ownership, display and produce values")
		var malformed: Dictionary = world.duplicate(true)
		malformed.barn.owners[0] = "forged"
		check(not WorldProtocol.valid(malformed), "malformed owner identity rejected")
		malformed = world.duplicate(true)
		malformed.world_items.back()[8].bay = 20
		check(not WorldProtocol.valid(malformed), "out-of-range display bay rejected")
		var save := AdventureSnapshot.capture(game, "Meadow", 0)
		check(SaveStore.valid(save), "save accepts barn and display state")
		storage.barn.banks[0].restore([])
		AdventureSnapshot.restore(game, save)
		check(storage.barn.banks[0].get_slot(0).count == 17, "personal contents survive save/restore")
		game.player.global_position = barn.global_position + Vector3(0, 0.6, 0)
		BarnDisplay.release_departed(game.world_items)
		check(displayed.protected_owner.is_empty(), "leaving the bay releases display")
		check(BarnDisplay.can_pickup(game.world_items, displayed, other), "public item collectible from the front")
		other.global_position = barn.to_global(MeadowBarn.bay_position(0) - MeadowBarn.front(0))
		check(not BarnDisplay.can_pickup(game.world_items, displayed, other), "rear collection is denied after release")
	var plant := game.world.produce[0]
	var target := game.meadow_harvest.targets[0]
	check(target.damage(1), "food crop is harvestable")
	check(plant.regrow_remaining > 0, "crop harvest starts regrowth")
	var found := false
	for drop in game.world_items.pool.drops.values():
		if drop.item_id == "potato" and drop.count == 2: found = true
	check(found, "harvest gives actual potatoes")
	check(WorldProtocol.valid(CoopWorld.capture(game)), "harvest state stays wire-valid")
	var command := PlayerCommand.new()
	command.attack_held = true
	command.punch_held = true
	game.player.global_position = barn.global_position + Vector3(0, 0.6, 0)
	BarnPeace.prepare(game, game.player, game.combat, command)
	check(not command.attack_held and not command.punch_held, "barn suppresses attacks")
	var member := CoopActor.new()
	member.actor = game.player
	member.combat = game.combat
	member.world_items = game.world_items
	check(member._filter_hit(50, Vector3.LEFT, Damageable.HitKind.SOY) == 0, "barn visitor protected from incoming fire")
	game.player.position = barn.position + Vector3.UP * 12
	check(member._filter_hit(50, Vector3.LEFT, Damageable.HitKind.SOY) == 0, "jumping over the barn does not bypass its safe area")
	member.free()
	other.queue_free()
	game.queue_free()
	for i in 3: await process_frame
	await create_timer(0.1).timeout
	print("Meadow reorganization tests: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: ", message)

func ticks(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame

func _run() -> void:
	var game := preload("res://game/app/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	await ticks(2)
	game.player.set_physics_process(false)
	game.player.position = Vector3.ZERO
	game.shooting_view.local_input.enabled = false
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	var gear: PlayerEquipment = game.combat.equipment
	var pool: WorldItemPool = game.world_items.pool
	var wall := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4, 3, 0.15)
	collision.shape = box
	wall.add_child(collision)
	game.add_child(wall)
	wall.position = Vector3(0, 1, -1.15)
	await ticks(2)
	gear.step(Vector2.UP, false, false, true, false, 1, 0.016)
	check(not gear.knife_owned and pool.drops.size() == 1, "knife leaves inventory only after safe world placement")
	var knife: WorldItemDrop = gear.dropped
	await ticks(45)
	check(knife.global_position.z > -0.75, "swept drop body stays in front of thin wall")
	check(knife.global_position.y > 0.2, "drop rests above floor")
	game.player.position = Vector3(0, 0, -2)
	check(not game.world_items._pickup(knife.drop_id, game.combat), "pickup cannot reach through a wall")
	game.player.position = Vector3.ZERO
	var other_actor := CharacterBody3D.new()
	game.add_child(other_actor)
	var other := PlayerCombat.new()
	other.actor = other_actor
	game.add_child(other)
	var other_loadout := ActorLoadout.new()
	other_loadout.combat = other
	other_loadout.inventory = PlayerInventory.new()
	other_loadout.equipment = CharacterEquipment.new()
	other.add_child(other_loadout)
	game.world_items.register(other, other_loadout.inventory, other_loadout)
	other.equipment.knife_owned = false
	var knife_id := knife.drop_id
	check(game.world_items._pickup(knife_id, other), "another actor can collect the dropped knife")
	check(other.equipment.knife_owned and not gear.knife_owned, "ownership transfers without restoring the original owner")
	check(not game.world_items._pickup(knife_id, game.combat), "same item cannot be claimed twice")
	wall.queue_free()
	await ticks(2)
	gear.step(Vector2.UP, false, false, true, false, 2, 0.016)
	check(not gear.gun_owned and not game.combat.gun.selected, "selected gun can be dropped")
	gear.step(Vector2.UP, false, false, false, false, 2, 0.016)
	check(not game.combat.gun.selected, "unowned gun cannot be selected")
	var gun_id: int = gear.dropped.drop_id
	check(game.world_items._pickup(gun_id, game.combat) and gear.gun_owned, "gun can be recovered")
	game.character_equipment.set_slot("combat_2", ItemStack.new(InventoryItem.weapon("sotjet"), 1))
	game.loadout.select(2)
	game.combat.sotjet.milk = 37
	gear.step(Vector2.RIGHT, false, false, true, false, 2, 0.016)
	var jet_id: int = gear.dropped.drop_id
	check(not gear.sotjet_owned and pool.drops[jet_id].reserve == 37, "Sotjet retains its dropped reservoir")
	check(game.world_items._pickup(jet_id, other), "another actor receives dropped weapon into a combat slot")
	check(other.sotjet.milk == 37 and not pool.drops.has(jet_id), "pickup preserves reservoir and consumes world item")
	other.equipment._drop()
	var returned_id: int = other.equipment.dropped.drop_id
	check(game.world_items._pickup(returned_id, game.combat) and game.combat.sotjet.milk == 37, "weapon can be returned by dropping it")
	var north := pool.spawn("knife", 1, Vector3.ZERO, Vector2.UP)
	var east := pool.spawn("soy_gun", 1, Vector3.ZERO, Vector2.RIGHT)
	check(pool.focused(Vector3.ZERO, Vector2.UP) == north.drop_id, "focus chooses aimed item among nearby drops")
	check(pool.focused(Vector3.ZERO, Vector2.RIGHT) == east.drop_id, "turning focus selects a different item")
	game.inventory.add_item(InventoryItem.create_soybean(), 15)
	check(game.world_items.drop_stack(game.combat, game.inventory, game.character_equipment, "inventory", 0), "bag stack can be dropped")
	check(game.inventory.count_item("soybean") == 0, "bag drop removes the stack exactly once")
	var stack_drop: WorldItemDrop
	for drop: WorldItemDrop in pool.drops.values():
		if drop.item_id == "soybean": stack_drop = drop
	for slot in PlayerInventory.CAPACITY: game.inventory.set_slot(slot, ItemStack.new(InventoryItem.create_soybean(), 999))
	check(not game.world_items._pickup(stack_drop.drop_id, game.combat) and stack_drop.count == 15, "full bag leaves world stack intact")
	game.inventory.get_slot(0).count = 998
	check(game.world_items._pickup(stack_drop.drop_id, game.combat) and stack_drop.count == 14, "partial pickup preserves the remainder on the ground")
	var save := AdventureSnapshot.capture(game, "Drops", 0)
	check(SaveStore.valid(save) and WorldProtocol.world_items(save.world_items), "drop snapshot passes save and network schemas")
	pool.restore([])
	AdventureSnapshot.restore(game, save)
	check(pool.drops.size() == 3 and not gear.knife_owned, "save restores world items independently of weapon ownership")
	var legacy := save.duplicate(true)
	legacy.erase("world_items")
	legacy.dropped_position = [0, 0, -1]
	AdventureSnapshot.restore(game, legacy)
	check(pool.drops.size() == 1 and pool.drops.values()[0].item_id == "knife", "legacy knife save migrates into shared pool")
	AdventureSnapshot.restore(game, save)
	var bad: Array = save.world_items.duplicate(true)
	bad[0][1] = "arbitrary_resource_path"
	check(not WorldProtocol.world_items(bad), "unknown network item identifiers are rejected")
	if "--preview" in OS.get_cmdline_user_args():
		other.queue_free()
		other_actor.queue_free()
		game.world_items.set_process(false)
		game.player.position = Vector3(0, 0, 1)
		pool.restore([[20, "knife", 1, 100, -0.9, 0.45, -0.2], [21, "soy_gun", 1, 100, 0, 0.45, -0.7], [22, "sotjet", 1, 37, 0.9, 0.45, -0.2]])
		pool.drops[21].set_focus(true, "[E] Pick up Soybean gun")
		game.camera.offset *= 0.45
		await ticks(30)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/tofufu-world-items.png")
	game.queue_free()
	await process_frame
	print("World items: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

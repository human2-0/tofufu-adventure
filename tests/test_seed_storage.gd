extends SceneTree

var failures := 0
var scene: Node3D

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	scene = preload("res://game/app/main.tscn").instantiate()
	scene.play_opening = false
	root.add_child(scene)
	await physics_frame
	var storage: SeedStorage = scene.seed_storage
	check(scene.world.seed_bank != null, "seed bank is composed into the meadow")
	var floor_from: Vector3 = scene.world.seed_bank.global_position + Vector3(0, 1.1, 0)
	var floor_to: Vector3 = scene.world.seed_bank.global_position + Vector3(0, -0.1, 0)
	var floor_ray := PhysicsRayQueryParameters3D.create(floor_from, floor_to, 1)
	var floor_hit := scene.get_world_3d().direct_space_state.intersect_ray(floor_ray)
	check(not floor_hit.is_empty() and floor_hit.position.y >= scene.world.seed_bank.global_position.y + 0.49, "solid finished floor keeps the player above the foundation")
	var satchel: WorldItemDrop
	for drop: WorldItemDrop in scene.world_items.pool.drops.values():
		if drop.item_id == "seed_satchel": satchel = drop
	check(satchel != null, "free Seed Satchel waits outside the bank")
	check(InventoryItem.backpack("seed_satchel").storage_slots == PlayerInventory.CAPACITY + 4, "Seed Satchel adds four bag slots")
	scene.player.global_position = satchel.global_position
	check(scene.world_items._pickup(satchel.drop_id, scene.combat), "nearby player can claim the free Seed Satchel")
	check(storage.free_satchel_claimed and not scene.world_items.pool.drops.has(satchel.drop_id), "claimed satchel is removed and cannot respawn")
	check(InventoryTransfer.apply(scene.inventory, scene.character_equipment, "inventory", 0, "equipment", "backpack"), "claimed satchel equips from the bag")
	check(scene.inventory.capacity == PlayerInventory.CAPACITY + 4, "equipped Seed Satchel expands the bag to fourteen slots")
	var doorway_from: Vector3 = scene.world.seed_bank.global_position + Vector3(0, 1.1, 4.1)
	var doorway_to: Vector3 = scene.world.seed_bank.global_position + Vector3(0, 1.1, 2.0)
	var doorway_ray := PhysicsRayQueryParameters3D.create(doorway_from, doorway_to, 1)
	check(scene.get_world_3d().direct_space_state.intersect_ray(doorway_ray).is_empty(), "open doorway provides a physical path into the bank")
	check(storage.chest.slots.size() == ChestInventory.CAPACITY and ChestInventory.CAPACITY == 24, "seed bank supplies 24 chest slots")
	var bean := InventoryItem.create_edamame()
	scene.inventory.set_slot(0, ItemStack.new(bean, 14))
	check(ChestTransfer.apply(scene.inventory, storage.chest, "inventory", 0, "chest", 4), "bag stack transfers into chest")
	check(scene.inventory.get_slot(0) == null and storage.chest.get_slot(4).count == 14, "transfer preserves the gathered stack")
	scene.inventory.set_slot(1, ItemStack.new(bean, 3))
	check(ChestTransfer.apply(scene.inventory, storage.chest, "inventory", 1, "chest", 4), "matching stacks merge in chest")
	check(storage.chest.get_slot(4).count == 17, "merged chest stack has complete count")
	var world_snapshot := CoopWorld.capture(scene)
	check(WorldProtocol.valid(world_snapshot), "co-op snapshot accepts the claimed satchel state")
	storage.chest.restore([])
	CoopWorld.apply(scene, world_snapshot, true)
	check(storage.chest.get_slot(4) != null and storage.chest.get_slot(4).count == 17, "host world snapshot replicates chest contents")
	var saved := AdventureSnapshot.capture(scene, "Storage test", 0.0)
	check(SaveStore.valid(saved), "save accepts the claimed satchel state")
	storage.chest.restore([])
	storage.free_satchel_claimed = false
	AdventureSnapshot.restore(scene, saved)
	check(storage.chest.get_slot(4) != null and storage.chest.get_slot(4).count == 17, "stored stack survives save restore")
	check(storage.free_satchel_claimed, "satchel claim survives save restore")
	scene.player.global_position = scene.world.seed_bank.global_position + Vector3(0, 0.2, 1.4)
	await physics_frame
	check(storage.nearby(scene.player), "player can reach storage from inside the open doorway")
	storage.window.open()
	check(storage.window.visible, "storage interaction opens chest transfer panel")
	await process_frame
	storage.window._chest_buttons[4].grab_focus()
	check(storage.window._description.text.contains("Fresh soybean"), "focused chest item shows its description")
	if "--preview" in OS.get_cmdline_user_args():
		root.size = Vector2i(960, 540)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/tofufu-chest-description.png")
	storage.window.close()
	scene.queue_free()
	await process_frame
	print("Seed storage tests: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

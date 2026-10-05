extends SceneTree
## Real adventure: E harvests, fruit remains on the ground, E explicitly collects.

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if ok: return
	failures += 1
	printerr("FAIL: ", message)

func _run() -> void:
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	var tree := game.world.apple_trees[0]
	var index := 0
	game.player.relocate(tree.global_position + Vector3(0, 0.2, 2.0))
	for frame in 5: await physics_frame
	var orchard := game.apple_harvest
	check(game.apple_tree_targets[index] not in game.combat.targets, "combat does not harvest the orchard")
	game.world_items.set_process(false)
	game.world_items.focused_kind = "apple_tree"
	orchard._process(0.0)
	check(orchard.focused_tree == tree and tree.prompt.text.begins_with("[E] Shake tree"), "tree starts with an E interaction prompt")
	var event := InputEventAction.new()
	event.action = "pickup_weapon"
	event.pressed = true
	orchard._unhandled_input(event)
	orchard._physics_process(0.0)
	check(not tree.can_harvest(), "E shakes the selected tree")
	check(not orchard.perform(game.player, index), "second shake cannot duplicate the fruit")
	await create_timer(0.7).timeout
	check(game.inventory.count_item("apple") == 0, "falling fruit is never granted automatically")
	var apples := apple_drops(game.world_items.pool)
	check(apples.size() == 1, "falling fruit becomes one shared four-apple stack")
	if apples.is_empty():
		quit(1)
		return
	var drop := apples[0]
	check(drop.item_id == "apple" and drop.count == 4, "exactly four apples wait on the ground")
	var visual := drop.get_child(drop.get_child_count() - 1) as AppleDropVisual
	check(visual != null and visual._apples.size() == 4, "the stack visibly contains four fruit meshes")
	for apple in visual._apples:
		check(apple.visible and apple.position.y < -0.25, "fallen apples sit at ground level")
	game.player.relocate(drop.global_position + Vector3(0, 0, 0.6))
	for frame in 35: await physics_frame
	check(game.inventory.count_item("apple") == 0 and game.world_items.pool.drops.has(drop.drop_id), "walking across apples does not collect them")
	check(game.world_items._pickup(drop.drop_id, game.combat), "explicit pickup collects nearby apples")
	check(game.inventory.count_item("apple") == 4 and apple_drops(game.world_items.pool).is_empty(), "E pickup transfers the four apples once")
	check(not game.world_items._pickup(drop.drop_id, game.combat), "repeated pickup cannot grant the removed stack")
	# A full bag leaves the entire stack visible; partial pickup keeps its remainder.
	var item := InventoryItem.from_id("apple")
	for slot in game.inventory.capacity:
		game.inventory.set_slot(slot, ItemStack.new(InventoryItem.create_edamame(), 100))
	var at := game.world.ground_point(game.player.position.x, game.player.position.z, WorldItemDrop.RADIUS + 0.02)
	var left := game.world_items.pool.spawn_at("apple", 4, 100.0, at)
	check(not game.world_items._pickup(left.drop_id, game.combat) and left.count == 4, "full bag cannot hide or collect fallen apples")
	game.inventory.set_slot(0, ItemStack.new(item, item.max_stack - 2))
	check(game.world_items._pickup(left.drop_id, game.combat) and left.count == 2, "partial pickup preserves two apples on the ground")
	var remaining := left.get_child(left.get_child_count() - 1) as AppleDropVisual
	remaining._process(0.0)
	check(remaining._apples[0].visible and remaining._apples[1].visible and not remaining._apples[2].visible and not remaining._apples[3].visible, "remaining quantity is reflected by visible ground fruit")
	# Pool saturation restores the tree without silently sending fruit into a bag.
	tree.apply_world_state(0.0)
	game.apple_tree_targets[index].current = 1.0
	game.player.relocate(tree.global_position + Vector3(0, 0.2, 2.0))
	while game.world_items.pool.drops.size() < WorldItemPool.LIMIT:
		game.world_items.pool.spawn_at("apple", 1, 100.0, Vector3(70, 2, 60))
	check(not orchard.perform(game.player, index) and tree.can_harvest(), "full drop pool leaves fruit available on the tree")
	var before := game.inventory.count_item("apple")
	orchard._apples_fell(4, tree.global_position, tree)
	check(game.inventory.count_item("apple") == before and tree.can_harvest(), "failed ground placement never invokes automatic inventory collection")
	game.queue_free()
	await process_frame
	print("Explicit apple pickup: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func apple_drops(pool: WorldItemPool) -> Array[WorldItemDrop]:
	var result: Array[WorldItemDrop] = []
	for drop: WorldItemDrop in pool.drops.values():
		if drop.item_id == "apple": result.append(drop)
	return result

extends SceneTree

var failures: int = 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("Running test_apple_trees...")
	var coop_world_script: Script = load("res://game/app/coop/coop_world.gd")
	check(coop_world_script != null, "co-op world snapshot script loads")
	var snapshot := {"mobs": [], "props": [], "dummies": [], "pickups": [], "phase": 0.0,
		"beans": 0, "kills": 0, "harvests": 0, "experience": 0, "next_pickup": 1,
		"places": [], "apple_trees": [], "world_items": [[1, "apple", 4, 100.0, 0.0, 0.0, 0.0]]}
	for i in 9: snapshot.mobs.append([0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
	for i in 24: snapshot.props.append([0.0, 0.0])
	for i in 3: snapshot.dummies.append([0.0, 0.0, 0, 0.0])
	for i in 20: snapshot.apple_trees.append([1.0, 0.0])
	check(WorldProtocol.valid(snapshot), "world protocol accepts bounded apple-tree records")
	snapshot.apple_trees[0] = [1.0, 181.0]
	check(not WorldProtocol.valid(snapshot), "world protocol rejects oversized tree regrowth timers")

	# 1. Test Apple InventoryItem
	var apple := InventoryItem.from_id("apple")
	check(apple != null, "apple item definition exists")
	check(apple.id == "apple", "apple id is apple")
	check(apple.name == "Apple", "apple name is Apple")
	check(apple.healing_amount == 50.0, "apple healing amount is 50")
	check(apple.heal_duration == 25.0, "apple duration is 25")
	check(apple.icon != null, "apple has icon")

	# 2. Test PlayerHealing with Apple compounding
	var healing := PlayerHealing.new()
	var vitals := VitalRules.new()
	var health := Damageable.new()
	health.maximum = 100.0
	health.current = 50.0
	vitals.maximum = 100.0
	vitals.current = 50.0
	healing.health = health
	healing.vitals = vitals

	check(healing.can_consume_apple(), "initially can consume apple")
	check(healing.apple_duration_remaining == 0.0, "initial duration is 0")

	# Consume 1 apple: recovers 50 HP and 50 SP over 25s (2 HP/s, 2 SP/s)
	check(healing.consume_apple(), "consume first apple succeeds")
	check(is_equal_approx(healing.apple_duration_remaining, 25.0), "apple duration is 25s after 1 apple")

	# Step 10s: should restore 20 HP and 20 SP
	healing.step(10.0)
	check(is_equal_approx(healing.apple_duration_remaining, 15.0), "15s duration remaining after 10s step")
	check(is_equal_approx(health.current, 70.0), "health recovered 20 HP over 10s")
	check(is_equal_approx(vitals.current, 70.0), "vitals recovered 20 SP over 10s")

	# Consume 4 more apples to test compounding up to 5 apples (max 125s)
	for i in 4:
		check(healing.consume_apple(), "consume compounded apple %d succeeds" % (i + 2))
	# 15s + 4 * 25s = 115s
	check(is_equal_approx(healing.apple_duration_remaining, 115.0), "duration compounded to 115s")
	# Add one more to reach 125s cap
	check(healing.consume_apple(), "consume apple to hit cap succeeds")
	check(is_equal_approx(healing.apple_duration_remaining, 125.0), "duration capped at 125s")

	# 6th apple must be rejected at cap
	check(not healing.can_consume_apple(), "cannot consume 6th apple at 125s cap")
	check(not healing.consume_apple(), "consume apple rejected when at cap")

	# Test that effect remains ongoing even when HP and SP are full
	health.current = 100.0
	vitals.current = 100.0
	healing.step(25.0)
	check(is_equal_approx(healing.apple_duration_remaining, 100.0), "timer continues counting down when HP/SP are full")
	check(health.current == 100.0, "health stays clamped at maximum")
	check(vitals.current == 100.0, "vitals stay clamped at maximum")

	# If player takes damage during the ongoing effect, it continues regenerating
	health.current = 60.0
	vitals.current = 60.0
	healing.step(10.0)
	check(is_equal_approx(healing.apple_duration_remaining, 90.0), "timer counts down to 90s")
	check(is_equal_approx(health.current, 80.0), "ongoing effect restores HP after taking damage")
	check(is_equal_approx(vitals.current, 80.0), "ongoing effect restores SP after spending stamina")

	# 3. Test consume_from_bag
	var inv := PlayerInventory.new()
	inv.add_item(InventoryItem.from_id("apple"), 3)
	check(inv.get_slot(0).count == 3, "bag slot has 3 apples")
	healing.apple_duration_remaining = 0.0
	check(healing.consume_from_bag(inv, 0), "consume apple from bag slot succeeds")
	check(inv.get_slot(0).count == 2, "bag slot count decreased to 2")
	check(is_equal_approx(healing.apple_duration_remaining, 25.0), "apple duration active after bag consumption")

	# 4. Test the 3D tree, explicit harvest, falling apples and regrowth lifecycle
	var tree := AppleTree.new()
	root.add_child(tree)
	tree.set_physics_process(false)
	check(tree.can_harvest(), "apple tree can initially be harvested")
	check(tree.apple_nodes.size() == 4, "apple tree has four visible apple meshes")
	for index in tree.apple_nodes.size():
		var node: Node3D = tree.apple_nodes[index]
		check(node.visible, "apple mesh is visible before harvest")
		check(tree.apple_home_positions[index].y > 1.5, "apple starts in the canopy")
	var item_pool := WorldItemPool.new()
	item_pool.build_visual = WorldItemVisuals.build
	root.add_child(item_pool)
	var apple_drop := item_pool.spawn("apple", AppleTree.APPLE_YIELD, Vector3(1.35, 0.1, 0), Vector2.RIGHT)
	check(apple_drop != null and apple_drop.count == 4, "four fallen apples create a collectible world stack")

	var fallen: Array[int] = []
	tree.apples_felled.connect(func(count: int, _at: Vector3) -> void: fallen.append(count))
	check(tree.harvest() == 4, "explicit harvest releases four apples")
	check(not tree.can_harvest(), "cannot harvest immediately after picking")
	check(is_equal_approx(tree.regrow_remaining, 180.0), "regrow timer is set to three minutes")
	await create_timer(0.55).timeout
	check(fallen.size() == 1 and fallen[0] == 4, "four apples fall from an explicit harvest")
	for node in tree.apple_nodes:
		check(not node.visible, "apple mesh disappears after falling")

	# Step half duration
	tree.step(90.0)
	check(not tree.can_harvest(), "cannot harvest midway through regrowth")
	check(is_equal_approx(tree.regrow_remaining, 90.0), "regrow timer is at 90s")

	# Step remaining duration
	tree.step(90.0)
	check(tree.can_harvest(), "can harvest after full regrowth timer")
	for index in tree.apple_nodes.size():
		var node: Node3D = tree.apple_nodes[index]
		check(node.visible, "apple meshes reappear after regrowth")
		check(node.position.y > 1.5, "regrown apple returns to the canopy")
	tree.queue_free()
	item_pool.queue_free()

	# 5. Test Meadow placement of 20 trees outside the village
	var meadow := Meadow.new()
	meadow.world_seed = 1847
	root.add_child(meadow)
	check(meadow.apple_trees.size() == 20, "exactly 20 apple trees placed in meadow, got %d" % meadow.apple_trees.size())

	for i in meadow.apple_trees.size():
		var t: AppleTree = meadow.apple_trees[i]
		var pos := t.position
		var in_village := Rect2(14, -22, 30, 50).has_point(Vector2(pos.x, pos.z))
		check(not in_village, "apple tree %d at (%.1f, %.1f) must be outside village" % [i, pos.x, pos.z])
		check(not meadow.is_water(pos), "apple tree %d at (%.1f, %.1f) must not be in water" % [i, pos.x, pos.z])
		check(t.apple_nodes.size() == 4, "placed apple tree %d has four fruit meshes" % i)
		for other_index in range(i):
			check(pos.distance_to(meadow.apple_trees[other_index].position) >= 8.0, "apple trees are spaced across the meadow")
	meadow.queue_free()
	health.free()
	await process_frame

	if failures > 0:
		printerr("Failed %d checks" % failures)
		quit(1)
	else:
		print("All apple tree checks passed!")
		quit(0)

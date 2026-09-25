extends SceneTree
## Quest path, gates, one-use milk crates, support healing and refinement law.

var failures: int = 0

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	if ok: return
	failures += 1
	push_error("FAIL: " + message)

func run() -> void:
	var game: Node3D = load("res://game/app/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	await physics_frame
	var dungeon: TofuDungeon = game.factory_dungeon
	check(game.world.tofu_factory.entrance_marker != null, "factory has an east meadow map marker")
	check(not game.inventory.refining_unlocked, "refining starts locked")
	game.inventory.set_slot(6, ItemStack.new(InventoryItem.create_edamame(), 100))
	check(CurrencyExchange.convert(game.inventory, 6, "edamame").begins_with("Refining is illegal"), "currency refinement is locked")
	dungeon._enter()
	check(game.player.position.x > 200 and game.world.tofu_factory.interior_built, "factory entrance opens traversable interior")
	dungeon._physics_process(0.016)
	check(dungeon._enemies.size() == 3 and dungeon._crates.size() == 2, "receiving station spawns distinct enemies and supply crates")
	var first_enemy: FactoryBean = dungeon._enemies[0]
	first_enemy.set_physics_process(false)
	game.player.relocate(first_enemy.position + Vector3(0, 0.1, 1.4))
	game.combat.strike(Vector2.UP, 0.0)
	for frame in 35: await physics_frame
	check(first_enemy.target.current < FactoryBean.HEALTH[first_enemy.kind], "real knife sweep damages original factory enemy")
	var crate: FactoryCrate = dungeon._crates[0]
	crate.target.damage(100)
	await process_frame
	var milk: WorldItemDrop = null
	for drop: WorldItemDrop in game.world_items.pool.drops.values():
		if drop.item_id == "soy_milk": milk = drop
	check(milk != null, "marked crate drops soy milk")
	if milk != null:
		game.player.relocate(milk.global_position)
		check(game.world_items._pickup(milk.drop_id, game.combat), "milk enters backpack")
		var slot := -1
		for i in game.inventory.capacity:
			var stack: ItemStack = game.inventory.get_slot(i)
			if stack != null and stack.item.id == "soy_milk": slot = i
		check(slot >= 0 and InventoryTransfer.apply(game.inventory, game.character_equipment, "inventory", slot, "equipment", "support_1"), "milk attaches to support slot")
		game.health.damage(60)
		var before: float = game.health.current
		check(game.healing.use_slot("support_1"), "milk activates")
		game.healing.step(2.5)
		check(is_equal_approx(game.health.current, minf(game.health.maximum, before + 50)), "milk heals 50 HP")
	var experience_before: int = game.progression.progress.experience
	for stage in TofuDungeonState.STATIONS.size():
		game.player.relocate(TofuFactory.CENTERS[stage] + Vector3(0,0.2,4))
		dungeon._physics_process(0.016)
		check(dungeon._enemies.size() > 0 or stage == 3, "stage %d has a combat wave" % stage)
		for enemy: FactoryBean in dungeon._enemies.duplicate(): enemy.target.damage(999)
		check(not dungeon.interact(game.player), "station rejects distant interactions")
		for unit in dungeon.state.required_units():
			dungeon.state.step(1.1)
			if stage == 0 or stage == 2:
				game.player.relocate(TofuFactory.bag(unit, stage) + Vector3.UP * 0.2)
				check(dungeon.interact(game.player), "pick up marked soy sack")
			game.player.relocate(TofuFactory.station(stage) + Vector3(0,0.2,2))
			check(dungeon.interact(game.player), "operate production station")
		if stage == 3:
			check(dungeon._enemies.size() == 4 and dungeon.state.process_remaining == 0, "coagulant triggers Dofu ambush before processing")
			for enemy: FactoryBean in dungeon._enemies.duplicate(): enemy.target.damage(999)

		check(dungeon.state.process_remaining > 0, "stage %d starts after work and combat" % stage)
		dungeon._physics_process(TofuDungeonState.PROCESS_SECONDS + 0.1)
		check(dungeon.state.stage == stage + 1, "stage %d advances" % stage)
		if stage < game.world.tofu_factory.gates.size():
			check(not game.world.tofu_factory.gates[stage].visible, "stage %d opens the next production gate" % stage)
	check(game.progression.progress.experience >= experience_before + 21 * 65 + 250, "factory mobs award bonus EXP including warden")
	check(dungeon.state.completed and game.inventory.refining_unlocked, "all six processes unlock refinement")
	check(CurrencyExchange.convert(game.inventory, 6, "press_edamame").begins_with("That currency"), "dungeon does not unlock a direct edamame-to-tofu shortcut")
	check(CurrencyExchange.convert(game.inventory, 6, "edamame").begins_with("Refined"), "100 edamame mature into one bean")
	check(game.inventory.get_slot(6).item.id == "mature_bean", "mature bean is the first resulting currency")
	check(CurrencyExchange.convert(game.inventory, 6, "mature_bean").begins_with("Refined"), "one mature bean refines into one white tofu")
	check(game.inventory.get_slot(6).item.id == "tofu_white_chunk", "white tofu follows mature bean only")
	var saved := dungeon.capture()
	var rule := TofuDungeonState.new()
	rule.restore(saved)
	check(rule.completed and rule.stage == 6 and rule.crate_broken(0), "completion and one-use crate survive save and restore")
	check(SaveStore.valid(AdventureSnapshot.capture(game, "Factory test", 300)), "completed dungeon remains a valid adventure save")
	game.player.position = Vector3(220,0.2,-94)
	dungeon.restore(saved)
	check(TofuFactory.contains(game.player.position), "old factory interior saves migrate to the new building")
	var partial := TofuDungeonState.new()
	partial.enter()
	partial.secured = true
	check(partial.operate(), "production accepts first delivered sack")
	check(not partial.operate(), "rapid repeated operation is rejected")
	var resumed := TofuDungeonState.new()
	resumed.restore(partial.capture())
	check(resumed.units == 1 and not resumed.secured, "delivered cargo persists while encounter restarts")
	var malformed := dungeon.capture_world()
	malformed.units = 4
	check(not WorldProtocol.factory(malformed), "network rejects excess production units")
	print("Tofu Dungeon: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures > 0 else 0)

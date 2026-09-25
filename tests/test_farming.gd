extends SceneTree

var failures: int = 0

func check(value: bool, message: String) -> void:
	if not value:
		push_error("FAIL: " + message)
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var crop := SoybeanCrop.new()
	var other := SoybeanCrop.new()
	check(not crop.harvest(), "empty cannot harvest")
	check(crop.plant() and not crop.plant(), "plant exactly once")
	crop.step(18)
	check(crop.phase() == SoybeanCrop.Phase.FLOWER, "flower milestone")
	check(not crop.harvest(), "premature harvest rejected")
	crop.step(100)
	check(crop.phase() == SoybeanCrop.Phase.RIPE and crop.pod_frame() == 10, "ripe capped frame")
	check(other.phase() == SoybeanCrop.Phase.EMPTY, "isolated plot state")
	check(crop.harvest() and not crop.harvest(), "single harvest")
	check(not crop.plant() and crop.pod_frame() == 11, "harvest animation before replant")
	crop.step(2)
	check(crop.plant(), "renewable soil")
	var game: Node3D = load("res://game/app/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	await physics_frame
	var plot: SoybeanPlot = game.farming.plots[3]
	game.player.position = plot.position + Vector3(0, 0.1, 1.2)
	check(game.farming.interact(plot), "nearby ripe plot harvest")
	check(game.encounters.pickups.size() == 3 and game.inventory.count_item("edamame") == 0, "harvest creates three ground edamame")
	var ground_bean: SoybeanPickup = game.encounters.pickups.values()[0]
	check(ground_bean.pixel_size * maxf(ground_bean.texture.get_width(), ground_bean.texture.get_height()) < 0.6, "ground bean remains smaller than the player")
	check(not game.farming.interact(plot), "no duplicate grant")
	for tick in 90: await physics_frame
	check(game.inventory.count_item("edamame") == 3, "nearby ground drops automatically enter backpack")
	if plot.crop.phase() == SoybeanCrop.Phase.HARVEST: plot.crop.step(2)
	check(game.farming.interact(plot), "replant soil")
	plot.crop.step(30)
	for i in PlayerInventory.CAPACITY:
		game.inventory.set_slot(i, ItemStack.new(InventoryItem.create_edamame(), 100))
	check(game.farming.interact(plot), "full bag can harvest into ground drops")
	for tick in 90: await physics_frame
	check(game.encounters.pickups.size() == 3 and game.inventory.count_item("edamame") == 1000, "full bag leaves currency on ground without loss")
	game.inventory.set_slot(0, null)
	for tick in 90: await physics_frame
	check(game.encounters.pickups.is_empty() and game.inventory.count_item("edamame") == 903, "ground currency can be recovered after making bag space")
	game.player.position = Vector3(20, 0, 20)
	check(not game.farming.interact(plot), "range validation")
	game.queue_free()
	await process_frame
	print("Farming checks complete")
	quit(1 if failures else 0)

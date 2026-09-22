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
	check(game.inventory.count_item("soybean") == 3, "three real bag beans")
	check(not game.farming.interact(plot), "no duplicate grant")
	plot.crop.step(2)
	check(game.farming.interact(plot), "replant soil")
	plot.crop.step(30)
	for i in PlayerInventory.CAPACITY:
		game.inventory.set_slot(i, ItemStack.new(InventoryItem.create_soybean(), 999))
	check(not game.farming.interact(plot) and plot.crop.phase() == SoybeanCrop.Phase.RIPE, "full bag preserves ripe crop")
	game.player.position = Vector3(20, 0, 20)
	check(not game.farming.interact(plot), "range validation")
	game.queue_free()
	await process_frame
	print("Farming checks complete")
	quit(1 if failures else 0)

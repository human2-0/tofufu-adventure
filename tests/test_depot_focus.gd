extends SceneTree
## Display desks and chest lids share a key but have distinct aim targets.

var failures := 0
var game: AdventureGame

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if value: return
	failures += 1
	printerr("FAIL: ", message)

func aim_at(at: Vector3) -> void:
	var items := game.world_items
	items.focused_id = 0
	items.focused_kind = ""
	items.focused_plot = -1
	var source := game.shooting_view.local_input
	source._pointer_aim = true
	WorldInteractionFocus.select_focus(items, source, game.camera.unproject_position(at))
	source.pickup_target = items.focused_id
	game.seed_storage._process(0)

func preview(name: String, at: Vector3) -> void:
	if "--preview" not in OS.get_cmdline_user_args(): return
	var expected := game.world_items.focused_kind
	Input.warp_mouse(game.camera.unproject_position(at))
	for i in 2: await process_frame
	game.world_items._process(0)
	game.seed_storage._process(0)
	check(game.world_items.focused_kind == expected, "actual mouse selects rendered " + name + " target")
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-depot-" + name + ".png")

func _run() -> void:
	game = preload("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.player.set_physics_process(false)
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	game.camera.set_physics_process(false)
	game.world_items.set_process(false)
	game.cycle.set_process(false)
	game.cycle.phase = 0.4
	game.cycle._process(0)
	await physics_frame
	await process_frame
	var storage := game.seed_storage
	var items := game.world_items
	var source := game.shooting_view.local_input
	var barn := game.world.seed_bank
	var interact := InputEventAction.new()
	interact.action = "pickup_weapon"
	interact.pressed = true
	for bay in [0, 10]:
		game.player.global_position = barn.to_global(MeadowBarn.table_position(bay) + MeadowBarn.front(bay) * 1.1 + Vector3.DOWN * 0.7)
		game.camera.position = game.player.position + Vector3(0, 7, 7)
		game.camera.look_at(barn.to_global(MeadowBarn.table_position(bay)))
		game.camera.fov = 55
		await physics_frame
		check(storage.bay_for(game.player) == bay, "front of either chest row selects its own bay")
		game.inventory.clear()
		game.inventory.set_slot(0, ItemStack.new(InventoryItem.create_edamame(), 4))
		check(items.drop_stack(game.combat, game.inventory, game.character_equipment, "inventory", 0), "drop places complete stack on desk")
		var display: WorldItemDrop
		for drop in items.pool.drops.values():
			if drop.display_bay == bay: display = drop
		check(display != null, "display created in selected bay")
		if display == null: continue
		var id := display.drop_id
		check(items.pool.reachable(display, game.player.global_position), "desk item reachable above the tabletop")
		aim_at(storage.focus_position(game.player))
		check(items.focused_kind == "storage" and source.pickup_target == 0, "aim at chest lid opens storage even with an item on desk")
		check(storage._prompt.visible and not display.label.visible, "only storage prompt visible when aimed at chest")
		storage._unhandled_input(interact)
		check(storage.window.visible, "shared interaction key opens selected chest")
		storage.window.close()
		await preview("chest-%d" % bay, storage.focus_position(game.player))
		# Simulate a focus change before the storage prompt's next process callback.
		WorldInteractionFocus.select_focus(items, source, game.camera.unproject_position(display.global_position))
		storage._unhandled_input(interact)
		check(not storage.window.visible, "stale chest prompt cannot consume an item interaction")
		aim_at(display.global_position)
		check(items.focused_kind == "drop" and source.pickup_target == id, "aim at actual desk item selects pickup rather than chest")
		check(not storage._prompt.visible, "chest prompt hidden while item is selected")
		await preview("item-%d" % bay, display.global_position)
		source._pointer_aim = false
		source._aim = Vector2(-MeadowBarn.front(bay).x, 0)
		items._process(0)
		storage._process(0)
		check(items.focused_id == id and source.pickup_target == id, "directional aim favors nearer desk item")
		check(display.label.visible and not storage._prompt.visible, "directional pickup shows only item prompt")
		for slot in game.inventory.capacity:
			game.inventory.set_slot(slot, ItemStack.new(InventoryItem.create_edamame(), 100))
		items._process(0)
		check(items.focused_id == id and display.label.text.begins_with("Bag full"), "full bag retains item focus with clear pickup feedback")
		check(not items._pickup(id, game.combat) and display.count == 4, "full bag leaves entire desk stack intact")
		game.inventory.clear()
		display.protected_owner = "visitor"
		items._process(0)
		check(items.focused_id == 0, "another owner's attended item does not become pickup focus")
		check(not items._pickup(id, game.combat), "focus changes cannot bypass attended owner protection")
		display.protected_owner = "solo"
		items._process(0)
		storage._process(0)
		storage._unhandled_input(interact)
		check(not storage.window.visible and source.enabled, "item focus leaves controls enabled for pickup")
		game.combat.equipment.step(source._aim, false, false, false, true, 0, 0.016, source.pickup_target)
		check(not items.pool.drops.has(id) and game.inventory.count_item("edamame") == 4, "selected pickup consumes desk stack exactly once")
		items._process(0)
		storage._process(0)
		check(items.focused_kind == "storage" and source.pickup_target == 0, "empty desk restores normal chest interaction")
		storage._unhandled_input(interact)
		check(storage.window.visible, "same key opens storage after item collected")
		storage.window.close()
	game.queue_free()
	for i in 3: await process_frame
	print("Depot focus: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

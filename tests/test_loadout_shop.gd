extends SceneTree
var failures: int = 0
func _initialize() -> void: call_deferred("_run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)
func _run() -> void:
	var game := preload("res://game/app/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	await process_frame
	game.player.set_physics_process(false)
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	check(CharacterEquipment.SLOTS.filter(func(s: String) -> bool: return s.begins_with("combat_")).size() == 2, "exactly two combat slots")
	check(CharacterEquipment.SLOTS.filter(func(s: String) -> bool: return s.begins_with("support_")).size() == 4, "four support slots")
	check(game.inventory.coins == 10, "new character has ten coins")
	game.merchant.purchase(game.player, game.inventory, "sotjet")
	check(game.inventory.coins == 10, "distant purchase cannot spend coins")
	game.player.position = game.world.ground_point(29, 5.2)
	await physics_frame
	check(game.merchant.nearby(game.player), "Kaji can be reached from front of weapon shop")
	await process_frame
	check(game.merchant._ring.visible and "Talk to Kaji" in game.merchant._prompt.text, "nearby merchant highlights with interaction prompt")
	var interact := InputEventAction.new()
	interact.action = "pickup_weapon"
	interact.pressed = true
	game.merchant._unhandled_input(interact)
	check(game.merchant.window.visible and not game.shooting_view.local_input.enabled, "interaction opens Kaji shop and pauses combat input")
	game.merchant.window.close()
	game.merchant.purchase(game.player, game.inventory, "sotjet")
	check(game.inventory.coins == 9 and game.inventory.get_slot(0).item.id == "sotjet", "one coin buys a real weapon item")
	game.inventory_window.execute_transfer("inventory", 0, "equipment", "combat_2")
	check(game.inventory.get_slot(0).item.id == "soy_gun", "equipping swaps previous combat item into bag")
	game.combat.equipment.step(Vector2.UP, false, false, false, false, 2, 0.016)
	check(game.combat.sotjet.selected and not game.combat.gun.selected, "key two selects equipped Soyjet")
	game.combat.sotjet.milk = 37
	game.inventory_window.execute_transfer("equipment", "combat_2", "inventory", 1)
	check(game.inventory.get_slot(1).reserve == 37 and not game.combat.sotjet.selected, "unequipping preserves weapon reserve and stops its use")
	check(not game.character_equipment.can_equip("support_1", game.inventory.get_slot(1)), "weapons cannot occupy support slots")
	game.health.current = 50
	game.character_equipment.set_slot("support_4", ItemStack.new(InventoryItem.create_soybean(), 2))
	var command := PlayerCommand.new()
	command.use_healing_4 = true
	game._on_command(command, 0.016)
	check(game.character_equipment.get_slot("support_4").count == 1, "fourth support slot consumes an item")
	var save := AdventureSnapshot.capture(game, "Equipment", 0)
	check(SaveStore.valid(save), "item loadout and coins are valid save data")
	game.inventory.coins = 0
	AdventureSnapshot.restore(game, save)
	check(game.inventory.coins == 9 and game.inventory.get_slot(1).reserve == 37, "save round trip keeps coins and stored weapon state")
	for i in PlayerInventory.CAPACITY: game.inventory.set_slot(i, ItemStack.new(InventoryItem.create_soybean(), 100))
	game.merchant.purchase(game.player, game.inventory, "knife")
	check(game.inventory.coins == 9, "full bag never spends coins")
	game.inventory.set_slot(0, null)
	game.inventory.coins = 0
	game.merchant.purchase(game.player, game.inventory, "knife")
	check(game.inventory.get_slot(0) == null, "insufficient funds cannot grant a weapon")
	var beans := InventoryItem.create_soybean()
	game.inventory.set_slot(0, ItemStack.new(beans, 999))
	game.inventory.set_slot(1, ItemStack.new(beans, 10))
	InventoryTransfer.apply(game.inventory, game.character_equipment, "inventory", 0, "inventory", 1)
	check(game.inventory.get_slot(1).count == 999 and game.inventory.get_slot(0).count == 10, "full source merges with overflow retained")
	game.character_equipment.set_slot("support_1", ItemStack.new(beans, 980))
	InventoryTransfer.apply(game.inventory, game.character_equipment, "inventory", 0, "equipment", "support_1")
	check(game.inventory.get_slot(0) == null and game.character_equipment.get_slot("support_1").count == 990, "bag merges into support")
	check(ItemStack.restore({"id": "soybean", "count": 999}) != null and ItemStack.restore({"id": "soybean", "count": 1000}) == null, "save stack limit is 999")
	game.merchant.sell(game.player, game.inventory, 1, "soybean")
	check(game.inventory.coins == 1 and game.inventory.get_slot(1).count == 998, "sale exchanges one gathered item for a coin")
	game.merchant.sell(game.player, game.inventory, 1, "knife")
	check(game.inventory.coins == 1, "stale sale cannot sell a different item")
	game.player.position = Vector3.ZERO
	game.merchant.sell(game.player, game.inventory, 1, "soybean")
	check(game.inventory.coins == 1, "distant sale rejected")
	game.player.position = game.world.ground_point(29, 5.2)
	if "--preview" in OS.get_cmdline_user_args():
		game.inventory.coins = 9
		game.inventory.restore(save.inventory)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/tofufu-kaji-highlight.png")
		game.inventory_window.open()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/tofufu-support-loadout.png")
		game.inventory_window.close()
		game.merchant.window.show()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/tofufu-weapon-shop.png")
		game.merchant.window._sales.get_parent().get_parent().current_tab = 1
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/tofufu-sell-shop.png")
	game.queue_free()
	await process_frame
	print("Loadout/shop: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if value: return
	failures += 1
	push_error("FAIL: " + message)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var bag := PlayerInventory.new()
	bag.add_item(InventoryItem.apple(), 3)
	bag.add_item(InventoryItem.soy_milk(), 2)
	bag.add_item(InventoryItem.apparel("celestial_armor"), 1)
	var window := InventoryWindow.new()
	window.inventory = bag
	window.equipment = CharacterEquipment.new()
	root.add_child(window)
	window.open()
	await process_frame
	await process_frame
	var apple := window._inv_buttons[0]
	apple.grab_focus()
	apple.mouse_entered.emit()
	check(window._tooltip._panel.visible, "controller focus opens occupied-slot tooltip")
	check(window._tooltip._title.text.contains("×3"), "stack count shown")
	check(window._tooltip._type.text.contains("Consumable"), "food type shown")
	check(window._tooltip._details.text.contains("+50 SP") and window._tooltip._details.text.contains("125s"), "apple HP, stamina and stacking shown")
	check(not window._tooltip._panel.get_global_rect().intersects(apple.get_global_rect()), "tooltip placed beside slot")
	var joy := InputEventJoypadButton.new()
	joy.button_index = JOY_BUTTON_RIGHT_STICK
	joy.pressed = true
	root.push_input(joy)
	check(not window._tooltip._panel.visible, "R3 hides tooltip")
	window._inv_buttons[1].grab_focus()
	check(not window._tooltip._panel.visible, "focus change respects hidden preference")
	joy.pressed = false
	root.push_input(joy)
	joy.pressed = true
	root.push_input(joy)
	check(window._tooltip._panel.visible and window._tooltip._details.text.contains("+50 HP over 2.5s"), "R3 restores current milk details")
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	wheel.position = window._inv_buttons[1].get_global_rect().get_center()
	root.push_input(wheel)
	check(not ItemTooltip.details_enabled, "wheel over item toggles details")
	wheel.pressed = false
	root.push_input(wheel)
	wheel.pressed = true
	root.push_input(wheel)
	check(ItemTooltip.details_enabled, "wheel restores details")
	window._inv_buttons[2].grab_focus()
	check(window._tooltip._details.text.contains("1% per piece") and window._tooltip._details.text.contains("Full set: 50%"), "individual protection distinguished from set bonus")
	check(window._tooltip._type.text.contains("Requires Lv. 5"), "level requirement shown")
	root.size = Vector2i(960, 540)
	await process_frame
	await process_frame
	var bounds := root.get_visible_rect()
	check(bounds.encloses(window._tooltip._panel.get_global_rect()), "tooltip stays in smaller viewport")
	bag.set_slot(2, null)
	window._tooltip._update()
	check(not window._tooltip._panel.visible, "removed item cannot leave stale details")
	window.close()
	var chest := ChestWindow.new()
	chest.inventory = bag
	chest.chest = ChestInventory.new()
	root.add_child(chest)
	chest.open()
	await process_frame
	chest._bag_buttons[0].grab_focus()
	check(chest._tooltip._panel.visible, "deposit shares item inspector")
	chest.close()
	var shop := WeaponShopWindow.new()
	shop.inventory = bag
	root.add_child(shop)
	shop.open()
	await process_frame
	shop._first_button.grab_focus()
	check(shop._tooltip._panel.visible and shop._tooltip._type.text == "Weapon", "shop stock shares inspector")
	var quest := InventoryItem.new()
	quest.category = "quest"
	check(ItemTooltipContent.type_label(quest) == "Quest item", "quest item category supported")
	if "--preview" in OS.get_cmdline_user_args():
		shop.close()
		window.open()
		bag.set_slot(2, ItemStack.new(InventoryItem.apparel("celestial_armor")))
		await process_frame
		await process_frame
		window._inv_buttons[2].grab_focus()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/tofufu-item-tooltip.png")
	print("Item tooltip: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

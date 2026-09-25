extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error("FAIL: " + message)

func key(code: Key, echo_event: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	event.echo = echo_event
	root.push_input(event)
	event = event.duplicate()
	event.pressed = false
	event.echo = false
	root.push_input(event)

func _run() -> void:
	var app := preload("res://game/app/launch.tscn").instantiate()
	app.store.directory = "user://test_inventory_input"
	app.preferences.path = "user://test_inventory_input.cfg"
	root.add_child(app)
	app._start(0, {"name": "Inventory test", "opening_complete": true})
	var game: Node3D = app.game
	await process_frame
	# Co-op disables this solo handler; modal controls must survive.
	game.set_process_unhandled_input(false)
	key(KEY_I)
	check(game.inventory_window.visible, "I opens inventory")
	await process_frame
	check(game.inventory_window.visible, "inventory stays open")
	check(not game.shooting_view.local_input.enabled, "inventory blocks gameplay")
	key(KEY_I, true)
	check(game.inventory_window.visible, "key repeat does not close inventory")
	check(not game.chat.view.available, "modal blocks chat input")
	key(KEY_B)
	check(not game.inventory_window.visible, "B closes inventory")
	key(KEY_B)
	check(game.inventory_window.visible, "B opens inventory")
	key(KEY_ESCAPE)
	check(not game.inventory_window.visible, "Escape closes inventory")
	check(game.shooting_view.local_input.enabled, "closing restores gameplay")
	check(not app.menu.visible, "Escape closes bag before pause menu")
	game.chat.view.set_editing(true)
	key(KEY_I)
	check(not game.inventory_window.visible, "typing I in chat does not open bag")
	game.chat.view.set_editing(false)
	key(KEY_I)
	app._input_enabled(false)
	check(not game.inventory_window.visible and not game.shooting_view.local_input.enabled, "menu closes bag and keeps input blocked")
	app._input_enabled(true)
	game.inventory.add_item(InventoryItem.create_edamame(), 100)
	game.inventory.refining_unlocked = true
	key(KEY_I)
	await process_frame
	var right_click := InputEventMouseButton.new()
	right_click.button_index = MOUSE_BUTTON_RIGHT
	right_click.pressed = true
	game.inventory_window._inv_buttons[0]._gui_input(right_click)
	check(game.inventory_window._refine_menu.visible and not game.inventory_window._refine_menu.is_item_disabled(0), "right-click full bean stack opens enabled refine action")
	game.inventory_window._refine_menu.id_pressed.emit(0)
	check(game.inventory.count_item("edamame") == 0 and game.inventory.count_item("mature_bean") == 1, "backpack context action refines the selected stack")
	game.inventory_window._refine_menu.hide()
	game.inventory_window._inv_buttons[0]._gui_input(right_click)
	check(not game.inventory_window._refine_menu.is_item_disabled(0), "a single mature bean can refine to one white tofu")
	check(game.inventory_window._refine_menu.get_item_text(0).contains("1 → 1"), "mature bean menu shows the one-for-one rate")
	game.inventory_window._refine_menu.hide()
	game.inventory_window._inv_buttons[0].focus_entered.emit()
	check(game.inventory_window._description.text.contains("Shop currency"), "focused item shows its description")
	check(game.inventory_window._inv_buttons[0].tooltip_text.contains("Shop currency"), "hover tooltip includes item description")
	if "--preview" in OS.get_cmdline_user_args():
		game.inventory.add_item(InventoryItem.create_edamame(), 15)
		game.inventory.add_item(InventoryItem.create_edamame(), 5)
		game.inventory.add_item(InventoryItem.currency("tofu_white_chunk"), 3)
		game.inventory.add_item(InventoryItem.currency("toasted_tofu_chunk"), 5)
		game.inventory.add_item(InventoryItem.currency("golden_tofu_chunk"), 100)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/tofufu-inventory.png")
		root.size = Vector2i(960, 540)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/tofufu-inventory-small.png")
	app.queue_free()
	await process_frame
	print("Inventory input: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

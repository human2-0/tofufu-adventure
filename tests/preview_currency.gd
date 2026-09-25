extends SceneTree
## Visual QA for all five currency sheets in actual backpack slot buttons.

const IDS: Array[String] = ["edamame", "mature_bean", "tofu_white_chunk", "toasted_tofu_chunk", "golden_tofu_chunk"]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(570, 520)
	var background := ColorRect.new()
	background.color = Color("112a28")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.position = Vector2(20, 25)
	grid.add_theme_constant_override("h_separation", 13)
	grid.add_theme_constant_override("v_separation", 16)
	background.add_child(grid)
	var heading := Label.new()
	heading.text = "STACK"
	heading.custom_minimum_size = Vector2(130, 0)
	grid.add_child(heading)
	for count in range(1, 6):
		var label := Label.new()
		label.text = str(count) if count < 5 else "5+"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(60, 0)
		grid.add_child(label)
	for id in IDS:
		var name := Label.new()
		name.text = InventoryItem.currency(id).name
		name.custom_minimum_size = Vector2(130, 60)
		grid.add_child(name)
		for count in range(1, 6):
			var slot := InventorySlotButton.new()
			slot.custom_minimum_size = Vector2(60, 60)
			grid.add_child(slot)
			slot.present(ItemStack.new(InventoryItem.currency(id), count), null, id, "", false)
	for frame in 12: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-currency-crops.png")
	quit()

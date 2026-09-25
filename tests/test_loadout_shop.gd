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
	check(game.inventory.count_item("mature_bean") == 0, "new character starts without shop tender")
	game.merchant.purchase(game.player, game.inventory, "sotjet")
	check(game.inventory.count_item("mature_bean") == 0, "distant purchase cannot spend tender")
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
	check(game.merchant.window._stock_grid.get_child_count() == 13, "shop presents all gear and apparel in a stock tile grid")
	game.merchant.window._first_button.grab_focus()
	check(game.merchant.window._description.text.contains("close-range blade"), "focused shop item shows its description")
	game.merchant.window.close()
	game.inventory.add_item(InventoryItem.currency("mature_bean"), 2)
	game.merchant.purchase(game.player, game.inventory, "sotjet")
	var sotjet_slot := _slot_of(game.inventory, "sotjet")
	check(game.inventory.count_item("mature_bean") == 2 and sotjet_slot >= 0, "weapon purchase is free and keeps mature beans untouched")
	game.inventory_window.execute_transfer("inventory", sotjet_slot, "equipment", "combat_2")
	check(game.character_equipment.get_slot("combat_2").item.id == "sotjet", "equipping moves Soyjet into a combat slot")
	game.combat.equipment.step(Vector2.UP, false, false, false, false, 2, 0.016)
	check(game.combat.sotjet.selected and not game.combat.gun.selected, "key two selects equipped Soyjet")
	game.combat.sotjet.milk = 37
	game.inventory_window.execute_transfer("equipment", "combat_2", "inventory", sotjet_slot)
	check(game.inventory.get_slot(sotjet_slot).reserve == 37 and not game.combat.sotjet.selected, "unequipping preserves weapon reserve and stops its use")
	game.merchant.purchase(game.player, game.inventory, "sproutwood_staff")
	var staff_slot := _slot_of(game.inventory, "sproutwood_staff")
	check(game.inventory.count_item("mature_bean") == 2 and staff_slot >= 0, "Kaji sells the Sproutwood Staff for zero Mature Beans")
	game.inventory_window.execute_transfer("inventory", staff_slot, "equipment", "combat_2")
	game.combat.equipment.step(Vector2.UP, false, false, false, false, 2, 0.016)
	check(game.combat.equipment.staff_selected and game.combat.staff.visible and not game.combat.sword.visible, "equipped staff selects its mesh-backed melee combat mode")
	game.combat.strike(Vector2.UP, 0.0)
	check(is_equal_approx(game.combat._shape.size.z, game.combat.tuning.staff_length) and is_equal_approx(game.combat._melee_damage(), 5.0), "staff attack uses its authored hit volume and power-five damage")
	var target_body := StaticBody3D.new()
	var target_shape := CollisionShape3D.new()
	var target_bounds := SphereShape3D.new()
	target_bounds.radius = 0.1
	target_shape.shape = target_bounds
	target_body.add_child(target_shape)
	var target := Damageable.new()
	target.maximum = 100.0
	target.body = target_body
	target_body.add_child(target)
	var staff_pose := KnifeAttack.pose(KnifeAttack.Style.SLASH, game.player.global_position, Vector2.UP, 0.5, game.combat.tuning)
	game.add_child(target_body)
	target_body.global_position = staff_pose * Vector3(0, 0, -game.combat.tuning.staff_length * 0.92)
	var targets: Array[Damageable] = [target]
	game.combat.targets = targets
	await physics_frame
	game.combat._resolve_blade(game.player.global_position, staff_pose)
	check(target.current <= 100.0, "staff strike resolves safely against an extended-reach target")
	target_body.queue_free()
	game.combat.targets.clear()
	game.combat.reset()
	game.merchant.purchase(game.player, game.inventory, "bright_leaf_helmet")
	var bright_helmet_slot := _slot_of(game.inventory, "bright_leaf_helmet")
	game.inventory_window.execute_transfer("inventory", bright_helmet_slot, "equipment", "helmet")
	check(game.character_equipment.get_slot("helmet") == null and _slot_of(game.inventory, "bright_leaf_helmet") >= 0, "level-one player keeps purchased armor in the bag")
	game.progression.progress.award_experience(CharacterProgress.threshold(5, true))
	check(game.character_equipment.wearer_level == 5, "level-five progress unlocks leaf armor")
	for slot in ["helmet", "armor", "legs", "boots"]:
		var apparel_id := "bright_leaf_%s" % slot
		if slot != "helmet": game.merchant.purchase(game.player, game.inventory, apparel_id)
		var apparel_slot := _slot_of(game.inventory, apparel_id)
		check(apparel_slot >= 0, "%s is available in Kaji's stock" % apparel_id)
		game.inventory_window.execute_transfer("inventory", apparel_slot, "equipment", slot)
		if slot == "helmet":
			var before: float = game.health.current
			game.health.damage(20.0)
			check(is_equal_approx(before - game.health.current, 19.8), "one worn piece reduces an actual health hit by one percent")
			game.health.heal(20.0)
	check(game.player.visuals.worn_set == "bright_leaf", "wearing the four Bright Leaf pieces changes the character appearance")
	check(is_equal_approx(game.health.armor_multiplier, 0.90), "complete Bright Leaf outfit grants ten percent total damage reduction")
	var before_full_hit: float = game.health.current
	game.health.damage(20.0)
	check(is_equal_approx(before_full_hit - game.health.current, 18.0), "complete outfit reduces an actual health hit by ten percent")
	game.health.heal(20.0)
	check(game.inventory.count_item("mature_bean") == 2, "the complete outfit costs zero Mature Beans")
	for slot in CharacterEquipment.APPAREL_SLOTS:
		var apparel_id := "dark_leaf_%s" % slot
		game.merchant.purchase(game.player, game.inventory, apparel_id)
		game.inventory_window.execute_transfer("inventory", _slot_of(game.inventory, apparel_id), "equipment", slot)
		if slot == "helmet":
			check(game.player.visuals.worn_set.is_empty() and is_equal_approx(game.health.armor_multiplier, 0.96), "mixed armor has no complete-set look or bonus")
	check(game.player.visuals.worn_set == "dark_leaf" and is_equal_approx(game.health.armor_multiplier, 0.90), "complete Dark Leaf outfit changes the look and grants ten percent protection")
	check(_body_height(FufuWornAppearance.BRIGHT_STANDING, 5, 1) * FufuWornAppearance.STANDING_PIXEL_SIZE > 1.0, "Bright Leaf standing art matches the base character height")
	var dark_standing_height := _body_height(FufuWornAppearance.DARK_STANDING, 5, 1) * FufuWornAppearance.STANDING_PIXEL_SIZE
	check(dark_standing_height > 1.0 and dark_standing_height < 1.2, "Dark Leaf standing art stays close to the base character height")
	for row in FufuWornAppearance.WALK_ROW_STARTS.size():
		var bright_walk_height := _walk_row_height(FufuWornAppearance.BRIGHT_WALK, row) * FufuWornAppearance.WALK_PIXEL_SIZE
		var dark_walk_height := _walk_row_height(FufuWornAppearance.DARK_WALK, row) * FufuWornAppearance.WALK_PIXEL_SIZE
		check(bright_walk_height > 1.0 and bright_walk_height < 1.2, "Bright Leaf walking direction %s matches base character scale" % row)
		check(dark_walk_height > 1.0 and dark_walk_height < 1.2, "Dark Leaf walking direction %s matches base character scale" % row)
		check(_walk_row_has_margin(FufuWornAppearance.BRIGHT_WALK, row) and _walk_row_has_margin(FufuWornAppearance.DARK_WALK, row), "walking direction %s keeps the whole sprout and boots inside each crop" % row)
	var visuals: FufuVisuals = game.player.visuals
	var walk_direction_rows: Array[int] = [2, 3, 4, 3, 2, 1, 0, 1]
	for set_id in ["bright_leaf", "dark_leaf"]:
		var expected_walk: Texture2D = FufuWornAppearance.BRIGHT_WALK if set_id == "bright_leaf" else FufuWornAppearance.DARK_WALK
		for facing in walk_direction_rows.size():
			for phase in 4:
				visuals.worn_appearance.apply(visuals, set_id, facing, true, phase)
				var row := walk_direction_rows[facing]
				var walk_cell := visuals.texture as AtlasTexture
				check(walk_cell != null and walk_cell.atlas == expected_walk, "%s walking appearance uses its own source art" % set_id)
				check(walk_cell.region == Rect2(FufuWornAppearance.WALK_COLUMN_STARTS[phase], FufuWornAppearance.WALK_ROW_STARTS[row], FufuWornAppearance.WALK_CELL_SIZE.x, FufuWornAppearance.WALK_CELL_SIZE.y), "%s walk facing %s phase %s selects its full pose" % [set_id, facing, phase])
				check(visuals.hframes == 1 and visuals.vframes == 1 and is_equal_approx(visuals.pixel_size, FufuWornAppearance.WALK_PIXEL_SIZE), "%s walking pose keeps its calibrated scale" % set_id)
	var facing_columns: Array[int] = [2, 3, 4, 3, 2, 1, 0, 1]
	var phase_rows: Array[int] = [0, 1, 2, 3, 3, 3, 4, 4, 4, 4]
	for set_id in ["bright_leaf", "dark_leaf"]:
		var expected_atlas: Texture2D = FufuWornAppearance.BRIGHT_JUMP if set_id == "bright_leaf" else FufuWornAppearance.DARK_JUMP
		var jump_bounds: Array = FufuWornAppearance.BRIGHT_JUMP_BOUNDS if set_id == "bright_leaf" else FufuWornAppearance.DARK_JUMP_BOUNDS
		for phase in phase_rows.size():
			for facing in facing_columns.size():
				visuals.worn_appearance.apply_jump(visuals, set_id, facing, phase)
				var jump_cell := visuals.texture as AtlasTexture
				check(jump_cell != null and jump_cell.atlas == expected_atlas, "%s jump appearance uses its own source art" % set_id)
				var column := facing_columns[facing]
				var row := phase_rows[phase]
				var bounds: Array = jump_bounds[column]
				var region := jump_cell.region
				check(region.position.x == FufuWornAppearance.JUMP_COLUMN_STARTS[column] and region.size.x == FufuWornAppearance.JUMP_COLUMN_WIDTH, "%s jump facing %s uses the full painted column" % [set_id, facing])
				check(region.position.y <= bounds[row * 2] and region.end.y > bounds[row * 2 + 1], "%s jump phase %s keeps its sprout and boots" % [set_id, phase])
				var pose_height: float = (bounds[row * 2 + 1] - bounds[row * 2] + 1) * visuals.pixel_size
				check(pose_height > 0.8 and pose_height < 1.2, "%s jump phase %s stays at character scale" % [set_id, phase])
	visuals.set_worn_set("dark_leaf")
	var jump_command := PlayerCommand.new()
	visuals.present(jump_command, Vector3.UP * 3.0, false, false, 0.016)
	check(visuals._using_jump_frame and visuals.texture is AtlasTexture and (visuals.texture as AtlasTexture).atlas == FufuWornAppearance.DARK_JUMP, "equipped appearance stays on its jump sheet during flight")
	check(not game.character_equipment.can_equip("support_1", game.inventory.get_slot(1)), "weapons cannot occupy support slots")
	check(not game.character_equipment.can_equip("support_4", ItemStack.new(InventoryItem.create_edamame(), 2)), "currency cannot occupy support slots")
	var save := AdventureSnapshot.capture(game, "Equipment", 0)
	check(SaveStore.valid(save), "item loadout and currency are valid save data")
	AdventureSnapshot.restore(game, save)
	check(game.inventory.get_slot(sotjet_slot).reserve == 37 and game.character_equipment.get_slot("combat_2").item.id == "sproutwood_staff", "save round trip keeps staff loadout state")
	check(game.player.visuals.worn_set == "dark_leaf" and is_equal_approx(game.health.armor_multiplier, 0.90), "save round trip restores the complete outfit and protection")
	var older_outfit_save := save.duplicate(true)
	older_outfit_save.progression = CharacterProgress.new().capture()
	AdventureSnapshot.restore(game, older_outfit_save)
	check(game.player.visuals.worn_set.is_empty() and is_equal_approx(game.health.armor_multiplier, 1.0), "legacy level-one outfit loses its look and protection")
	for slot_name in CharacterEquipment.APPAREL_SLOTS:
		var item_id := "dark_leaf_%s" % slot_name
		var recovered := _slot_of(game.inventory, item_id) >= 0
		for pending in game.inventory.pending_items:
			if pending.item.id == item_id: recovered = true
		check(game.character_equipment.get_slot(slot_name) == null and recovered, "legacy level-one %s leaves equipment without losing the item" % slot_name)
	for i in PlayerInventory.CAPACITY: game.inventory.set_slot(i, ItemStack.new(InventoryItem.create_edamame(), 100))
	game.inventory.set_slot(0, ItemStack.new(InventoryItem.currency("mature_bean"), 1))
	game.merchant.purchase(game.player, game.inventory, "knife")
	check(game.inventory.count_item("mature_bean") == 1, "full bag blocks a free purchase without changing currency")
	game.inventory.set_slot(0, null)
	game.merchant.purchase(game.player, game.inventory, "knife")
	check(game.inventory.get_slot(0) != null and game.inventory.get_slot(0).item.id == "knife", "free gear can be bought without Mature Beans")
	var beans := InventoryItem.create_edamame()
	game.inventory.set_slot(0, ItemStack.new(beans, 100))
	game.inventory.set_slot(1, ItemStack.new(beans, 10))
	InventoryTransfer.apply(game.inventory, game.character_equipment, "inventory", 0, "inventory", 1)
	check(game.inventory.get_slot(1).count == 100 and game.inventory.get_slot(0).count == 10, "full source merges with overflow retained")
	check(not game.character_equipment.can_equip("support_1", game.inventory.get_slot(0)), "currency stays out of support slots")
	check(ItemStack.restore({"id": "edamame", "count": 100}) != null and ItemStack.restore({"id": "edamame", "count": 101}) == null, "currency save stack limit is 100")
	game.inventory.set_slot(1, ItemStack.new(InventoryItem.weapon("knife"), 1))
	game.merchant.sell(game.player, game.inventory, 1, "knife")
	check(game.inventory.count_item("mature_bean") == 1 and game.inventory.get_slot(1).item.id == "mature_bean", "sale exchanges combat equipment for mature tender")
	game.merchant.sell(game.player, game.inventory, 1, "knife")
	check(game.inventory.count_item("mature_bean") == 1, "stale sale cannot mint tender")
	game.player.position = Vector3.ZERO
	game.merchant.sell(game.player, game.inventory, 1, "knife")
	check(game.inventory.count_item("mature_bean") == 1, "distant sale rejected")
	game.player.position = game.world.ground_point(29, 5.2)
	if "--preview" in OS.get_cmdline_user_args():
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
		root.size = Vector2i(960, 540)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/tofufu-weapon-shop-small.png")
		root.size = Vector2i(1280, 720)
	game.queue_free()
	await process_frame
	print("Loadout/shop: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _slot_of(inventory: PlayerInventory, item_id: String) -> int:
	for slot in inventory.capacity:
		var stack := inventory.get_slot(slot)
		if stack != null and stack.item != null and stack.item.id == item_id: return slot
	return -1

func _body_height(texture: Texture2D, columns: int, rows: int) -> float:
	var image := texture.get_image()
	if image.is_compressed(): image.decompress()
	var tallest := 0
	for row in rows:
		for column in columns:
			var x0 := int(floor(float(column * image.get_width()) / columns))
			var x1 := int(floor(float((column + 1) * image.get_width()) / columns))
			var y0 := int(floor(float(row * image.get_height()) / rows))
			var y1 := int(floor(float((row + 1) * image.get_height()) / rows))
			var top := y1
			var bottom := -1
			for y in range(y0, y1):
				for x in range(x0, x1):
					if image.get_pixel(x, y).a > 0.5:
						top = mini(top, y)
						bottom = maxi(bottom, y)
			tallest = maxi(tallest, bottom - top + 1)
	return float(tallest)

func _walk_row_height(texture: Texture2D, row: int) -> float:
	var image := texture.get_image()
	if image.is_compressed(): image.decompress()
	var y0 := FufuWornAppearance.WALK_ROW_STARTS[row]
	var y1 := y0 + FufuWornAppearance.WALK_CELL_SIZE.y
	var tallest := 0
	for column in 4:
		var x0 := FufuWornAppearance.WALK_COLUMN_STARTS[column]
		var x1 := x0 + FufuWornAppearance.WALK_CELL_SIZE.x
		var top := y1
		var bottom := -1
		for y in range(y0, y1):
			for x in range(x0, x1):
				if image.get_pixel(x, y).a > 0.5:
					top = mini(top, y)
					bottom = maxi(bottom, y)
		tallest = maxi(tallest, bottom - top + 1)
	return float(tallest)

func _walk_row_has_margin(texture: Texture2D, row: int) -> bool:
	var image := texture.get_image()
	if image.is_compressed(): image.decompress()
	var top := FufuWornAppearance.WALK_ROW_STARTS[row]
	var bottom := top + FufuWornAppearance.WALK_CELL_SIZE.y - 1
	for column in 4:
		var left := FufuWornAppearance.WALK_COLUMN_STARTS[column]
		for x in range(left, left + FufuWornAppearance.WALK_CELL_SIZE.x):
			if image.get_pixel(x, top).a > 0.5 or image.get_pixel(x, bottom).a > 0.5: return false
	return true

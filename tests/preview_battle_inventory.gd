extends SceneTree
## Native bilingual compact/desktop check of actual chest, gear and match stats.
var failures: int = 0
var game: BattleRoyaleGame
const OUTPUT := "res://.codex/visualizations/2026/10/21/battle-balance/inventory/"

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, label: String) -> void:
	if value: return
	failures += 1
	printerr("FAIL: ", label)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	GamePreferences.install_translations(self)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	var room := BattleRoom.new()
	root.add_child(room)
	room.practice()
	room.epoch = "f".repeat(24)
	game = BattleRoyaleGame.new()
	game.room = room
	root.add_child(game)
	while not game.composed: await physics_frame
	BattleTestDeployment.finish(game)
	game.set_physics_process(false)
	game.match_state.time = 14
	var chest: Array = game.match_state.chests[0]
	var nearest := INF
	for row: Array in game.match_state.chests:
		var distance := Vector2(row[1] + 22, row[3] + 22).length_squared()
		if distance < nearest:
			chest = row
			nearest = distance
	var at := Vector3(chest[1], chest[2], chest[3])
	game.bodies[0].position = game.world.ground_point(at.x, at.z + 2.4, 0.08)
	game.bodies[0].visuals.test_skin.select(TofufuTestArt.IDS[0])
	game.camera.reset_follow()
	for frame in 6: await physics_frame
	check(BattleChestLoot.open(game.pack, 0, int(chest[0])), "actual chest can be opened")
	game.pack.field.update()
	for frame in 100: await physics_frame
	var fighter := game.combat.fighters[0]
	for i in 4: fighter.loadout.equipment.set_slot(CharacterEquipment.APPAREL_SLOTS[i], ItemStack.new(BattleItems.make(20 + i), 1))
	fighter.loadout.equipment.set_slot("backpack", ItemStack.new(BattleItems.make(26), 1))
	fighter.loadout.equipment.set_slot("combat_2", ItemStack.new(BattleItems.make(11), 1))
	fighter.loadout.select(2)
	for i in 20: fighter.loadout.inventory.set_slot(i, ItemStack.new(BattleItems.make([1, 3, 4, 6, 8, 7, 5, 11, 12, 16, 24, 25, 27, 28, 29, 30, 31, 32, 13, 17][i]), 1))
	game.pack.refresh(0)
	game.pack.capture(true)
	game.combat.capture()
	for locale in ["en", "pl"]:
		TranslationServer.set_locale(locale)
		for dimensions in [Vector2i(1280, 720), Vector2i(640, 360)]:
			root.size = dimensions
			root.content_scale_size = dimensions
			game._update_hud()
			game.pack_ui.close()
			await _capture("world", locale, dimensions)
			game.pack_ui.show_bag()
			await _capture("backpack", locale, dimensions)
			var weapon_button: InventorySlotButton = game.pack_ui.bag._eq_buttons["combat_2"]
			game.pack_ui.bag._tooltip.inspect(weapon_button, func() -> ItemStack: return weapon_button.current_stack)
			await _capture("legendary-tooltip", locale, dimensions)
			var bag := game.pack_ui.bag
			check(root.get_visible_rect().encloses(bag._backpack_dock.get_global_rect()), "full twenty-slot bag stays inside viewport")
			check(root.get_visible_rect().encloses(bag._equipment_dock.get_global_rect()), "all worn slots stay inside viewport")
			check(not bag._backpack_dock.get_global_rect().intersects(bag._equipment_dock.get_global_rect()), "equipment and bag do not overlap")
			bag._tooltip.clear()
			game.pack_ui.show_loot()
			await _capture("loot", locale, dimensions)
			check(root.get_visible_rect().encloses(game.pack_ui.panel._panel.get_global_rect()), "loot controls fit viewport")
			check(root.get_visible_rect().encloses(game.pack_ui.panel.close_button.get_global_rect()), "loot Close button fits: " + str(game.pack_ui.panel.close_button.get_global_rect()))
			check(root.get_visible_rect().encloses(game.pack_ui.panel.backpack_button.get_global_rect()), "loot Backpack button fits: " + str(game.pack_ui.panel.backpack_button.get_global_rect()))
			game.pack_ui.show_stats()
			await _capture("stats", locale, dimensions)
			check(root.get_visible_rect().encloses(game.pack_ui.panel._panel.get_global_rect()), "scrollable stats fit viewport")
	game.queue_free()
	room.queue_free()
	await process_frame
	await process_frame
	await create_timer(0.25).timeout
	print("Battle inventory native preview: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _capture(page: String, locale: String, dimensions: Vector2i) -> void:
	for frame in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT + "%s-%s-%d.png" % [page, locale, dimensions.x])

extends SceneTree
## Native real-world English/Polish views of integrity, confirmed hurt and whole-kit loot.
const OUTPUT := "res://.codex/visualizations/2026/10/22/battle-survival/"
var game: BattleRoyaleGame
var room: BattleRoom
var failures: int = 0
var inspecting: bool = false
var aim_view: BattleAimView

func _initialize() -> void: _run.call_deferred()

func _shot(name: String) -> void:
	game._update_hud()
	aim_view.reticle.visible = not game.pack_ui.blocked() and not game.hud.radar.expanded
	aim_view.reticle.centered = true
	game.presentation.update(0.3)
	game.pack.field.update(false)
	for frame in 8:
		for body in game.bodies:
			var command := PlayerCommand.new()
			command.aim = Vector2.UP
			body.visuals.present(command, Vector3.ZERO, true, false, 1.0 / 60)
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT + name + ".png")

func _sizes(name: String) -> void:
	for dimensions in [Vector2i(1280, 720), Vector2i(640, 360)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		for locale in ["en", "pl"]:
			TranslationServer.set_locale(locale)
			await _shot("%s-%d-%s" % [name, dimensions.x, locale])
			if inspecting and not game.pack_ui.bag._tooltip._panel.visible:
				failures += 1
				printerr("FAIL: integrity tooltip was not displayed")
			if game.pack_ui.bag.visible and game.pack_ui.bag._tooltip._panel.visible:
				if not root.get_visible_rect().encloses(game.pack_ui.bag._tooltip._panel.get_global_rect()):
					failures += 1
					printerr("FAIL: integrity tooltip leaves viewport")

func _outfit(kinds: Array) -> void:
	for i in 4:
		var stack := ItemStack.new(BattleItems.make(kinds[i]), 1)
		stack.reserve = [80, 56, 24, 70][i]
		game.combat.fighters[0].loadout.equipment.set_slot(CharacterEquipment.APPAREL_SLOTS[i], stack)
	game.pack.refresh(0)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	GamePreferences.install_translations(self)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	room = BattleRoom.new()
	room.options = [3, 1]
	root.add_child(room)
	room.practice()
	game = BattleRoyaleGame.new()
	game.room = room
	root.add_child(game)
	while not game.composed: await physics_frame
	room.set_process(false)
	game.set_physics_process(false)
	BattleTestDeployment.finish(game)
	game.combat.process_mode = Node.PROCESS_MODE_DISABLED
	game.match_state.circle = BattleRing.CENTER
	game.match_state.time = BattleRing.start_of(5) + BattleRing.HOLD + 1
	var at := game.world.ground_point(-22, -14, 0.08)
	for slot in game.bodies.size(): game.bodies[slot].position = at + Vector3(slot * 3, 0, -slot * 2)
	for child in game.get_children():
		if child is BattleAimView:
			aim_view = child
			child.set_process(false)
			child.set_process_unhandled_input(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	game.camera.yaw = 0
	game.camera.pitch = 0.14
	game.camera.reset_follow()
	game.local_input.enabled = true
	_outfit([20, 17, 14, 23])
	game.combat.capture()
	await _sizes("partial-armour")
	game._update_hud()
	game.combat.receive(20, Vector3.ZERO, Damageable.HitKind.SOY, Vector3.ZERO, game.combat.fighters[1].health, 0)
	var commands: Array[PlayerCommand] = [null, null, null, null]
	game.combat.step(commands, 0, 0)
	game._update_hud()
	var flash := game.match_view.tactical.damage_flash
	flash.set_process(false)
	flash.hurt()
	await _sizes("hurt-pulse")
	game.pack_ui.show_bag()
	await _sizes("hurt-inventory")
	game.pack_ui.close()
	flash.hide()
	flash.remaining = 0
	game.pack_ui.show_bag()
	await process_frame
	var button: InventorySlotButton = game.pack_ui.bag._eq_buttons["legs"]
	button.grab_focus()
	inspecting = true
	game.pack_ui.bag._tooltip.inspect(button, func() -> ItemStack: return button.current_stack)
	await _sizes("damaged-tooltip")
	inspecting = false
	game.pack_ui.close()
	_outfit([20, 21, 22, 23])
	await _sizes("complete-set")
	game.pack_ui.show_bag()
	await process_frame
	button = game.pack_ui.bag._eq_buttons["legs"]
	button.grab_focus()
	inspecting = true
	game.pack_ui.bag._tooltip.inspect(button, func() -> ItemStack: return button.current_stack)
	await _sizes("unbreakable-tooltip")
	inspecting = false
	game.pack_ui.close()
	game.bodies[2].position = at + Vector3(0, 0, -1)
	for i in 3: game.match_state.rows[2][i] = game.bodies[2].position[i]
	var victim := game.combat.fighters[2]
	victim.loadout.equipment.set_slot("backpack", ItemStack.new(BattleItems.make(26), 1))
	for i in 20: victim.loadout.inventory.set_slot(i, ItemStack.new(BattleItems.make(12 + i % 12), 1))
	for i in 4: victim.loadout.equipment.set_slot(CharacterEquipment.APPAREL_SLOTS[i], ItemStack.new(BattleItems.make(20 + i), 1))
	game.pack.refresh(2)
	game.match_state.hit(2, 1000, 0)
	game.pack.step(0)
	await _sizes("whole-kit-drop")
	game.pack_ui.show_loot()
	await _sizes("whole-kit-loot")
	inspecting = false
	game.pack_ui.close()
	game.match_state.time = 13
	var candidates := BattleStormLayout.candidates(game)
	var file := FileAccess.open(OUTPUT + "finale-sites.json", FileAccess.WRITE)
	var sites: Array = []
	for point in candidates: sites.append([point.x, point.y, BattleStormLayout.region(point)])
	file.store_string(JSON.stringify({"candidates": sites, "atlas": [1400, 1400]}, "\t"))
	file.close()
	game.match_state.circle = BattleStormLayout.pick(candidates, 8319)
	game.hud.toggle_map()
	await _sizes("expanded-regions")
	game.queue_free()
	room.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	print("Native survival/integrity/loot preview: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

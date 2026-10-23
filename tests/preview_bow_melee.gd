extends SceneTree
## Native Royale shots driven by LocalPlayerInput, plus bilingual base-stat comparisons.
const OUT := "res://.codex/visualizations/2026/10/23/bow-melee"
var game: BattleRoyaleGame
var fighter: BattleFighter
var view: BattleAimView
var failures: int = 0

func _initialize() -> void: _run.call_deferred()

func check(value: bool, label: String) -> void:
	if value: return
	failures += 1
	printerr("FAIL: ", label)

func capture(name: String) -> void:
	game._update_hud()
	for frame in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join(name + ".png"))

func _run() -> void:
	GamePreferences.install_translations(self)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	var room := BattleRoom.new()
	room.options = [1, 1]
	root.add_child(room)
	room.practice()
	game = BattleRoyaleGame.new()
	game.preferences.path = "user://bow-melee-preview-%d.cfg" % Time.get_ticks_usec()
	game.room = room
	root.add_child(game)
	while not game.composed: await physics_frame
	BattleTestDeployment.finish(game)
	game.set_physics_process(false)
	game.match_state.time = 13
	game.local_input.enabled = true
	for child in game.get_children():
		if child is BattleAimView: view = child
	fighter = game.combat.fighters[0]
	var at := _clearing()
	game.bodies[0].position = at
	game.bodies[1].position = game.world.ground_point(at.x, at.z + 22, 0.08)
	for slot in game.bodies.size():
		for axis in 3: game.match_state.rows[slot][axis] = game.bodies[slot].position[axis]
	var row: Array = game.match_state.rows[0]
	row[23] = 8
	row[10] = 8
	row[18] = 2
	fighter.equip(row)
	game.camera.yaw = PI
	game.camera.pitch = 0.08
	game.camera.reset_follow()
	game._update_hud()
	for frame in 20: await process_frame
	await _shots()
	await _stats()
	Input.action_release("guard")
	Input.action_release("attack")
	game.queue_free()
	room.queue_free()
	await process_frame
	print("Native bow and melee: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _clearing() -> Vector3:
	for z in range(-80, -10, 6):
		for x in range(-80, -10, 6):
			var at := game.world.ground_point(x, z, 0.08)
			var end := game.world.ground_point(x, z + 26, 0.08)
			if absf(at.y - end.y) > 1: continue
			var nearby := false
			for chest: Array in game.match_state.chests:
				if Vector2(at.x - float(chest[1]), at.z - float(chest[3])).length_squared() < 144: nearby = true
			if nearby: continue
			var ray := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.65, end + Vector3.UP * 0.65, 1)
			if game.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): return at
	return game.world.ground_point(-22, -22, 0.08)

func _step(command: PlayerCommand) -> void:
	fighter.step(command, 1.0 / 60)
	fighter.actor.visuals.present(command, Vector3.ZERO, true, false, 1.0 / 60)

func _shots() -> void:
	Input.action_press("attack")
	await process_frame
	var command := game.local_input.sample(fighter.actor.position)
	check(command.attack_held, "real native input permits bow LMB")
	_step(command)
	Input.action_release("attack")
	for tick in 4: await physics_frame
	for child in fighter.combat.bow.get_children():
		if child is AngelArrow:
			child.set_physics_process(false)
			child.flight.advance(child.global_position)
	await capture("01-normal-flight")
	await _overhead("01b-normal-overhead")
	fighter.clear_flights()
	fighter.combat.bow.reload_remaining = 0
	Input.action_press("guard")
	await process_frame
	for tick in 45:
		command = game.local_input.sample(fighter.actor.position)
		_step(command)
		await physics_frame
	check(fighter.combat.bow.charge > 0.6, "real native RMB continuously charges the selected bow")
	for locale in ["en", "pl"]:
		TranslationServer.set_locale(locale)
		game._update_hud()
		await capture("02-charge-" + locale)
	root.size = Vector2i(640, 360)
	root.content_scale_size = root.size
	for locale in ["en", "pl"]:
		TranslationServer.set_locale(locale)
		await capture("02-charge-640-" + locale)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	for tick in 31:
		_step(game.local_input.sample(fighter.actor.position))
		await physics_frame
	check(fighter.combat.bow.sequence == 2 and fighter.combat.bow.empowered, "native held RMB launches exactly one flame arrow")
	Input.action_release("guard")
	for child in fighter.combat.bow.get_children():
		if child is AngelArrow:
			child.set_physics_process(false)
			child.flight.advance(child.global_position)
	await capture("03-flame-flight")
	await _overhead("03b-flame-overhead")
	fighter.clear_flights()

	var bow := fighter.combat.bow
	bow.reload_remaining = 0
	bow.cooldown = 0
	bow.step(false, false, Vector2.DOWN, Vector3.ZERO, 0.016)
	var point := fighter.actor.position + Vector3(0, -0.08, 7)
	bow.step(false, true, Vector2.DOWN, point, AngelBow.CHARGE)
	var burst := bow.burst_sequence
	for tick in 15:
		await physics_frame
		if bow.burst_sequence > burst: break
	check(bow.burst_sequence == burst + 1, "a real terrain impact produces the charged flame sphere")
	await capture("04-terrain-flame-impact")
	fighter.clear_flights()

func _overhead(name: String) -> void:
	var event := InputEventAction.new()
	event.action = "camera_mode"
	event.pressed = true
	view._unhandled_input(event)
	check(not game.camera.shoulder, "C switches to overhead with an arrow in flight")
	for frame in 25: await process_frame
	await capture(name)
	view._unhandled_input(event)
	for frame in 25: await process_frame

func _stats() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", MenuStyle.panel(Color("13241f")))
	game.hud.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]: margin.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(margin)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 14)
	margin.add_child(grid)
	for locale in ["en", "pl"]:
		TranslationServer.set_locale(locale)
		for child in grid.get_children(): child.free()
		for kind in [1, 3, 4, 5, 6, 9, 10, 8]:
			var row := HBoxContainer.new()
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			grid.add_child(row)
			var icon := TextureRect.new()
			icon.texture = BattleItems.make(kind).icon
			icon.custom_minimum_size = Vector2(64, 64)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			row.add_child(icon)
			var text := Label.new()
			text.text = BattleBalance.title(kind) + "\n" + BattleWeaponRoles.text(BattleBalance.ITEMS[kind])
			text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			text.add_theme_font_size_override("font_size", 16)
			row.add_child(text)
		await capture("05-weapon-roles-" + locale)
	panel.free()

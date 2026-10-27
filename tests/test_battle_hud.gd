extends SceneTree
## Actual Royale composition: camera-relative controls, modal guards and visible storm.
var failures: int = 0
var game: BattleRoyaleGame
var view: BattleAimView

func _initialize() -> void: _run.call_deferred()
func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: ", label)

func _run() -> void:
	_rim_budget()
	GamePreferences.install_translations(self)
	var room := BattleRoom.new()
	root.add_child(room)
	room.options = [1, 1]
	room.practice()
	game = BattleRoyaleGame.new()
	game.preferences.path = "user://battle-hud-%d.cfg" % Time.get_ticks_usec()
	game.room = room
	root.add_child(game)
	while not game.composed: await physics_frame
	BattleTestDeployment.finish(game)
	game.set_physics_process(false)
	game.combat.process_mode = Node.PROCESS_MODE_DISABLED
	game.local_input.enabled = true
	for child in game.get_children():
		if child is BattleAimView: view = child
	_camera()
	_loadout()
	_storm()
	await _layout()
	game.queue_free()
	room.queue_free()
	await process_frame
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "leaving the match restores the mouse")
	await create_timer(0.2).timeout
	print("Battle HUD/camera/storm: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _key(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	view._unhandled_input(event)

func _camera() -> void:
	check(game.camera.shoulder and game.local_input.shoulder_view and not game.camera.first_person, "Royale starts behind Tofufu with centred aiming")
	_key("camera_direction")
	check(game.camera.shoulder_side == -1, "middle click swaps shoulders")
	_key("camera_mode")
	check(not game.camera.shoulder and not game.local_input.shoulder_view, "C enters overhead")
	for i in 4:
		_key("camera_direction")
		game.camera._follow(10)
		Input.action_press("move_up")
		var command := game.local_input.sample(game.bodies[0].position)
		Input.action_release("move_up")
		var expected: Vector2 = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP][i]
		check(command.move.distance_to(expected) < 0.001, "movement follows rotated screen-up")
	_key("camera_mode")
	check(game.camera.shoulder and not game.camera.first_person and not game.local_input.first_person_view, "C returns behind without entering first person")
	game.hud.exit_panel.show()
	game._update_hud()
	check(not game.match_view.tactical.visible, "Help hides objective medallions and combat markers")
	_key("camera_mode")
	view._process(0)
	check(game.camera.shoulder and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Help blocks camera switches and releases cursor")
	game.hud.exit_panel.hide()
	game.pack_ui.show_bag()
	_key("camera_direction")
	check(game.camera.shoulder_side == -1 and not view.available(), "bag blocks direction switches")
	game.pack_ui.close()
	var stage: int = game.match_state.deployment.stage
	game.match_state.deployment.stage = 0
	check(not view.available(), "plant selection releases camera input")
	game.match_state.deployment.stage = stage
	game.room.phase = "recovering"
	_key("camera_mode")
	check(game.camera.shoulder and not view.available(), "recovery blocks camera changes")
	game.room.phase = "playing"

func _loadout() -> void:
	var fighter := game.combat.fighters[0]
	fighter.loadout.equipment.set_slot("combat_2", ItemStack.new(BattleItems.make(8), 1))
	fighter.loadout.select(2)
	game.pack.refresh(0)
	fighter.combat.bow.reload_remaining = 1
	var values := BattleHUDValues.loadout(game)
	check(values.ammo == 0 and values.magazine_capacity == 1 and values.reload > 0, "bow HUD shows its one reloading arrow instead of the hidden gun magazine")
	fighter.combat.bow.reload_remaining = 0
	check(BattleHUDValues.loadout(game).ammo == 1, "ready bow shows one usable arrow")
	fighter.loadout.equipment.set_slot("combat_2", ItemStack.new(BattleItems.make(2), 1))
	game.pack.refresh(0)

func _storm() -> void:
	var storm := game.presentation.storm
	game.match_state.time = BattleRing.start_of(5) + BattleRing.HOLD + 1
	game.match_state.circle = BattleRing.CENTER
	var radius := BattleRing.radius(game.match_state.time)
	var center := BattleRing.center(game.match_state.time, game.match_state.circle)
	game.bodies[0].position = game.world.ground_point(center.x, center.y)
	storm.present(0.3)
	check(storm.wall.visible and is_equal_approx(storm.wall.scale.x, radius), "wall exactly follows accepted damage radius")
	check(not storm.edge.visible, "safe centre keeps view clear")
	game.bodies[0].position = game.world.ground_point(center.x + radius + 1, center.y)
	storm.present(0)
	check(storm.edge.visible, "outside storm adds local danger mist")
	var phase: float = storm.wall_material.get_shader_parameter("phase")
	var pending := storm._terrain_rim._next
	game.room.phase = "recovering"
	storm.present(0)
	check(is_equal_approx(phase, storm.edge_material.get_shader_parameter("phase")), "recovery freezes every storm effect on the same clock")
	check(storm._terrain_rim._next == pending, "recovery also freezes pending terrain outline work")
	game.room.phase = "playing"
	game.match_state.time = BattleRing.total_time() + 8
	storm.present(0.3)
	check(not storm.wall.visible and storm.edge.visible, "fully closed circle stays dangerous without a degenerate wall")
	game.match_state.time = BattleRing.start_of(5) + BattleRing.HOLD + 1
	game._update_hud()
	check(game.hud.zone.values.unsafe and game.hud.zone.values.zone_distance > 0, "unsafe HUD supplies an escape direction and distance")

func _rim_budget() -> void:
	var outline := BattleStormRim.new()
	var queries: Array[int] = [0]
	outline.material = StandardMaterial3D.new()
	outline.ground_point = func(x: float, z: float, lift: float) -> Vector3:
		queries[0] += 1
		return Vector3(x, x * 0.1 + z * 0.2 + lift, z)
	check(outline.request(Vector2(20, -30), 100), "first terrain rim requests a build")
	for tick in 13:
		var before := queries[0]
		outline.step()
		check(queries[0] - before <= 48, "each outline tick performs at most 48 terrain queries")
		if tick < 12: check(outline.mesh.get_surface_count() == 0, "incomplete terrain profiles never become a torn visible ring")
	check(queries[0] == 579 and outline.mesh.get_surface_count() == 1, "full rim retains all 192 segments and three terrain bands")
	var vertices: PackedVector3Array = outline.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	check(vertices.size() == 2304, "rim preserves every original triangle")
	for at in vertices:
		check(is_equal_approx(at.y, (at.x + 20) * 0.1 + (at.z - 30) * 0.2 + 0.14), "completed rim follows the authored terrain query at every vertex")
	check(not outline.request(Vector2(20, -30), 100), "stationary circles reuse their completed outline")
	outline.step()
	check(queries[0] == 579, "stationary circles perform no repeated terrain sampling")
	outline.request(Vector2(25, -30), 99)
	outline.step()
	check(outline.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] == vertices, "moving circles retain their old complete rim while new samples accumulate")

func _layout() -> void:
	for dimensions in [Vector2i(1280, 720), Vector2i(640, 360)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		for locale in ["en", "pl"]:
			TranslationServer.set_locale(locale)
			game._update_hud()
			for frame in 3: await process_frame
			for control: Control in [game.hud.vitals, game.hud.loadout, game.hud.zone, game.hud.radar, game.hud._header]:
				check(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(control.get_global_rect()), "compact HUD stays inside viewport")
			check(not game.hud.vitals.get_global_rect().intersects(game.hud.loadout.get_global_rect()), "loadout and resources never overlap")
			check(not game.hud.zone.get_global_rect().intersects(game.hud.radar.get_global_rect()), "storm status leaves minimap clear")
			check(not game.hud.controls_hint.is_visible_in_tree(), "controls stay in optional Help")
			check(game.hud.loadout.values.weapon_icons.size() == 2, "real equipped weapon art reaches the HUD")
	check(tr("STORM") == "BURZA" and game.hud.controls_hint.text.contains("kamera"), "storm and Help update live in Polish")

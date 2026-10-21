extends SceneTree
## Actual display interaction, cosmetic-only selection, eight facings and pose priority.

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if ok: return
	failures += 1
	printerr("FAIL: ", message)

func _run() -> void:
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	await physics_frame
	await process_frame
	var flow := game.skin_test
	var sprite := game.player.visuals
	check(flow.display != null and flow.window.buttons.is_empty(), "optional chooser defers loading skin artwork until interaction")
	game.player.relocate(flow.display.global_position + Vector3(0, 0.1, 2))
	game.camera.reset_follow()
	await physics_frame
	await process_frame
	var source := game.shooting_view.local_input
	WorldInteractionFocus.select_focus(game.world_items, source, game.camera.unproject_position(flow.focus_position()))
	check(game.world_items.focused_kind == "skin_test", "display participates in shared mouse/controller focus")
	var event := InputEventAction.new()
	event.action = "pickup_weapon"
	event.pressed = true
	flow._unhandled_input(event)
	check(flow.window.visible and not source.enabled, "normal interact opens modal and blocks gameplay input")
	check(flow.window.buttons.size() == 8, "real meadow study offers Fufu plus all seven skins")
	check(game.chat._menu_open, "opening chooser blocks chat capture")
	var collider: Shape3D = game.player.get_node("CollisionShape3D").shape
	var maximum := game.health.maximum
	var equipment := game.character_equipment.get_slot("combat_1")
	var body := game.player.collision_layer
	for id: String in TofufuTestArt.IDS:
		if not flow.window.visible: flow.open()
		(flow.window.buttons[id] as Button).pressed.emit()
		check(sprite.test_skin.selected == id and not flow.window.visible and source.enabled, "button applies " + id + " and returns movement")
		check(not game.chat._menu_open, "selection restores chat availability")
		_check_frames(sprite, id)
		var command := PlayerCommand.new()
		command.aim = Vector2.DOWN
		for strike in 4:
			sprite.jump_animation.reset()
			game.combat.equipment.step(Vector2.DOWN, false, true, false, false, 0, 1.0, -1, true)
			sprite.present(command, Vector3.ZERO, true, false, 0)
			check(sprite._using_unarmed_frame and sprite.test_skin.kind == "melee", "actual fist combat drives selected skin contacts")
			var effect := game.combat.equipment.get_child(-1) as PunchImpact
			check(effect != null and not effect.visible, "test body contacts do not show Fufu's separate limb cutouts")
		check(game.player.get_node("CollisionShape3D").shape == collider and game.player.collision_layer == body, "skin preserves collision capsule")
		check(game.health.maximum == maximum and game.character_equipment.get_slot("combat_1") == equipment, "skin preserves stats and actual equipment")
	check(not sprite.set_test_skin("not-a-skin") and sprite.test_skin.selected == "burnt_tofufu", "unknown IDs cannot replace a valid test skin")
	_check_priority(sprite)
	game.player.visuals.set_worn_set("", false)
	game.player.relocate(flow.display.global_position + Vector3(0, 0.1, 2))
	flow.open()
	var cancel := InputEventAction.new()
	cancel.action = "ui_cancel"
	cancel.pressed = true
	flow._input(cancel)
	check(not flow.window.visible and source.enabled, "Escape closes selector and restores input")
	flow.open()
	game.player.relocate(Vector3(0, 0.1, 0))
	flow._process(0)
	check(not flow.window.visible and source.enabled, "leaving range safely closes the modal")
	flow.open()
	check(not flow.window.visible, "display cannot be opened remotely")
	for locale in ["en", "pl"]:
		TranslationServer.set_locale(locale)
		for size in [Vector2i(1280, 720), Vector2i(640, 360)]:
			root.content_scale_size = size
			root.size = size
			game.player.relocate(flow.display.global_position + Vector3(0, 0.1, 2))
			flow.open()
			for frame in 3: await process_frame
			check(flow.window._column.get_global_rect().position.y >= 0 and flow.window._column.get_global_rect().end.y <= size.y, "chooser fits " + str(size) + " in " + locale)
			(flow.window.buttons["burnt_tofufu"] as Button).grab_focus()
			for frame in 3: await process_frame
			check(flow.window._scroll.get_global_rect().intersects((flow.window.buttons["burnt_tofufu"] as Button).get_global_rect()), "controller focus scrolls the final skin into view")
			flow.window.close()
	game.queue_free()
	await process_frame
	TranslationServer.set_locale("en")
	print("Meadow skin test: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _check_frames(sprite: FufuVisuals, id: String) -> void:
	for facing in 8:
		sprite.current_facing = facing as FufuVisuals.Facing
		for category in ["locomotion", "jump", "melee"]:
			var columns := 5 if category == "locomotion" else (10 if category == "jump" else 4)
			for column in columns:
				sprite.test_skin.apply(sprite, category, column)
				var atlas := sprite.texture as AtlasTexture
				check(atlas != null and atlas.atlas.resource_path.contains(id), "all poses use the chosen character")
				check(sprite.flip_h == (facing in [0, 1, 7]), "right facings mirror the correct authored angles")
				check(sprite.hframes == 1 and sprite.vframes == 1 and sprite.frame == 0 and atlas.filter_clip, "tight atlas region prevents neighboring sprite bleed")
				check(sprite.test_skin.hand.x >= 0 and sprite.test_skin.hand.x <= atlas.region.size.x and sprite.test_skin.hand.y <= atlas.region.size.y, "wrist stays inside the selected region")
				var data: Dictionary = sprite.test_skin._layout.sheets[category][TofufuTestArt.ROWS[facing] * columns + column]
				var feet := (atlas.region.size.y * 0.5 - float(data.feet) + sprite.offset.y) * sprite.pixel_size
				check(is_equal_approx(feet, -0.56), "walk, jump and contacts retain the planted foot pivot")

func _check_priority(sprite: FufuVisuals) -> void:
	var command := PlayerCommand.new()
	command.aim = Vector2.DOWN
	sprite.set_worn_set("celestial", false)
	check(sprite.set_test_skin("silken_tofufu"), "test skin can override equipped outfit appearance")
	sprite.present(command, Vector3.ZERO, true, false, 0)
	check((sprite.texture as AtlasTexture).atlas.resource_path.contains("silken_tofufu"), "celestial outfit never replaces test idle")
	check(not sprite.celestial_aura.visible, "outfit aura does not obscure the test art")
	sprite.show_jump()
	sprite.present(command, Vector3.UP * 4, false, false, 0.05)
	check(sprite.test_skin.kind == "jump", "real jump state selects the skin's jump phases")
	sprite.jump_animation.reset()
	sprite.present(command, Vector3.ZERO, true, false, 0, 0.5)
	check(sprite.test_skin.kind == "jump" and sprite.test_skin.phase == 0, "jump charging uses matching takeoff instead of Fufu art")
	for style in 4:
		sprite.unarmed_pose = func() -> Dictionary: return {"style": style, "elapsed": 0.04, "duration": 0.16, "aim": Vector2.DOWN}
		sprite.present(command, Vector3.ZERO, true, false, 0)
		check(sprite._using_unarmed_frame and sprite.test_skin.kind == "melee" and sprite.test_skin.phase == style, "real strike context selects matching skin contact")
		sprite.present(command, Vector3.ZERO, false, false, 0)
		check(not sprite._using_unarmed_frame, "airborne contacts keep jump presentation priority")
		sprite.jump_animation.reset()
	sprite.unarmed_pose = Callable()
	sprite.set_test_skin("")
	check(sprite.worn_set == "celestial" and (sprite.texture as AtlasTexture).atlas.resource_path.contains("celestial"), "return to Fufu restores actual outfit appearance")

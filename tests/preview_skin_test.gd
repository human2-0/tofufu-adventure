extends SceneTree
## Native village display interaction, bilingual chooser and real player atlas poses.

const OUT := "user://skin-test-preview/"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	await physics_frame
	var flow := game.skin_test
	game.player.relocate(flow.display.global_position + Vector3(0, 0.1, 2))
	game.camera.reset_follow()
	for frame in 10: await physics_frame
	game.world_items.set_process(false)
	game.world_items.focused_kind = "skin_test"
	await _capture("display-interaction")
	for locale in ["en", "pl"]:
		TranslationServer.set_locale(locale)
		for dimensions in [Vector2i(1280, 720), Vector2i(640, 360)]:
			root.content_scale_size = dimensions
			root.size = dimensions
			flow.open()
			await _capture(locale + "-" + str(dimensions.x))
			(flow.window.buttons["burnt_tofufu"] as Button).grab_focus()
			await _capture(locale + "-" + str(dimensions.x) + "-last-choice")
			flow.window.close()
	TranslationServer.set_locale("en")
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	game.player.set_physics_process(false)
	flow.set_process(false)
	flow.prompt.hide()
	game.camera.set_process(false)
	game.camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	game.camera.size = 5.0
	game.camera.global_position = game.player.global_position + Vector3(-3, 5, -7)
	game.camera.look_at(game.player.global_position + Vector3.UP * 0.65)
	for id: String in TofufuTestArt.IDS:
		flow.open()
		(flow.window.buttons[id] as Button).pressed.emit()
		game.player.visuals.current_facing = FufuVisuals.Facing.DOWN_LEFT
		game.player.visuals._set_frame(false)
		await _capture(id)
		game.player.visuals.test_skin.apply(game.player.visuals, "jump", 3)
		await _capture(id + "-jump")
		game.player.visuals.test_skin.apply(game.player.visuals, "melee", 2)
		await _capture(id + "-uppercut")
	print("Skin test previews: ", ProjectSettings.globalize_path(OUT))
	quit()

func _capture(label: String) -> void:
	for frame in 5: await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	assert(root.get_texture().get_image().save_png(OUT + label + ".png") == OK)

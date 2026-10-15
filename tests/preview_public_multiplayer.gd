extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var app: Node = load("res://game/app/bootstrap/launch.tscn").instantiate()
	app.preferences.path = "user://public-preview.cfg"
	app.public_play.profile.path = "user://public-preview-character.json"
	root.add_child(app)
	await _capture("home")
	await app.public_play.show_public()
	await _capture("create")
	app.public_play.panel.name_field.text = "MisoBean"
	app.public_play.panel.show_status("That character name is already taken. Choose another.")
	await _capture("taken")
	root.content_scale_size = Vector2i(640, 360)
	root.size = Vector2i(640, 360)
	await _capture("compact")
	app.public_play._back()
	await _capture("home-compact")
	app.queue_free()
	await process_frame
	quit()

func _capture(label: String) -> void:
	for frame in 10: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-public-" + label + ".png")

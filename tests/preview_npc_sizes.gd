extends SceneTree
## Actual royal/resident art beside the unchanged playable Fufu silhouette.
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(1440, 720)
	var stage := Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("536e72")
	stage.add_child(env)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12
	camera.position = Vector3(0, 4, 18)
	stage.add_child(camera)
	camera.look_at(Vector3(0, 1.8, 0))
	var player: Player = load("res://game/player/player.tscn").instantiate()
	player.position.x = -4.6
	stage.add_child(player)
	player.set_physics_process(false)
	var king := LavaKing.new()
	king.position.x = -1.6
	stage.add_child(king)
	var god := Godfufu.new()
	god.position.x = 1.6
	stage.add_child(god)
	var goddess := CloudResident.new()
	goddess.role = "goddess"
	goddess.art_key = "goddess"
	goddess.art_height = 2.55
	goddess.position.x = 4.6
	stage.add_child(goddess)
	goddess.greeting.hide()
	for label in goddess.get_children():
		if label is Label3D: label.hide()
	for i in 4:
		var label := Label3D.new()
		label.text = ["FUFU", "TOFUFU KING", "GODFUFU", "GODDESS TOFUFU"][i]
		label.position = Vector3(-4.6 + i * 3.07, -0.45, 0)
		label.font_size = 27
		label.pixel_size = 0.011
		stage.add_child(label)
	for frame in 10: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-npc-sizes.png")
	stage.queue_free()
	await process_frame
	quit()

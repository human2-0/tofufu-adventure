extends SceneTree
## Renderer QA for all eight sprite/sword directions at the gameplay camera tilt.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("253a38")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.8
	stage.add_child(environment)
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.position = Vector3(0, 8.5, 8)
	camera.look_at(Vector3(0, 0.5, 0))
	camera.fov = 48
	var actors: Array[Player] = []
	var visuals: Array[SwordVisual] = []
	var names: Array[String] = ["E", "NE", "N", "NW", "W", "SW", "S", "SE"]
	for index in 8:
		var actor: Player = load("res://game/player/player.tscn").instantiate()
		actor.position = Vector3((index % 4 - 1.5) * 2.4, 0, (index / 4 - 0.5) * 3.5)
		stage.add_child(actor)
		actor.set_physics_process(false)
		actors.append(actor)
		var sword := SwordVisual.new()
		sword.tuning = CombatTuning.new()
		sword.debug_visible = true
		stage.add_child(sword)
		actor.visuals.hand_presented.connect(sword.follow_hand)
		visuals.append(sword)
		var label := Label3D.new()
		label.text = names[index]
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 36
		label.pixel_size = 0.014
		stage.add_child(label)
		label.position = actor.position + Vector3(0, 0.1, 1.5)
	for tick in 45:
		for index in 8:
			var aim := Vector2.from_angle(-index * PI / 4)
			var command := PlayerCommand.new()
			command.move = Vector2.ZERO
			command.aim = aim
			actors[index].visuals.present(command, Vector3.ONE, true, false, 1.0 / 60.0)
			visuals[index].present(SwordGeometry.pose(actors[index].position, aim, -1, visuals[index].tuning), aim, 0, false, 1.0)
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-eight-directions.png")
	for index in 8:
		var aim := Vector2.from_angle(-index * PI / 4)
		visuals[index].present(SwordGeometry.pose(actors[index].position, aim, 0.5, visuals[index].tuning, true), aim, 1, true)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-sword-hitboxes.png")
	for frame in 4:
		for index in 8:
			var aim := Vector2.from_angle(-index * PI / 4)
			var command := PlayerCommand.new()
			command.move = aim
			command.aim = aim
			actors[index].visuals.anim_timer = frame
			actors[index].visuals.present(command, Vector3.ONE, true, false, 0.0)
			visuals[index].present(SwordGeometry.pose(actors[index].position, aim, -1, visuals[index].tuning), aim, 0, false, 1.0)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/tofufu-walking-grips-%d.png" % frame)
	print("Sword renderer QA: /tmp/tofufu-eight-directions.png and /tmp/tofufu-sword-hitboxes.png")
	stage.queue_free()
	await process_frame
	quit()

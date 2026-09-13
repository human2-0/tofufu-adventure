extends SceneTree
## Six moving charge frames and stationary mouse-facing poses, with hand grips.

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
	for phase in range(-1, 6):
		for index in 8:
			var aim := Vector2.from_angle(-index * PI / 4)
			var command := PlayerCommand.new()
			command.move = aim if phase >= 0 else Vector2.ZERO
			command.aim = aim
			actors[index].visuals.anim_timer = maxf(0, phase)
			actors[index].visuals.present(command, Vector3.ONE if phase >= 0 else Vector3.ZERO, true, false, 0.0, 1.0)
			visuals[index].present(SwordGeometry.pose(actors[index].position, aim, -1, visuals[index].tuning), aim, 0, false, 1.0)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/tofufu-charge-walk-%s.png" % (str(phase) if phase >= 0 else "idle"))
	print("Charge walking renderer QA: /tmp/tofufu-charge-walk-{idle,0..5}.png")
	stage.queue_free()
	await process_frame
	quit()

extends SceneTree
## Size and pose comparison for the imported staff and knife.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("Staff preview requires a rendered Godot window.")
		quit()
		return
	root.size = Vector2i(1280, 720)
	var stage := Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("253a38")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 1.0
	stage.add_child(environment)
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.position = Vector3(0, 3.5, 5)
	camera.look_at(Vector3(0, 0.55, 0))
	camera.fov = 48
	var tuning := CombatTuning.new()
	var staff_visual: StaffVisual
	var staff_pose := Transform3D.IDENTITY
	for index in 2:
		var actor: Player = load("res://game/player/player.tscn").instantiate()
		actor.position = Vector3(-1.4 if index == 0 else 1.4, 0, 0)
		stage.add_child(actor)
		actor.set_physics_process(false)
		var command := PlayerCommand.new()
		command.aim = Vector2.DOWN
		actor.visuals.present(command, Vector3.ZERO, true, false, 0.0)
		var pose := SwordGeometry.pose(actor.global_position, command.aim, -1.0, tuning)
		if index == 0:
			var sword := SwordVisual.new()
			sword.tuning = tuning
			stage.add_child(sword)
			sword.present(pose, command.aim, 0.0, false, 1.0)
		else:
			var staff := StaffVisual.new()
			stage.add_child(staff)
			staff.present(pose)
			staff_visual = staff
			staff_pose = pose
		var label := Label3D.new()
		label.text = "KNIFE · L2 P10" if index == 0 else "STAFF · L1 P5"
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.pixel_size = 0.007
		label.font_size = 28
		label.position = actor.position + Vector3(0, 1.6, 0)
		stage.add_child(label)
	for tick in 5:
		await process_frame
	var image := root.get_texture().get_image()
	if image != null and not image.is_empty():
		image.save_png("/tmp/tofufu-staff-size.png")
	staff_visual.present(staff_pose, 1.0)
	for tick in 3: await process_frame
	root.get_texture().get_image().save_png("/tmp/tofufu-staff-loaded.png")
	staff_visual.present(StaffAttack.pose(StaffAttack.TORNADO, Vector3(1.4, 0, 0), Vector2.DOWN, 0.5, tuning), 0.0, true)
	for tick in 3: await process_frame
	root.get_texture().get_image().save_png("/tmp/tofufu-staff-tornado.png")
	print("Staff visual QA: /tmp/tofufu-staff-size.png, /tmp/tofufu-staff-loaded.png, /tmp/tofufu-staff-tornado.png")
	stage.queue_free()
	await process_frame
	quit()

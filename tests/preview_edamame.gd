extends SceneTree
## Rendered comparison of the supplied pod sword and knife.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("Edamame preview requires a rendered Godot window.")
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
			var sword := SwordVisual.new()
			sword.tuning = tuning
			stage.add_child(sword)
			sword.set_pod(true)
			sword.present(pose, command.aim, 0.0, false, 1.0)
		var label := Label3D.new()
		label.text = "KNIFE · L2 P10" if index == 0 else "EDAMAME · Lv5 · Power12"
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.pixel_size = 0.007
		label.font_size = 28
		label.position = actor.position + Vector3(0, 1.6, 0)
		stage.add_child(label)
	for tick in 5:
		await process_frame
	var image := root.get_texture().get_image()
	if image != null and not image.is_empty():
		image.save_png("/tmp/tofufu-edamame.png")
	var burst_actor := Node3D.new()
	stage.add_child(burst_actor)
	burst_actor.position = Vector3(1.4, 0, 0)
	var combat := PlayerCombat.new()
	combat.actor = burst_actor
	stage.add_child(combat)
	combat.sword.visible = false
	combat.staff.visible = false
	Podburst.visual(combat, Vector2.DOWN)
	await create_timer(0.12).timeout
	await process_frame
	root.get_texture().get_image().save_png("/tmp/tofufu-podburst.png")
	stage.queue_free()
	await process_frame
	quit()

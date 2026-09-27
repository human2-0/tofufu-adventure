extends SceneTree
## Rendered real Fufu grip, long blade and plunge VFX QA.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var stage := Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("344e4b")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 1.0
	stage.add_child(environment)
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.position = Vector3(0, 5.5, 7)
	camera.look_at(Vector3(0, 0.6, 0))
	camera.fov = 48
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(30, 30)
	ground.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("344e4b")
	ground.material_override = material
	stage.add_child(ground)
	var floor_body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(30, 1, 30)
	collision.shape = box
	floor_body.add_child(collision)
	stage.add_child(floor_body)
	floor_body.position.y = -0.5
	var actors: Array[Player] = []
	var combats: Array[PlayerCombat] = []
	for index in 3:
		var actor: Player = load("res://game/player/player.tscn").instantiate()
		actor.position = Vector3((index - 1) * 2.7, 0, 0)
		stage.add_child(actor)
		actor.set_physics_process(false)
		var combat := PlayerCombat.new()
		combat.actor = actor
		stage.add_child(combat)
		combat.staff.visible = false
		combat.sword.set_nori(index == 2)
		combat.sword.set_pod(index == 1)
		actor.visuals.hand_presented.connect(combat.sword.follow_hand)
		var command := PlayerCommand.new()
		command.aim = Vector2.DOWN
		if index == 2: actor.visuals.set_worn_set("dark_leaf", false)
		actor.visuals.present(command, Vector3.ZERO, true, false, 0.0)
		combat.sword.present(SwordGeometry.pose(actor.position, command.aim, -1, combat.tuning), command.aim, 0, false, 1)
		actors.append(actor)
		combats.append(combat)
		var label := Label3D.new()
		label.text = ["KNIFE / POWER 10", "POD SWORD / POWER 12", "NORI / POWER 10 / +10% SPEED"][index]
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.pixel_size = 0.004
		label.font_size = 28
		label.position = actor.position + Vector3(0, 2.0, 0)
		stage.add_child(label)
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-nori-comparison.png")
	actors[0].visible = false
	actors[1].visible = false
	combats[0].sword.visible = false
	combats[1].sword.visible = false
	actors[2].position = Vector3.ZERO
	combats[2].sword.present(NoriPlunge.pose(Vector3.ZERO), Vector2.DOWN, 0, true, 0)
	NoriPlungeVFX.impact(stage, Vector3.ZERO, 2.6)
	await create_timer(0.16).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-nori-impact.png")
	var actor := actors[2]
	var combat := combats[2]
	combat.equipment.nori_selected = true
	actor.velocity = Vector3.DOWN
	actor.move_and_slide()
	combat.plunge.start(combat, Vector2.DOWN)
	var command := PlayerCommand.new()
	command.aim = Vector2.DOWN
	camera.position = Vector3(0, 7.5, 11)
	camera.look_at(Vector3(0, 2.4, 0))
	for tick in 95:
		await physics_frame
		actor.velocity = combat.plunge.velocity(Vector3(0.8, 0, 0), actor.is_on_floor(), 1.0 / 60)
		actor.move_and_slide()
		combat.step(Vector2.DOWN, false, 1.0 / 60, Vector2.ZERO, not actor.is_on_floor(), tick < 45)
		actor.visuals.present(command, actor.velocity, actor.is_on_floor(), false, 1.0 / 60)
		if tick == 30:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/tofufu-nori-airborne.png")
	stage.queue_free()
	await process_frame
	quit()

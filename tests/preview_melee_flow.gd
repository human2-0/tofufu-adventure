extends SceneTree
## Native Godot trajectory sheet and a real-time enemy launch sequence.

var stage: Node3D
var camera: Camera3D

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1440, 1000)
	stage = Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("263c47")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.85
	stage.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -20, 0)
	stage.add_child(sun)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 17.5
	camera.position = Vector3(0, 20, 20)
	stage.add_child(camera)
	camera.look_at(Vector3.ZERO)
	var styles := [KnifeAttack.Style.SLASH, KnifeAttack.Style.REVERSE_SLASH, KnifeAttack.Style.STAB, KnifeAttack.Style.LAUNCHER]
	var names := ["1 / Descending cut", "2 / Reverse cut", "3 / Thrust", "4 / Rising launcher"]
	var phases := [0.14, 0.34, 0.50, 0.66, 0.84]
	for row in 4:
		for column in 5:
			var actor := Node3D.new()
			actor.position = camera.global_basis.x * ((column - 2) * 3.2) + camera.global_basis.y * ((1.5 - row) * 3.0)
			stage.add_child(actor)
			var sprite := FufuVisuals.new()
			sprite.position.y = 0.56
			actor.add_child(sprite)
			var combat := PlayerCombat.new()
			combat.actor = actor
			stage.add_child(combat)
			combat.set_process(false)
			combat.gun.visual.visible = false
			combat.sotjet.visual.visible = false
			ActorWeaponHands.connect_visuals(sprite, combat)
			combat.equipment.nori_selected = true
			combat.sword.set_nori(true)
			combat.active = true
			combat.attack_style = styles[row]
			combat.attack_aim = Vector2.DOWN
			combat._elapsed = phases[column] * combat._attack_duration()
			var command := PlayerCommand.new()
			command.aim = Vector2.DOWN
			sprite.attack_facing = command.aim
			sprite.present(command, Vector3.ZERO, true, false, 0.0)
			MeleePose.present(combat, command.aim, phases[column], row == 3)
			var label := Label3D.new()
			label.text = "%s\n%s" % [names[row], ["Wind-up", "Cut begins", "Contact", "Follow-through", "Recovery"][column]]
			label.font_size = 24
			label.pixel_size = 0.007
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.modulate = Color("fff0c2")
			actor.add_child(label)
			label.position = camera.global_basis.y * -0.55
	await _save("/tmp/tofufu-melee-trajectories.png")
	for child in stage.get_children():
		if child not in [camera, environment, sun]: child.queue_free()
	await process_frame
	await _launch_demo()
	await _first_person()
	stage.queue_free()
	await process_frame
	print("Melee trajectory and launch previews saved in /tmp/tofufu-melee-*.png")
	quit()

func _launch_demo() -> void:
	camera.size = 6.0
	camera.position = Vector3(4, 5, 5)
	camera.look_at(Vector3(0, 0.55, 0))
	var floor_body := StaticBody3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(12, 0.2, 12)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("667c68")
	box.material = material
	var mesh := MeshInstance3D.new()
	mesh.mesh = box
	floor_body.add_child(mesh)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box.size
	collider.shape = shape
	floor_body.add_child(collider)
	floor_body.position.y = -0.1
	stage.add_child(floor_body)
	var actor := Node3D.new()
	stage.add_child(actor)
	var sprite := FufuVisuals.new()
	sprite.position.y = 0.56
	actor.add_child(sprite)
	var combat := PlayerCombat.new()
	combat.actor = actor
	stage.add_child(combat)
	ActorWeaponHands.connect_visuals(sprite, combat)
	combat.gun.visual.visible = false
	combat.sotjet.visual.visible = false
	combat.equipment.nori_selected = true
	combat.sword.set_nori(true)
	combat.critical_roll = func() -> float: return 1.0
	var mob := TrainingMob.new()
	mob.position = Vector3(0, 0.05, 1.0)
	mob.quarry = actor
	stage.add_child(mob)
	mob.target.current = 1000
	mob._rest = 20.0
	combat.targets = [mob.target]
	var command := PlayerCommand.new()
	command.aim = Vector2.DOWN
	sprite.attack_facing = command.aim
	sprite.present(command, Vector3.ZERO, true, false, 0.0)
	for move in 4:
		mob.position.x = 0.0
		mob.position.z = 1.0
		await physics_frame
		combat.strike(Vector2.DOWN, 0.0)
		for tick in 44:
			await physics_frame
			combat.step(command.aim, false, 1.0 / 60.0)
			if tick in [14, 26] and move == 3: await _save("/tmp/tofufu-melee-launch-%d.png" % tick)
		await _save("/tmp/tofufu-melee-combo-%d.png" % (move + 1))

func _save(path: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func _first_person() -> void:
	var actor := CharacterBody3D.new()
	stage.add_child(actor)
	var combat := PlayerCombat.new()
	combat.actor = actor
	stage.add_child(combat)
	combat.set_process(false)
	combat.gun.visual.visible = false
	combat.sotjet.visual.visible = false
	combat.equipment.nori_selected = true
	var view := FirstPersonWeapon.new()
	view.actor = actor
	view.combat = combat
	root.add_child(view)
	view.set_process(false)
	for style in [0, 6, 1, 4]:
		combat.active = true
		combat.attack_style = style
		combat._elapsed = combat._attack_duration() * 0.6
		combat._previous_elapsed = combat._elapsed
		combat.hit_pause = combat.tuning.light_hit_pause
		view._process(0.0)
		await _save("/tmp/tofufu-melee-first-person-%d.png" % style)
	view.queue_free()
	combat.queue_free()
	actor.queue_free()

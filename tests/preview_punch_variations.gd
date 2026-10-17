extends SceneTree
## Actual Godot renders of every outfit/style, rotated aim, and rapid clicks.

const OUT := "/tmp/tofufu-punch-variations/"
var stage: Node3D
var camera: Camera3D
var actors: Array[Node3D] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	root.size = Vector2i(1600, 1100)
	root.content_scale_size = root.size
	stage = Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("30463f")
	stage.add_child(environment)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 10.4
	stage.add_child(camera)
	camera.position = Vector3(0, 12, 14)
	camera.look_at(Vector3.ZERO)
	for row in 4:
		for column in 4:
			_add_actor(row, column, 4, column, Vector2(0.85, 0.53))
	await _save("all-sixteen-strikes")
	_clear()
	await process_frame
	root.size = Vector2i(1920, 1100)
	root.content_scale_size = root.size
	camera.size = 16.0
	for style in 4:
		for row in 4:
			for column in 8:
				_add_actor(row, column, 8, style, Vector2(cos(column * PI / 4), sin(column * PI / 4)))
		await _save("eight-directions-" + PunchImpact.STYLES[style])
		_clear()
		await process_frame
	await _burst()
	stage.queue_free()
	await process_frame
	print("Punch variation previews saved: ", ProjectSettings.globalize_path(OUT))
	quit()

func _add_actor(row: int, column: int, columns: int, style: int, aim: Vector2) -> void:
	var actor := Node3D.new()
	actor.position = camera.global_basis.x * ((column - (columns - 1) * 0.5) * 1.9) + camera.global_basis.y * ((1.5 - row) * 1.75)
	stage.add_child(actor)
	actors.append(actor)
	var sprite := FufuVisuals.new()
	sprite.position.y = 0.56
	actor.add_child(sprite)
	sprite.set_worn_set(PunchImpact.OUTFITS[row], false)
	var command := PlayerCommand.new()
	command.aim = aim
	sprite.unarmed_pose = func() -> Dictionary:
		return {"style": style, "elapsed": 0.04, "duration": PunchImpact.LIFETIME, "aim": aim}
	sprite.present(command, Vector3.ZERO, true, false, 0)
	var effect := CombatEffects.punch(actor, actor.global_position + Vector3(aim.x * 0.65, 0.55, aim.y * 0.65), style + 1, PunchImpact.OUTFITS[row], aim)
	effect.set_process(false)
	effect.age = 0.04
	effect.present()
	_label(actor, ("Fufu" if row == 0 else PunchImpact.OUTFITS[row].capitalize()) + " / " + PunchImpact.STYLES[style], -0.35)

func _burst() -> void:
	root.size = Vector2i(1200, 900)
	root.content_scale_size = root.size
	camera.size = 3.8
	var actor := Node3D.new()
	stage.add_child(actor)
	var sprite := FufuVisuals.new()
	sprite.position.y = 0.56
	actor.add_child(sprite)
	sprite.set_worn_set("celestial", false)
	var command := PlayerCommand.new()
	command.aim = Vector2.RIGHT
	sprite.present(command, Vector3.ZERO, true, false, 0)
	var combat := PlayerCombat.new()
	combat.actor = actor
	stage.add_child(combat)
	ActorWeaponHands.connect_visuals(sprite, combat)
	combat.set_process(false)
	combat.equipment.knife_owned = false
	combat.equipment.knife_selected = false
	combat.equipment.punch_outfit = "celestial"
	combat.gun.visual.hide()
	combat.sotjet.visual.hide()
	_label(actor, "Rapid clicks / jab, cross, uppercut, kick", -0.4)
	for click in 4:
		for effect in combat.equipment.get_children():
			if effect is PunchImpact: effect._process(0.041)
		combat.equipment.step(command.aim, false, true, false, false, 0, 0.041, -1, true)
		sprite.present(command, Vector3.ZERO, true, false, 0)
		for effect in combat.equipment.get_children():
			if effect is PunchImpact: effect.set_process(false)
		await _save("rapid-click-%d" % (click + 1))
	combat.equipment._punch_time = 0.0
	sprite.present(command, Vector3.ZERO, true, false, 0)
	await _save("recovered-idle")
	actor.queue_free()
	combat.queue_free()

func _label(actor: Node3D, text: String, height: float) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 28
	label.pixel_size = 0.004
	label.modulate = Color("fff2d5")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	actor.add_child(label)
	label.position = camera.global_basis.y * height

func _clear() -> void:
	for actor in actors: actor.queue_free()
	actors.clear()

func _save(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + label + ".png")

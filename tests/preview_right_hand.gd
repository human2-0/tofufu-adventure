extends SceneTree
## Native-rendered eight-angle contact sheet, including arm/hand depth and outfits.
var sprites: Array[FufuVisuals] = []
var combats: Array[PlayerCombat] = []
var camera: Camera3D
var items: Array[String] = ["knife", "nori_katana", "edamame_sword", "sproutwood_staff", "soy_gun", "sotjet"]

func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(1680, 1080)
	var stage := Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("304d48")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.9
	stage.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -20, 0)
	stage.add_child(sun)
	camera = Camera3D.new()
	stage.add_child(camera)
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 28.0
	camera.position = Vector3(0, 18, 18)
	camera.look_at(Vector3.ZERO)
	for row in items.size():
		for facing in 8:
			var body := Node3D.new()
			body.position = camera.global_basis.x * ((facing - 3.5) * 2.15) + camera.global_basis.y * ((2.5 - row) * 1.9)
			stage.add_child(body)
			var sprite := FufuVisuals.new()
			sprite.position.y = 0.56
			body.add_child(sprite)
			sprites.append(sprite)
			var combat := PlayerCombat.new()
			combat.actor = body
			stage.add_child(combat)
			combats.append(combat)
			ActorWeaponHands.connect_visuals(sprite, combat)
			combat.set_process(false)
			combat.equipment.knife_selected = row < 3
			combat.equipment.nori_selected = row == 1
			combat.equipment.pod_selected = row == 2
			combat.sword.set_nori(row == 1)
			combat.sword.set_pod(row == 2)
			combat.sword.visible = row < 3
			combat.staff.visible = row == 3
			combat.gun.visual.visible = row == 4
			combat.sotjet.visual.visible = row == 5
			var label := Label3D.new()
			label.text = "%s / %s" % [items[row], ["E", "SE", "S", "SW", "W", "NW", "N", "NE"][facing]]
			label.font_size = 22
			label.pixel_size = 0.0042
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			body.add_child(label)
			label.position = camera.global_basis.y * -0.4
	for outfit in ["", "bright_leaf", "dark_leaf"]:
		for state in ["idle", "walk", "jump", "charge", "cut", "reload"]:
			for index in sprites.size():
				var sprite := sprites[index]
				var combat := combats[index]
				var facing := index % 8
				var command := PlayerCommand.new()
				command.aim = Vector2.from_angle(facing * PI / 4)
				command.move = command.aim if state == "walk" else Vector2.ZERO
				sprite.set_worn_set(outfit, false)
				sprite.jump_animation.reset()
				sprite.anim_timer = 1
				sprite.present(command, Vector3(command.move.x * 4.8, 4.0 if state == "jump" else 0.0, command.move.y * 4.8), state != "jump", false, 0, 0.6 if state == "charge" else 0.0)
				var cutting: bool = state == "cut"
				var pose := SwordGeometry.pose(combat.actor.global_position, command.aim, 0.5 if cutting else -1.0, combat.tuning)
				combat.sword.present(pose, command.aim, 0, cutting, 0 if cutting else 1.0)
				combat.staff.present(pose, 0, false, 0 if cutting else 1.0)
				combat.gun.visual.facing = command.aim
				combat.gun.visual.reload_remaining = 1.0 if state == "reload" else 0.0
				combat.gun.visual.refresh()
				combat.sotjet.visual.facing = command.aim
				combat.sotjet.visual.refresh()
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/tofufu-right-hand-%s-%s.png" % ["base" if outfit.is_empty() else outfit, state])
	print("Right-hand native renderer contact sheets saved in /tmp/tofufu-right-hand-*.png")
	stage.queue_free()
	await process_frame
	quit()

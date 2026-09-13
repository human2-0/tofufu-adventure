extends SceneTree
## Render every mirrored jump direction, hand attachment and gun muzzle.
var actors: Array[Player] = []
var guns: Array[SoyGun] = []
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(1440, 900)
	var stage := Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("425e59")
	stage.add_child(environment)
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.position = Vector3(0, 3.8, 7)
	camera.look_at(Vector3(0,0.6,0))
	camera.fov = 43
	for index in 8:
		var actor: Player = load("res://game/player/player.tscn").instantiate()
		stage.add_child(actor)
		actor.set_physics_process(false)
		actor.position = Vector3((index % 4 - 1.5) * 1.7, 0, (index / 4 - 0.5) * 2.5)
		actors.append(actor)
		var combat := PlayerCombat.new()
		combat.actor = actor
		stage.add_child(combat)
		combat.sword.visible = false
		combat.gun.selected = true
		combat.gun.visual.visible = true
		combat.gun.visual.facing = Vector2.from_angle(index * PI / 4)
		actor.visuals.hand_presented.connect(combat.gun.visual.follow_hand)
		guns.append(combat.gun)
		var label := Label3D.new()
		label.text = ["E (mirror)", "SE (mirror)", "S (original)", "SW", "W", "NW", "N", "NE (mirror)"][index]
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 32
		label.pixel_size = 0.006
		stage.add_child(label)
		label.position = actor.position + Vector3(0,-0.2,0)
	for phase in 10:
		for index in 8:
			var sprite := actors[index].visuals
			sprite.current_facing = index as FufuVisuals.Facing
			sprite.jump_animation.frame = phase
			sprite.jump_animation.apply(sprite, index)
			sprite._using_jump_frame = true
			sprite._present_hand()
		for frame in 3: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/tofufu-directional-jump-%02d.png" % phase)
	# Cosmetic beans must visibly start on each gun's drawn barrel.
	for index in 8:
		var gun := guns[index]
		gun.step(true, true, gun.visual.facing, actors[index].position + Vector3(0,0.8,-20), 0.016)
		for child in gun.get_children():
			if child is SoyProjectile:
				child.set_physics_process(false)
				child.set_process(false)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-muzzle-origins.png")
	stage.queue_free()
	await process_frame
	quit()

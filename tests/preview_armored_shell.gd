extends SceneTree
## Run without --headless; writes shell contact/break frames to /tmp.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(2.7, 1.9, 3.5)
	camera.look_at(Vector3(0, 0.55, 0))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.5
	var light := DirectionalLight3D.new()
	world.add_child(light)
	light.rotation_degrees = Vector3(-55, -30, 0)
	light.light_energy = 1.3
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("334943")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("dbe7d2")
	environment.environment.ambient_light_energy = 0.6
	world.add_child(environment)
	var snail := ArmoredSnail.new()
	world.add_child(snail)
	snail.set_physics_process(false)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/armored-shell-intact.png")
	snail.target.damage(20, Vector3.RIGHT, Damageable.HitKind.SOY, Vector3(-0.45, 0.8, 0))
	await create_timer(0.07).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/armored-shell-hit.png")
	await create_timer(0.9).timeout
	snail.target.damage(30, Vector3.RIGHT, Damageable.HitKind.SOY, Vector3(0, 0.8, 0))
	await create_timer(0.12).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/armored-shell-break.png")
	await create_timer(1.0).timeout
	world.queue_free()
	await process_frame
	quit()

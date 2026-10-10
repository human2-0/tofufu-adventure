extends SceneTree
## Standalone studio views of the same shared mount art used in the world.
func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var studio := Node3D.new()
	root.add_child(studio)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("e7ebe0")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.65
	studio.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, -35, 0)
	light.light_energy = 0.8
	studio.add_child(light)
	var bird := ParrotArt.new()
	studio.add_child(bird)
	bird.airborne = true
	bird.set_process(false)
	bird._process(1.0)
	var camera := Camera3D.new()
	camera.fov = 36
	studio.add_child(camera)
	for view: String in ["front", "side", "behind", "perched"]:
		camera.position = Vector3(3, 2.5, -6) if view == "front" else (Vector3(5, 2.4, -0.6) if view == "side" else Vector3(3, 2.3, 6))
		if view == "perched":
			bird.airborne = false
			for i in 60: bird._process(1.0 / 60.0)
		camera.look_at(Vector3(0, 0.9, 0.3))
		for frame in 10: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/tofufu-parrot-art-" + view + ".png")
	studio.queue_free()
	await process_frame
	quit()

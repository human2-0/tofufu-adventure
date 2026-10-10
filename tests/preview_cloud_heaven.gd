extends SceneTree
## Render heavenly surfaces, Greek architecture and the cloud skirts on the GPU.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1440, 900)
	var stage := Node3D.new()
	root.add_child(stage)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("c7d9e9")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("e7edf9")
	world.environment.ambient_light_energy = 0.65
	stage.add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -30, 0)
	light.light_energy = 0.7
	light.shadow_enabled = true
	stage.add_child(light)
	var realm := CloudRealm.new()
	stage.add_child(realm)
	var camera := Camera3D.new()
	stage.add_child(camera)
	await capture(camera, Vector3(70, 117, 389), Vector3(-8, 58, 299), "overview")
	var at := realm.godfufu.global_position
	await capture(camera, at + Vector3(13, 10, 26), at + Vector3(0, 2.5, -3), "temple")
	await capture(camera, at + Vector3(6, 5, 12), at + Vector3(2, 1.5, 0), "court")
	at = CloudTerrain.point(43, 287)
	await capture(camera, at + Vector3(8, 6, 14), at + Vector3(0, 1.5, -1), "market")
	at = CloudTerrain.point(4, 336)
	await capture(camera, at + Vector3(12, 8, 25), at + Vector3(0, 2, 2), "sanctuary")
	at = CloudTerrain.point(-55, 292)
	await capture(camera, at + Vector3(8, 6, 14), at + Vector3(0, 1, 0), "fountain")
	await capture(camera, Vector3(104, 47, 387), Vector3(9, 56, 298), "cloudbanks")
	stage.free()
	print("Cloud heaven GPU preview: PASS")
	quit()

func capture(camera: Camera3D, eye: Vector3, target: Vector3, label: String) -> void:
	camera.position = eye
	camera.look_at(target)
	for frame in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-heaven-" + label + ".png")

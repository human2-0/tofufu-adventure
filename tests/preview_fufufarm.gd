extends SceneTree
## Actual renderer QA for the entire first terrain and its village services.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Node3D = load("res://game/app/main.tscn").instantiate()
	scene.play_opening = false
	root.add_child(scene)
	scene.hud.visible = false
	scene.player.set_physics_process(false)
	scene.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	scene.cycle.set_process(false)
	scene.cycle.phase = 0.4
	scene.cycle._process(0)
	var camera: Camera3D = scene.get_node("Camera3D")
	camera.set_physics_process(false)
	var views: Array[Vector3] = [Vector3(0, 0, 0), Vector3(23, 0, 4), Vector3(-22, 2, -21), Vector3(-2, 0, -4), Vector3(-11, 1, 17), Vector3(30, 1, 18)]
	var names: Array[String] = ["overview", "village", "seed-bank", "nursery", "fields", "mayor"]
	for i in views.size():
		camera.position = views[i] + (Vector3(0, 65, 55) if i == 0 else Vector3(0, 17, 19))
		camera.look_at(views[i])
		camera.fov = 55 if i == 0 else 48
		scene.player.position = scene.world.ground_point(views[i].x, views[i].z + 2, 0.1)
		for frame in 8:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/fufufarm-" + names[i] + ".png")
	scene.cycle.phase = 0.94
	scene.cycle._process(0)
	camera.position = Vector3(23, 17, 23)
	camera.look_at(Vector3(23, 0, 4))
	for frame in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/fufufarm-night.png")
	scene.queue_free()
	await process_frame
	quit()

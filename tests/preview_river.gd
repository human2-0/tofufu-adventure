extends SceneTree
## Render both the missing reaches and close-up wildlife in the actual world.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world: Meadow = load("res://game/world/meadow.tscn").instantiate()
	root.add_child(world)
	var cycle: EnvironmentCycle = world.get_node("EnvironmentCycle")
	cycle.phase = 0.43
	cycle._process(0.0)
	cycle.set_process(false)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.current = true
	var life: RiverWildlife = world.get_node("RiverWildlife")
	life.set_process(false)
	var targets := [Vector3(11, 0, 9), RiverCourse.point(76), RiverCourse.point(109), Vector3(-38, -2, 148), RiverCourse.point(-23.4)]
	var offsets := [Vector3(10, 10, 13), Vector3(15, 21, 26), Vector3(18, 19, 25), Vector3(18, 20, 25), Vector3(2.5, 2.6, 3.4)]
	var names := ["village", "extension", "desert", "oasis", "fish"]
	for i in targets.size():
		life.present(12.0)
		if i == 4:
			var time := (47.0 + 6.0 * 1.31) * 2.0 - 6.0 * 11.7 + 0.475
			life.present(time)
			targets[i] = RiverWildlife.swim_position(6, time)
		camera.position = targets[i] + offsets[i]
		camera.look_at(targets[i])
		for frame in 12: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/tofufu-river-" + names[i] + ".png")
	world.queue_free()
	await process_frame
	quit()

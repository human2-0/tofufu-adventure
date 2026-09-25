extends SceneTree
## Render the actual meadow sky at a low horizon for each authored mood.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world: Node3D = load("res://game/world/meadow.tscn").instantiate()
	root.add_child(world)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(0, 12, 25)
	camera.look_at(Vector3(0, 15, -70))
	camera.current = true
	var cycle: EnvironmentCycle = world.get_node("EnvironmentCycle")
	cycle.set_process(false)
	var phases := [0.48, 0.25, 0.73, 0.79, 0.0, 0.45]
	var names := ["day", "dawn", "peach", "lavender", "night", "storm"]
	for i in phases.size():
		cycle.phase = phases[i]
		cycle.cloud_cover = 1.0 if i == 5 else 0.0
		cycle.cycle_seconds = 1.0e10
		cycle._process(5.0)
		if i == 5:
			cycle.sky_effects._next_strike = 0.0
			cycle._process(0.0)
		for frame in 8:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/tofufu-sky-" + names[i] + ".png")
	world.queue_free()
	await process_frame
	quit()

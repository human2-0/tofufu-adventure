extends SceneTree
## Seams, water classification and collision ground for the northern biome chain.

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("FAIL: " + message)

func _run() -> void:
	var scene := load("res://game/app/main.tscn").instantiate() as Node3D
	scene.play_opening = false
	root.add_child(scene)
	scene.player.set_physics_process(false)
	await physics_frame
	await physics_frame
	var locked_entry := Transform3D(Basis.IDENTITY, Vector3(0, 6, -76))
	check(not scene.player.test_move(locked_entry, Vector3(0, 0, -10)), "ocean test route is open")
	check(is_equal_approx(OceanTerrain.height_at(0, -84, scene.world.terrain), scene.world.terrain.height_at(0, -84)), "meadow-to-ocean seam matches")
	check(is_equal_approx(FrostTerrain.height_at(0, -220, scene.world.ocean), OceanTerrain.height_at(0, -220, scene.world.terrain)), "ocean-to-frost seam matches")
	check(scene.world.is_water(scene.world.ground_point(0, -150)), "seabed is classified as water")
	for at in [Vector3(0, 20, -110), Vector3(-52, 20, -160), Vector3(0, 20, -232), Vector3(44, 20, -298), Vector3(-50, 20, -332)]:
		var ray := PhysicsRayQueryParameters3D.create(at, at + Vector3.DOWN * 35, 1)
		check(not scene.player.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(), "northern biome has collision ground")
	if DisplayServer.get_name() != "headless":
		scene.hud.visible = false
		scene.encounters.process_mode = Node.PROCESS_MODE_DISABLED
		var camera: Camera3D = scene.get_node("Camera3D")
		camera.set_physics_process(false)
		for i in [0, 1]:
			var target := Vector3(-52, -3, -160) if i == 0 else Vector3(44, 2, -298)
			camera.position = target + Vector3(12, 14, 20)
			camera.look_at(target)
			for frame in 8: await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/northern-biome-%d.png" % i)
	scene.queue_free()
	await process_frame
	quit(1 if failures else 0)

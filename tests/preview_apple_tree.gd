extends SceneTree
## Godot renderer preview for the meadow apple tree and its fruit lifecycle.

func _initialize() -> void:
	call_deferred("_render")

func _render() -> void:
	var scene := Node3D.new()
	root.add_child(scene)
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("bfd4d3")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d9e5ca")
	environment.ambient_light_energy = 0.65
	world_environment.environment = environment
	scene.add_child(world_environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-48, -28, 0)
	light.shadow_enabled = true
	light.light_energy = 1.25
	scene.add_child(light)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(9, 9)
	ground.mesh = plane
	ground.position.y = -0.04
	ground.material_override = MeadowGeometry.material(Color("8da96a"))
	scene.add_child(ground)
	ground.create_trimesh_collision()
	var tree := AppleTree.new()
	tree.rotation.y = -0.32
	tree.scale = Vector3.ONE * 1.08
	scene.add_child(tree)
	tree.set_physics_process(false)
	var pool := WorldItemPool.new()
	pool.build_visual = WorldItemVisuals.build
	scene.add_child(pool)
	tree.apples_felled.connect(func(count: int, at: Vector3) -> void:
		var drop := pool.spawn_at("apple", count, 100.0, Vector3(at.x, WorldItemDrop.RADIUS, at.z))
		drop.set_focus(true, "[E] Pick up Apple ×4"))
	var camera := Camera3D.new()
	camera.position = Vector3(5.3, 4.4, 7.4)
	camera.fov = 42
	camera.current = true
	scene.add_child(camera)
	camera.look_at(Vector3(0, 1.65, 0))
	tree.present(true, "[E] Shake tree · Drop 4 Apples")
	await _draw_frames(8)
	await _save("/tmp/tofufu-apple-tree-ready.png")
	tree.harvest()
	tree.present(false, "")
	await create_timer(0.8).timeout
	await _draw_frames(8)
	await _save("/tmp/tofufu-apple-tree-felled.png")
	tree.step(AppleTree.REGROW_SECONDS)
	for id in pool.drops.keys(): pool.remove(id)
	tree.present(true, "[E] Shake tree · Drop 4 Apples")
	await _draw_frames(12)
	await _save("/tmp/tofufu-apple-tree-regrown.png")
	print("Apple tree renderer previews saved under /tmp/tofufu-apple-tree-*.png")
	scene.queue_free()
	await process_frame
	quit()

func _draw_frames(count: int) -> void:
	for frame in count: await process_frame
	await RenderingServer.frame_post_draw

func _save(path: String) -> void:
	root.get_texture().get_image().save_png(path)

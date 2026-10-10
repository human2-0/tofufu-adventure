extends SceneTree
## Paired render of immutable geometry before/after baking, including scaled ink.

func _initialize() -> void: call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 60
	var viewport: SubViewport = preload("res://tests/rendering_viewport.gd").create(root)
	var scene := Node3D.new()
	viewport.add_child(scene)
	var camera := Camera3D.new()
	scene.add_child(camera)
	camera.position = Vector3(5, 4, 11)
	camera.look_at(Vector3(0, 0.5, 0))
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -30, 0)
	scene.add_child(sun)
	var scenery := Node3D.new()
	scene.add_child(scenery)
	MeadowGeometry.rock(scenery, Vector3(-2, 0, 0), Vector3(2, 0.5, 1.3), Color("829979"))
	MeadowGeometry.rock(scenery, Vector3(2, 0.2, 0), Vector3(0.4, 2, 0.8), Color("978982"))
	var box := MeadowGeometry.box(scenery, Vector3(0, -0.5, 1), Vector3(2, 0.8, 1), Color("8c815f"))
	box.rotation = Vector3(0.2, 0.4, 0.1)
	JungleProps.leaf(scenery, Vector3(0, 1, 1), Vector3.RIGHT, 2, Color.GREEN)
	for phase in ["before", "after"]:
		if phase == "after": StaticDecorationBatch.build(scenery)
		for frame in 8: await process_frame
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("/tmp/tofufu-scenery-%s.png" % phase)
	for child in root.get_children(): child.queue_free()
	await process_frame
	print("Scenery paired captures: complete")
	quit()

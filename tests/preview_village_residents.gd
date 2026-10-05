extends SceneTree
## Actual Sprite3D camera-relative views with measured feet and shared species scale.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	MeadowGeometry.box(stage, Vector3(0, -0.1, 0), Vector3(30, 0.2, 30), Color("a6b38a"))
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-65, -25, 0)
	light.light_energy = 1.2
	stage.add_child(light)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 6
	stage.add_child(camera)
	camera.make_current()
	var residents: Array[Node3D] = []
	for asset: String in ["grandma", "grandpa"]:
		var resident := MeadowVillage.resident(stage, Vector3.ZERO, asset.capitalize() + " Fufu", asset)
		(resident.get_node("DirectionalArt") as MeadowResidentArt).facing = Vector2.DOWN
		(resident.get_node("ResidentTitle") as Label3D).billboard = BaseMaterial3D.BILLBOARD_ENABLED
		residents.append(resident)
	var views: Array[Vector3] = [Vector3(0, 5, -7), Vector3(-5, 5, -5), Vector3(-7, 5, 0), Vector3(-5, 5, 5), Vector3(0, 5, 7)]
	var names: Array[String] = ["north", "north-east", "east", "south-east", "south"]
	for index in views.size():
		camera.position = views[index]
		camera.look_at(Vector3(0, 1, 0))
		for side in 2: residents[side].position = camera.global_basis.x * (-1.2 + side * 2.4)
		for frame in 8: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/village-residents-" + names[index] + ".png")
	stage.queue_free()
	for frame in 3: await process_frame
	quit()

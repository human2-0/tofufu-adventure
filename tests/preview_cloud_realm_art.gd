extends SceneTree
## Render all authored directions through the actual billboard material in Godot.

const VIEWS: Array[int] = [6, 7, 0, 1, 2]
const GROUPS: Array = [["godfufu", "goddess", "guardian"], ["nimbus", "petal", "mallow"], ["lumen", "pearl", "angel"]]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1600, 1000)
	var stage := Node3D.new()
	root.add_child(stage)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("c8dedb")
	stage.add_child(world)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 24
	camera.position = Vector3(0, 6, 30)
	stage.add_child(camera)
	camera.look_at(Vector3(0, 6, 0))
	for group in GROUPS.size():
		var page := Node3D.new()
		stage.add_child(page)
		for row in 3:
			var key: String = GROUPS[group][row]
			for col in 5:
				var art := CloudResidentArt.new()
				art.asset = key
				art.height = 3.3
				art.position = Vector3((col - 2) * 4.5, (2 - row) * 4.3, 0)
				page.add_child(art)
				art.set_process(false)
				art.present_direction(VIEWS[col])
			var label := Label3D.new()
			label.text = key.capitalize() + "  ·  N / NE / E / SE / S"
			label.font_size = 28
			label.pixel_size = 0.012
			label.position = Vector3(0, (2 - row) * 4.3 + 3.7, 0)
			page.add_child(label)
		for frame in 5: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/tofufu-cloud-art-%d.png" % group)
		page.free()
	stage.free()
	quit()

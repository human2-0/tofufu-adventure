extends SceneTree
## Actual Godot plate of all five authored views, followed by an eight-view camera orbit.

const NAMES: Array[String] = ["east", "south-east", "south", "south-west", "west", "north-west", "north", "north-east"]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1600, 720)
	var stage := Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("212333")
	stage.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -30, 0)
	stage.add_child(light)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12
	camera.position = Vector3(0, 8, 27)
	stage.add_child(camera)
	camera.look_at(Vector3(0, 2, 0))
	camera.make_current()
	var kings: Array[LavaKing] = []
	for i in 5:
		var king := LavaKing.new()
		king.position.x = (i - 2) * 5.1
		stage.add_child(king)
		king.set_process(false)
		king.sprite.set_process(false)
		king.sprite.present_direction([6, 7, 0, 1, 2][i])
		kings.append(king)
		CastleGeometry.solid(stage, king.position + Vector3(0, -0.25, 0), Vector3(4.6, 0.5, 3), Color("987a66"))
		var label := Label3D.new()
		label.text = ["NORTH", "NORTH-EAST", "EAST", "SOUTH-EAST", "SOUTH"][i]
		label.position = king.position + Vector3(0, -0.7, 2)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 30
		label.pixel_size = 0.012
		stage.add_child(label)
	await capture("views")
	for king in kings: king.visible = false
	var orbit_king := LavaKing.new()
	stage.add_child(orbit_king)
	orbit_king.set_process(false)
	camera.size = 7.5
	for direction in 8:
		var angle := direction * PI / 4
		camera.position = Vector3(-cos(angle) * 12, 6, sin(angle) * 12)
		camera.look_at(Vector3(0, 2, 0))
		await capture(NAMES[direction])
	stage.queue_free()
	for frame in 4: await process_frame
	quit()

func capture(label: String) -> void:
	for frame in 10: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-lava-king-" + label + ".png")

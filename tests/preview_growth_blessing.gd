extends SceneTree
## Actual-render blessing phases on an isolated actor with bounded effects.
const OUT := "res://.codex/visualizations/2026/10/16/growth/"
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	root.size = Vector2i(1200, 900)
	root.content_scale_size = root.size
	var stage := Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("2a3c35")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	stage.add_child(environment)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 4.2
	stage.add_child(camera)
	camera.position = Vector3(2, 3, 5)
	camera.look_at(Vector3.UP * 0.8)
	var actor := preload("res://game/player/player.tscn").instantiate() as Player
	stage.add_child(actor)
	actor.set_physics_process(false)
	var blessing := LevelBlessing.new()
	actor.add_child(blessing)
	blessing.set_process(false)
	for phase in [0.35, 1.4, 2.7]:
		blessing.age = 0.0
		blessing._process(phase)
		for frame in 5: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT + "blessing-%.2f.png" % phase)
	stage.queue_free()
	await process_frame
	quit()

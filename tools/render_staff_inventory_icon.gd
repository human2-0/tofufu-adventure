extends SceneTree
## Renders the supplied GLB to its square transparent inventory icon.

const OUTPUT := "res://game/inventory/icons/sproutwood_staff.png"
const MODEL := "res://assets/weapons/sproutwood_staff/source/sproutwood_staff.glb"

func _initialize() -> void:
	call_deferred("_render")

func _render() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(512, 512)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.65
	camera.position = Vector3(0.65, 0.25, 3.3)
	world.add_child(camera)
	camera.look_at(Vector3.ZERO)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, -25, 0)
	key.light_energy = 1.35
	world.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 145, 0)
	fill.light_color = Color(0.72, 0.86, 1.0)
	fill.light_energy = 0.55
	world.add_child(fill)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0, 0, 0, 0)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(0.8, 0.9, 0.78)
	environment.environment.ambient_light_energy = 0.65
	world.add_child(environment)
	var model := load(MODEL).instantiate() as Node3D
	model.rotation.y = 0.28
	world.add_child(model)
	for _frame in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	var result := image.save_png(ProjectSettings.globalize_path(OUTPUT))
	if result != OK:
		push_error("Could not save staff icon: %s" % error_string(result))
	quit(0 if result == OK else 1)

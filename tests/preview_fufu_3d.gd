extends SceneTree
## Actual-renderer turnaround, walk contact/stride and village-placement evidence.

const OUTPUT := "res://.codex/visualizations/2026/10/16/fufu-3d/manga-outlines/"
const DISPLAY := preload("res://game/world/farm/fufu_3d_display.tscn")

func _initialize() -> void:
	call_deferred("_run")

func _capture(title: String) -> void:
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT + title + ".png"))

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.size = Vector2i(1440, 1000)
	var stage := Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("29332f")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("edf0e8")
	environment.environment.ambient_light_energy = 0.5
	stage.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, -35, 0)
	sun.light_energy = 0.95
	sun.shadow_enabled = true
	stage.add_child(sun)
	var floor_view := MeshInstance3D.new()
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(200, 200)
	floor_view.mesh = floor_mesh
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("3a493f")
	floor_material.roughness = 1.0
	floor_view.material_override = floor_material
	stage.add_child(floor_view)
	var display := DISPLAY.instantiate() as Fufu3DDisplay
	stage.add_child(display)
	display.animation.pause()
	display.animation.seek(0.0, true)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.15
	stage.add_child(camera)
	for view in [{"name": "front", "at": Vector3(0, 1.45, 4)},
		{"name": "three-quarter", "at": Vector3(2.7, 1.7, 3.5)},
		{"name": "side", "at": Vector3(4, 1.3, 0)},
		{"name": "back", "at": Vector3(1.8, 1.5, -4)}]:
		camera.position = view.at
		camera.look_at(Vector3(0, 0.97, 0))
		await _capture(view.name)
	camera.position = Vector3(1.7, 1.55, 4)
	camera.look_at(Vector3(0, .97, 0))
	for index in 8:
		display.animation.seek(index * 1.25 / 8, true)
		await _capture("walk-%02d" % index)
	stage.queue_free()
	await process_frame
	var world := preload("res://game/world/farm/meadow.tscn").instantiate() as Meadow
	root.add_child(world)
	var village_camera := Camera3D.new()
	world.add_child(village_camera)
	var at := world.ground_point(40, -13.5)
	village_camera.position = at + Vector3(-3.0, 2.7, 5.0)
	village_camera.look_at(at + Vector3(0, 1, 0))
	village_camera.fov = 48
	await _capture("village-close")
	village_camera.position = at + Vector3(-6, 12, 13)
	village_camera.look_at(at + Vector3(2, 0, -3))
	await _capture("village-context")
	world.queue_free()
	await process_frame
	quit()

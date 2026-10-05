extends SceneTree
## Render all five harvestable-soy stages and a close view of the mature canopy.

func _initialize() -> void:
	call_deferred("_render")

func _render() -> void:
	root.size = Vector2i(1440, 800)
	var scene := Node3D.new()
	root.add_child(scene)
	var sky := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("c3d8db")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("e0ebce")
	environment.ambient_light_energy = 0.65
	sky.environment = environment
	scene.add_child(sky)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -25, 0)
	light.shadow_enabled = true
	scene.add_child(light)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(18, 10)
	ground.mesh = plane
	var earth := StandardMaterial3D.new()
	earth.albedo_color = Color("6d7950")
	ground.material_override = earth
	ground.position.y = -0.015
	scene.add_child(ground)
	var times := [0.0, 9.0, 26.0, 46.0, 60.0]
	var names := ["SEED + SHOOT", "SPROUT", "VEGETATION", "FLOWERING", "MATURE PODS"]
	for index in 5:
		var plant := HarvestProp.new()
		plant.position.x = (index - 2) * 1.75
		scene.add_child(plant)
		plant.set_physics_process(false)
		EncounterState.apply_prop(plant, [20.0 if index == 4 else 0.0, 60.0 - times[index]])
		var label := Label3D.new()
		label.text = "%s\n%d / 60 seconds" % [names[index], int(times[index])]
		label.font_size = 26
		label.pixel_size = 0.004
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = Vector3(plant.position.x, 1.8, 0)
		scene.add_child(label)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 4.4, 8.8)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 5.2
	camera.current = true
	scene.add_child(camera)
	camera.look_at(Vector3(0, 0.65, 0))
	await _save("/tmp/tofufu-soy-stages.png")
	camera.size = 2.6
	camera.position = Vector3(5.3, 2.6, 3.2)
	camera.look_at(Vector3(3.5, 0.65, 0))
	await _save("/tmp/tofufu-soy-mature.png")
	scene.queue_free()
	await process_frame
	print("Soy plant renderer previews saved under /tmp/tofufu-soy-*.png")
	quit()

func _save(path: String) -> void:
	for frame in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

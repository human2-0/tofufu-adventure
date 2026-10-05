extends SceneTree
## Renders the supplied weapon GLBs into transparent inventory thumbnails.

const ICONS: Array[Dictionary] = [
	{"item_id": "knife", "path": "res://game/inventory/icons/knife_model.png", "rotation": Vector3(0, 0, -0.62)},
	{"item_id": "nori_katana", "path": "res://game/inventory/icons/nori_katana_model.png", "rotation": Vector3(0, 0.3, 0)},
	{"item_id": "sotjet", "path": "res://game/inventory/icons/soyjet_model.png", "rotation": Vector3(0, -0.2, 0)},
	{"item_id": "edamame_sword", "path": "res://game/inventory/icons/soypod_blade_model.png", "rotation": Vector3(0, 0.3, 0)},
]

func _initialize() -> void:
	call_deferred("_render")

func _render() -> void:
	for icon in ICONS:
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
		camera.size = 2.55
		camera.position = Vector3(0.12, 0.18, 3.4)
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
		var model := WeaponModelCatalog.scene_for(icon.item_id).instantiate() as Node3D
		model.rotation = icon.rotation
		world.add_child(model)
		for _frame in 8: await process_frame
		await RenderingServer.frame_post_draw
		var output := ProjectSettings.globalize_path(icon.path)
		var result := viewport.get_texture().get_image().save_png(output)
		if result != OK: push_error("Could not save weapon icon %s: %s" % [output, error_string(result)])
		else: print("Rendered %s" % output)
		viewport.queue_free()
		await process_frame
	quit()

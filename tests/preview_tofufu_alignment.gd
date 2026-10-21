extends SceneTree
## Actual Sprite3D frames on fixed body axes: every skin and all eight directions.
var sprites: Array[FufuVisuals] = []
var stage := Node3D.new()
var caption := Label3D.new()

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1800, 1350)
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("24353c")
	stage.add_child(environment)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 13.2
	camera.position = Vector3(0, 0, 20)
	stage.add_child(camera)
	_label("Torso axes · E / SE / S / SW / W / NW / N / NE", Vector3(0, 6.05, 0), 29)
	stage.add_child(caption)
	caption.position = Vector3(0, -5.9, 0)
	caption.font_size = 27
	caption.pixel_size = 0.01
	var mesh := ImmediateMesh.new()
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	stage.add_child(instance)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	for row in 7:
		_label(TofufuTestArt.NAMES[row].replace(" · ", "\n"), Vector3(-7.15, 4.95 - row * 1.65, 0), 17)
		for facing in 8:
			var sprite := FufuVisuals.new()
			stage.add_child(sprite)
			sprite.set_test_skin(TofufuTestArt.IDS[row])
			sprite.current_facing = facing as FufuVisuals.Facing
			sprite.position = Vector3(-5.3 + facing * 1.55, 5 - row * 1.65, 0)
			sprites.append(sprite)
			mesh.surface_set_color(Color("e17878"))
			mesh.surface_add_vertex(sprite.position + Vector3(0, -0.62, -0.02))
			mesh.surface_add_vertex(sprite.position + Vector3(0, 0.8, -0.02))
			mesh.surface_set_color(Color("9eb4bb"))
			mesh.surface_add_vertex(sprite.position + Vector3(-0.65, -0.56, -0.02))
			mesh.surface_add_vertex(sprite.position + Vector3(0.65, -0.56, -0.02))
	mesh.surface_end()
	for phase in 5: await _show("locomotion", phase)
	await _show("jump", 3)
	for phase in 4: await _show("melee", phase)
	print("Tofufu alignment preview complete")
	quit()

func _show(category: String, phase: int) -> void:
	caption.text = "%s · phase %d · fixed red axis passes through the torso" % [category, phase]
	for sprite: FufuVisuals in sprites: sprite.test_skin.apply(sprite, category, phase)
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.codex/visualizations/2026/10/20/battle-migration/tofufu-%s-%d.png" % [category, phase])

func _label(text: String, position: Vector3, size: int) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = size
	label.pixel_size = 0.01
	label.position = position
	stage.add_child(label)

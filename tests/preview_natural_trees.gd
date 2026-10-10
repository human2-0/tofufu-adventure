extends SceneTree
## Render both shared scenery and harvestable trees at close and gameplay distance.

func _initialize() -> void:
	call_deferred("_render")

func _render() -> void:
	var scene := Node3D.new()
	root.add_child(scene)
	var background := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("bfd4d3")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d9e5ca")
	environment.ambient_light_energy = 0.5
	background.environment = environment
	scene.add_child(background)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-48, -28, 0)
	light.shadow_enabled = true
	light.light_energy = 0.85
	scene.add_child(light)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(24, 20)
	ground.mesh = plane
	ground.position.y = -0.04
	ground.material_override = MeadowGeometry.material(Color("8da96a"))
	scene.add_child(ground)
	for index in 3:
		var tree: Node3D = preload("res://game/world/common/tree.tscn").instantiate()
		tree.position = Vector3(-4.5 + index * 4.5, 0, -1.5)
		tree.rotation.y = index * 1.7
		tree.scale = Vector3.ONE * (0.95 + index * 0.12)
		scene.add_child(tree)
	var apple := AppleTree.new()
	apple.position = Vector3(0, 0, 3.5)
	scene.add_child(apple)
	var camera := Camera3D.new()
	camera.position = Vector3(11, 9, 16)
	camera.fov = 44
	camera.current = true
	scene.add_child(camera)
	camera.look_at(Vector3(0, 1.5, 0))
	for frame in 12: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-natural-trees.png")
	print("Natural tree renderer preview saved to /tmp/tofufu-natural-trees.png")
	scene.queue_free()
	await process_frame
	await _render_meadow()
	quit()

func _render_meadow() -> void:
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.hud.hide()
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	game.camera.set_physics_process(false)
	game.camera.set_process(false)
	game.cycle.phase = 0.43
	game.cycle.set_process(false)
	game.cycle._process(0.0)
	game.weather.set_physics_process(false)
	var tree: AppleTree = game.world.apple_trees[0]
	game.player.relocate(tree.position + Vector3(2.2, 0.1, 2.2))
	game.player.set_physics_process(false)
	game.camera.position = tree.position + Vector3(4.2, 4.5, 8.0)
	game.camera.look_at(tree.position + Vector3.UP * 1.4)
	for frame in 12: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-natural-trees-meadow.png")
	print("Meadow tree renderer preview saved to /tmp/tofufu-natural-trees-meadow.png")
	game.queue_free()
	await process_frame

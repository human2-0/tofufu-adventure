extends SceneTree
## Native inspection of tucked-away chests and the visible carried sack.

func _initialize() -> void: call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280, 720)
	var stage := Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("a6beb8")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("fff0d1")
	environment.environment.ambient_light_energy = 0.8
	stage.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -25, 0)
	stage.add_child(sun)
	var factory := TofuFactory.new()
	stage.add_child(factory)
	factory.ensure_interior()
	for legacy in factory._displays: legacy.visible = false
	for legacy in factory._bags: legacy.visible = false
	for legacy in factory._process_labels: legacy.visible = false
	var chests := FactoryHiddenChests.new()
	factory.add_child(chests)
	chests.present(0)
	var player: Player = load("res://game/player/player.tscn").instantiate()
	stage.add_child(player)
	player.set_physics_process(false)
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.current = true
	for index in 3:
		var at: Vector3 = FactoryHiddenChests.POSITIONS[index]
		player.relocate(at + Vector3(-1, 0, 1.7))
		camera.position = at + Vector3(-1.3, 2.0, 3)
		camera.look_at(at + Vector3(0, 0.65, 0))
		await capture("stash-%d-closed" % index)
		chests.present((1 << (index + 1)) - 1)
		for frame in 35: await process_frame
		await capture("stash-%d-open" % index)
	var at := TofuFactory.CENTERS[0]
	player.relocate(at + Vector3(0, 0.2, 4))
	var sack: Node3D
	for view in get_nodes_in_group("factory_production_visuals"):
		if (view as FactoryProductionVisuals).room == 0: sack = view.get_parent().get_node("sack_mature")
	FactoryCargoPose.apply(sack, 1, {1: {"position": player.global_position, "facing": Vector2.DOWN, "moving": true}}, 0.2)
	camera.position = player.global_position + Vector3(2.5, 2.0, 4)
	camera.look_at(player.global_position + Vector3.UP * 0.75)
	await capture("carried-sack")
	stage.queue_free()
	for frame in 5:
		await physics_frame
		await process_frame
	print("Factory detail render: PASS")
	quit()

func capture(id: String) -> void:
	for frame in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-details-%s.png" % id)

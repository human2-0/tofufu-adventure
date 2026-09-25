extends SceneTree
## Rendered QA for the east entrance, production hall and original enemy art.

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	var scene: Node3D = load("res://game/app/main.tscn").instantiate()
	scene.play_opening = false
	root.add_child(scene)
	scene.hud.visible = false
	scene.player.set_physics_process(false)
	scene.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	scene.cycle.phase = 0.4
	scene.cycle._process(0)
	var camera: Camera3D = scene.camera
	camera.set_physics_process(false)
	camera.position = Vector3(132, 20, 29)
	camera.look_at(Vector3(158, 3, 6))
	await _save("/tmp/tofufu-factory-exterior.png")
	scene.factory_dungeon._enter()
	scene.factory_dungeon._physics_process(0.016)
	scene.factory_dungeon.set_physics_process(false)
	for stage in [0, 3, 4, 5]:
		var center := TofuFactory.CENTERS[stage]
		scene.player.relocate(center + Vector3(0, 0.2, 6))
		if stage != 0:
			for gate in stage: scene.world.tofu_factory.open_gate(gate)
			scene.factory_dungeon.state.stage = stage
			scene.factory_dungeon._spawn_stage()
		camera.position = center + Vector3(0, 13, 16)
		camera.look_at(center + Vector3.UP)
		await _save("/tmp/tofufu-factory-stage-%d.png" % stage)
	scene.factory_dungeon.set_process(false)
	camera.position = Vector3(324,58,-150)
	camera.look_at(Vector3(324,1,-193))
	await _save("/tmp/tofufu-factory-layout.png")
	scene.world.tofu_factory.set_cutaway(false)
	camera.position = TofuFactory.CENTERS[3] + Vector3(0,1.6,4)
	camera.look_at(TofuFactory.station(3) + Vector3.UP * 1.5)
	await _save("/tmp/tofufu-factory-enclosed.png")
	print("Tofu Factory previews saved to /tmp")
	quit()

func _save(path: String) -> void:
	for frame in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

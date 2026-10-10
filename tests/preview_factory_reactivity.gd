extends SceneTree
## Native render evidence of local interaction feedback, without a saved adventure.

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
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
	sun.light_energy = 1.2
	stage.add_child(sun)
	var factory := TofuFactory.new()
	stage.add_child(factory)
	factory.ensure_interior()
	for old in factory._displays: old.visible = false
	for old in factory._bags: old.visible = false
	for old in factory._process_labels: old.visible = false
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.current = true
	var attempt := TofuDungeonAttempt.new()
	attempt.configure(35, 1, 14)
	var snapshot: Dictionary = attempt.capture(true)
	FactoryProductionVisuals.present_factory(factory, snapshot)
	await process_frame
	camera.position = Vector3(298, 4.8, -172)
	camera.look_at(Vector3(300, 0.9, -179))
	snapshot.sorting.carried_by = {"sack_mature": 1}
	snapshot.sorting.revision += 1
	FactoryProductionVisuals.present_factory(factory, snapshot)
	await _save("sorting-pickup")
	snapshot.sorting.carried_by = {}
	snapshot.sorting.assignments = {"sack_mature": "intake_tofu"}
	snapshot.sorting.revision += 1
	FactoryProductionVisuals.present_factory(factory, snapshot)
	camera.position = Vector3(301.5, 3.1, -181.2)
	camera.look_at(Vector3(300, 1.1, -185))
	await _save("intake-load")
	snapshot.lab.opening_cleared = true
	snapshot.lab.carried_bottle = "container_00"
	snapshot.lab.carrier_id = 1
	snapshot.lab.revision += 1
	FactoryProductionVisuals.present_factory(factory, snapshot)
	snapshot.lab.carried_bottle = ""
	snapshot.lab.carrier_id = 0
	snapshot.lab.complete = true
	snapshot.lab.revision += 1
	FactoryProductionVisuals.present_factory(factory, snapshot)
	camera.position = Vector3(325, 3.0, -179.7)
	camera.look_at(Vector3(327, 1.0, -183))
	await _save("coagulation-pour")
	snapshot.press.active_sample = 2
	snapshot.press.lease_actor = 1
	snapshot.press.revision += 1
	FactoryProductionVisuals.present_factory(factory, snapshot, {}, {"active_sample": 2, "gauge": 86.0, "elapsed": 6.88})
	camera.position = Vector3(347, 2.6, -181)
	camera.look_at(Vector3(349, 1.2, -185))
	await _save("pressure-release")
	snapshot.pack.slot_slabs[0] = 0
	snapshot.pack.slot_slabs[1] = 1
	snapshot.pack.revision += 1
	FactoryProductionVisuals.present_factory(factory, snapshot)
	snapshot.pack.sealed[0] = true
	snapshot.pack.sealed[1] = true
	snapshot.pack.revision += 1
	FactoryProductionVisuals.present_factory(factory, snapshot)
	camera.position = Vector3(315.5, 7.0, -209)
	camera.look_at(Vector3(317, 5.5, -213))
	await _save("packaging-seal")
	print("Factory reactivity previews: saved /tmp/tofufu-reactive-*.png")
	stage.queue_free()
	await process_frame
	await process_frame
	quit()

func _save(title: String) -> void:
	for frame in 12: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-reactive-%s.png" % title)
	print("%s: %.0f draw calls, %.2f ms process monitor" % [title, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0])

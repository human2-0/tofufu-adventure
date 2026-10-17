extends SceneTree
## Render the real model in both states, then its nursery placement at player scale.

func _initialize() -> void:
	if "--polish" in OS.get_cmdline_user_args():
		TranslationServer.set_locale("pl")
		GamePreferences.install_translations(self)
	call_deferred("run")

func save(path: String) -> void:
	for i in 12: await process_frame
	await RenderingServer.frame_post_draw
	if "--polish" in OS.get_cmdline_user_args(): path = path.trim_suffix(".png") + "-pl.png"
	root.get_texture().get_image().save_png(path)

func run() -> void:
	root.size = Vector2i(1440, 900)
	var scene := Node3D.new()
	root.add_child(scene)
	var sky := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("c7d9d6")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("f3f0d8")
	environment.ambient_light_energy = 0.65
	sky.environment = environment
	scene.add_child(sky)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -25, 0)
	light.shadow_enabled = true
	scene.add_child(light)
	var plane := PlaneMesh.new()
	plane.size = Vector2(30, 30)
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("69856b")
	SoySaveSpotGeometry.mesh(scene, plane, Vector3(0, -0.01, 0), Vector3.ONE, floor_material)
	for i in 2:
		var plant: SoySaveSpot = load("res://game/world/common/soy_save_spot.tscn").instantiate()
		plant.position.x = -1.7 if i == 0 else 1.7
		plant.title = "Nursery Roots" if i == 0 else "Fufufarm Village"
		scene.add_child(plant)
		plant.present(i == 1, true, "E")
	var camera := Camera3D.new()
	camera.position = Vector3(5.3, 4.7, 9)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 8
	camera.current = true
	scene.add_child(camera)
	camera.look_at(Vector3(0, 1.3, 0))
	await save("/tmp/tofufu-soy-save-spots-states.png")
	if "--model-only" in OS.get_cmdline_user_args():
		quit()
		return
	scene.queue_free()
	await process_frame
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	for i in 5: await physics_frame
	game.player.relocate(game.soy_spots.spots[0].position + Vector3(1.3, 0.1, 1.3))
	game.player.set_physics_process(false)
	game.camera.set_process(false)
	game.camera.set_physics_process(false)
	game.camera.position = game.soy_spots.spots[0].position + Vector3(5, 4.5, 7)
	game.camera.look_at(game.soy_spots.spots[0].position + Vector3.UP)
	game.world_items.set_process(false)
	game.world_items.focused_kind = "soy_spot"
	game.world_items.focused_plot = 0
	game.soy_spots._process(0)
	await save("/tmp/tofufu-soy-save-spots-nursery.png")
	game.soy_spots.ownership.claim(0)
	await save("/tmp/tofufu-soy-save-spots-owned.png")
	for index in range(1, game.soy_spots.spots.size()):
		var spot := game.soy_spots.spots[index]
		game.player.relocate(spot.position + Vector3(0, 0.1, 1.6))
		game.camera.position = spot.position + Vector3(5, 4.5, 7)
		game.camera.look_at(spot.position + Vector3.UP)
		game.world_items.focused_plot = index
		await save("/tmp/tofufu-soy-save-spots-%s.png" % SoySaveSpotSites.IDS[index])
	game.queue_free()
	await process_frame
	print("Soybean save spot renderer previews: /tmp/tofufu-soy-save-spots-*.png")
	quit()

extends SceneTree
## GPU checks: nearby text, distance culling, solid walls and visible openings.

var failures: int = 0
var results: Array[Dictionary] = []

func _initialize() -> void: call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("World text visibility requires a rendered viewport.")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	root.gui_disable_input = true
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 60
	var scene := Node3D.new()
	root.add_child(scene)
	var camera := Camera3D.new()
	scene.add_child(camera)
	camera.position = Vector3(0, 1.8, 8)
	var label := MobLabels.make(scene, "ARMORED SNAIL", 48, 0.012, Color("ff00ff"), 1.8)
	var wall := MeadowGeometry.box(scene, Vector3(0, 1.8, 4), Vector3(8, 6, 0.4), Color("343434"))
	wall.visible = false
	for case in ["near", "far_control", "far", "wall", "opening", "return"]:
		camera.position.z = 50 if case in ["far_control", "far"] else 8
		label.visibility_range_end = 0 if case == "far_control" else 32
		wall.visible = case in ["wall", "opening"]
		wall.position.x = 8 if case == "opening" else 0
		for frame in 6: await process_frame
		await RenderingServer.frame_post_draw
		var capture := root.get_texture().get_image()
		capture.save_png("/tmp/tofufu-world-text-%s.png" % case)
		var pixels := _text_pixels(capture)
		var expected: bool = case not in ["far", "wall"]
		var visible: bool = pixels > (0 if case == "far_control" else 100)
		if not (visible if expected else pixels == 0):
			printerr("FAIL: ", case, " label visibility, pink pixels=", pixels)
			failures += 1
		results.append({"case": case, "text_pixels": pixels, "expected_visible": expected})
	scene.queue_free()
	await process_frame
	if "--probe-only" not in OS.get_cmdline_user_args(): await _world_views()
	FileAccess.open("/tmp/tofufu-world-text.json", FileAccess.WRITE).store_string(JSON.stringify(results, "\t"))
	print("World text visibility: ", "PASS" if failures == 0 else "FAIL", " ", JSON.stringify(results))
	quit(failures)

func _text_pixels(capture: Image) -> int:
	var count := 0
	for y in capture.get_height():
		for x in capture.get_width():
			var color := capture.get_pixel(x, y)
			if color.r > 0.6 and color.b > 0.6 and color.g < 0.3: count += 1
	return count

func _world_views() -> void:
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.process_mode = Node.PROCESS_MODE_DISABLED
	game.cycle.phase = 0.43
	game.cycle._process(0)
	game.weather.set_phase(0.05)
	var snail := ArmoredSnail.new()
	snail.position = game.world.ground_point(34, -68, 0.1)
	snail.quarry = game.player
	game.encounters.add_child(snail)
	_audit(game)
	for case in [
		{"name": "village", "at": game.world.ground_point(46, -29, 0.1), "mode": 0},
		{"name": "snails", "at": game.world.ground_point(34, -63, 0.1), "mode": 1},
		{"name": "castle", "at": Vector3(316, 4.5, 355), "mode": 2}]:
		game.player.relocate(case.at)
		while (2 if game.shooting_view.first_person else (1 if game.shooting_view.shoulder else 0)) != case.mode:
			game.shooting_view.cycle_mode()
		game.camera.yaw = 0
		game.camera.pitch = 0.12
		game.camera.reset_follow()
		game.camera._follow(1)
		game.world.volcanic.castle.present(game.player.position, case.mode == 0)
		for node in game.get_children():
			if node is MeadowInteriorView: node._process(0)
		for frame in 6: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/tofufu-world-text-%s.png" % case.name)
	game.queue_free()
	await process_frame
	await process_frame

func _audit(node: Node) -> void:
	if node is Label3D:
		var label := node as Label3D
		if label.visibility_range_end <= 0 or label.no_depth_test or label.ignore_occlusion_culling:
			printerr("FAIL: unbounded or through-wall world label: ", label.get_path())
			failures += 1
	for child in node.get_children(): _audit(child)

extends SceneTree
## Real camera orbit selects front, back, side and diagonal art with stable foot anchors.

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if ok: return
	failures += 1
	printerr("FAIL: ", message)

func _run() -> void:
	var king := LavaKing.new()
	root.add_child(king)
	king.set_process(false)
	king.sprite.set_process(false)
	var camera := Camera3D.new()
	root.add_child(camera)
	# Camera on the west sees E; orbit south then east then north around the king.
	for direction in 8:
		var angle := direction * PI / 4.0
		camera.position = Vector3(-cos(angle) * 12, 6, sin(angle) * 12)
		camera.look_at(Vector3(0, 2, 0))
		king.sprite.update_view(camera)
		var art := king.sprite
		check(art.current_direction == direction, "camera orbit chooses angle %d" % direction)
		check(art.current_cell == LavaKingArt.CELLS[direction], "angle uses its authored view")
		check(art.flip_h == (direction in [3, 4, 5]), "only western views mirror")
		var frame := art.texture as AtlasTexture
		check(frame.atlas == LavaKingArt.TEXTURES[art.current_cell], "atlas points to the expected PNG")
		var bounds := LavaKingArt.BOUNDS[art.current_cell]
		check(is_equal_approx(art.pixel_size * bounds.size.y, LavaKingArt.HEIGHT), "every view has the same apparent height")
		var foot_y := art.offset.y - (frame.region.size.y * 0.5 - 8)
		check(absf(foot_y * art.pixel_size - 0.05) < 0.001, "feet share the plaza baseline")
		var foot_x := frame.region.get_center().x - LavaKingArt.FOOT_X[art.current_cell]
		if art.flip_h: foot_x = -foot_x
		check(is_equal_approx(art.offset.x, foot_x), "mirrored foot anchor stays centered")
	# Follow cameras translate without yawing; the king still needs the observer's side view.
	camera.position = Vector3(-12, 6, 0)
	king.sprite.update_view(camera)
	check(king.sprite.current_direction == 0, "fixed-orientation observer on west sees right-facing side")
	camera.position = Vector3(12, 6, 0)
	king.sprite.update_view(camera)
	check(king.sprite.current_direction == 4, "translating the same camera east changes the side view")
	var solid_count := 0
	for child in king.get_children():
		if child is StaticBody3D: solid_count += 1
	check(solid_count == 1, "directional presentation retains the king collider")
	king.rotation.y = PI
	camera.position = Vector3(0, 6, 12)
	camera.look_at(Vector3(0, 2, 0))
	king.sprite.update_view(camera)
	check(king.sprite.current_cell == 0, "authored king rotation turns the rear toward the camera")
	check(not king.greeting.visible, "directional art retains greeting visibility state")
	king.queue_free()
	camera.queue_free()
	await process_frame
	print("King Lava directional art: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

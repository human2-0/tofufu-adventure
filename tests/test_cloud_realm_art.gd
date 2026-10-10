extends SceneTree
## Imported atlas crops, ground pivots, observer-facing views and angel wing poses.

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if ok: return
	failures += 1
	printerr("FAIL: ", message)

func _run() -> void:
	for key: String in CloudSpriteCatalog.ART:
		var art := CloudResidentArt.new()
		art.asset = key
		root.add_child(art)
		art.set_process(false)
		var entry := CloudSpriteCatalog.entry(key)
		var sheet: Texture2D = entry.sheet
		var image := sheet.get_image()
		check(image != null and image.detect_alpha() != Image.ALPHA_NONE, key + " keeps a transparent background")
		check(entry.bounds.size() == (10 if key == "angel" else 5), key + " contains every authored direction")
		for direction in 8:
			art.present_direction(direction)
			var frame := art.texture as AtlasTexture
			var cell := CloudResidentArt.CELLS[direction]
			check(frame != null and frame.atlas == sheet, key + " uses its own imported atlas")
			check(art.flip_h == ((direction in [3, 4, 5]) != (cell in entry.flip_cells)), key + " mirrors western views")
			var bounds: Rect2 = entry.bounds[cell]
			check(Rect2(Vector2.ZERO, sheet.get_size()).encloses(frame.region), key + " crop stays inside source margins")
			check(is_equal_approx(art.pixel_size * bounds.size.y, art.height), key + " has calibrated apparent height")
			var anchor: Vector2 = entry.anchors[cell]
			check(absf((art.offset.y + frame.region.get_center().y - anchor.y) * art.pixel_size - 0.04) < 0.001, key + " keeps feet above the floor")
			var horizontal := frame.region.get_center().x - anchor.x
			check(is_equal_approx(art.offset.x, -horizontal if art.flip_h else horizontal), key + " preserves horizontal sole pivots when mirrored")
			for other: Rect2 in entry.bounds:
				if other == bounds: continue
				check(not frame.region.intersects(other), key + " excludes neighbouring figure fragments")
		var camera := Camera3D.new()
		root.add_child(camera)
		camera.position = Vector3(0, 5, 10)
		art.update_view(camera)
		check(art.current_cell == 4, key + " shows its front from the south")
		camera.position.z = -10
		art.update_view(camera)
		check(art.current_cell == 0, key + " shows its back from the north")
		var visitor := Node3D.new()
		visitor.position = Vector3(0, 0, -2)
		root.add_child(visitor)
		art.view_focus = visitor
		art.update_view(camera)
		check(art.current_cell == 4, key + " turns toward a nearby visitor")
		if key == "angel":
			art.elapsed = 0
			art.present_direction(2)
			var raised: Texture2D = art.texture
			var size := art.pixel_size
			art.elapsed = 0.21
			art.present_direction(2)
			check(art.texture != raised and art.current_pose == 1, "angels alternate both authored wing poses")
			check(art.pixel_size == size, "angel wing motion does not rescale the body")
		visitor.free()
		camera.free()
		art.free()
	print("Cloud Realm art: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

extends SceneTree
## Independent alpha silhouette measurements and actual camera-relative intent.
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.current = true
	var sprite := FufuVisuals.new()
	stage.add_child(sprite)
	for id: String in TofufuTestArt.IDS:
		sprite.set_test_skin(id)
		for category: String in ["locomotion", "jump", "melee"]:
			var image := Image.load_from_file(TofufuTestArt.ROOT + id + "/" + category + ".png")
			var columns := 5 if category == "locomotion" else (10 if category == "jump" else 4)
			for facing in 8:
				sprite.current_facing = facing as FufuVisuals.Facing
				for phase in columns:
					sprite.test_skin.apply(sprite, category, phase)
					var data: Dictionary = sprite.test_skin._layout.sheets[category][TofufuTestArt.ROWS[facing] * columns + phase]
					var center := _torso_center(image, data)
					var atlas := sprite.texture as AtlasTexture
					if sprite.flip_h: center = atlas.region.size.x - center
					var at := (center - atlas.region.size.x * 0.5 + sprite.offset.x) * sprite.pixel_size
					check(absf(at) < 0.006, "%s %s %d %d torso stays over the capsule" % [id, category, facing, phase])
		for yaw in [0.0, 0.85, PI * 0.5]:
			camera.position = Vector3(sin(yaw) * 7, 4, cos(yaw) * 7)
			camera.look_at(Vector3.ZERO)
			for facing in 8:
				var screen := Vector2.from_angle(facing * PI / 4)
				var back := Vector2(camera.global_basis.z.x, camera.global_basis.z.z).normalized()
				var right := Vector2(camera.global_basis.x.x, camera.global_basis.x.z).normalized()
				var travel := right * screen.x + back * screen.y
				var command := BattleInputBuffer.decode([travel.x, travel.y, -travel.x, -travel.y, 0])
				sprite.jump_animation.reset()
				sprite.present(command, Vector3(travel.x, 0, travel.y) * 4, true, false, 0)
				check(int(sprite.current_facing) == facing, "ordinary battle walking faces chosen travel through camera rotation")
				var data: Dictionary = sprite.test_skin._layout.sheets.locomotion[TofufuTestArt.ROWS[facing] * 5 + 1]
				check(data.direction == ["w", "sw", "s", "sw", "w", "nw", "n", "nw"][facing], "selected source angle matches screen direction")
				command.attack_held = true
				sprite.present(command, Vector3(travel.x, 0, travel.y) * 4, true, false, 0)
				check(int(sprite.current_facing) == (facing + 4) % 8, "held fire still faces aim independently of travel")
	stage.queue_free()
	await process_frame
	print("Tofufu torso anchors and directions: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _torso_center(image: Image, data: Dictionary) -> float:
	var region: Array = data.region
	var bounds: Array = data.painted_bounds
	var top := int(region[1] + bounds[1] + int(float(bounds[3]) * 0.32))
	var bottom := int(region[1] + bounds[1] + int(float(bounds[3]) * 0.62))
	var longest := Vector2i.ZERO
	var start := -1
	for x in range(int(region[0] + bounds[0]), int(region[0] + bounds[0] + bounds[2]) + 1):
		var count := 0
		if x < int(region[0] + bounds[0] + bounds[2]):
			for y in range(top, bottom):
				if image.get_pixel(x, y).a >= 0.5: count += 1
		var solid := float(count) / (bottom - top) >= 0.8
		if solid and start < 0: start = x
		if not solid and start >= 0:
			if x - start > longest.y - longest.x: longest = Vector2i(start, x)
			start = -1
	return (longest.x + longest.y - 1) * 0.5 - float(region[0])

extends SceneTree
## Geometry/collision preservation and validated local rendering preferences.
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in [0.0, 48.0]:
		for offset: Vector3 in [Vector3.ZERO, Vector3.RIGHT, Vector3.BACK]:
			surface.set_color(Color.GREEN)
			surface.set_normal(Vector3.UP)
			surface.add_vertex(Vector3(x, 0, 0) + offset)
	var ground := MeshInstance3D.new()
	ground.mesh = surface.commit()
	ground.material_override = StandardMaterial3D.new()
	root.add_child(ground)
	ground.create_trimesh_collision()
	var body := ground.get_child(0) as StaticBody3D
	var shape := body.get_child(0) as CollisionShape3D
	var collision := shape.shape
	TerrainChunks.split_visual(ground, true)
	check(ground.mesh == null and ground.get_child_count() == 3, "two separate visual tiles replace one broad mesh")
	check(shape.shape == collision and body.collision_layer == 1, "terrain retains its original physical surface")
	var triangles := 0
	for node in ground.get_children():
		if node is not MeshInstance3D: continue
		var tile := node as MeshInstance3D
		triangles += tile.mesh.surface_get_array_index_len(0) / 3
		check(tile.material_override == ground.material_override, "tile retains the authored material")
		check(tile.mesh.get_aabb().size.x < 2, "each tile has independently bounded geometry")
	check(triangles == 2, "tiling preserves all triangles")
	var grid := TerrainGrid.new(Rect2i(0, 0, 2, 2), func(x: float, z: float) -> float: return x + z, 1)
	check(is_equal_approx(grid.interpolated_height(Vector2(0.25, 1.25)), 1.5), "wildlife smoothly samples the cached seabed")
	var prefs := GamePreferences.new()
	prefs.path = "user://test_render_budget_%d.cfg" % Time.get_ticks_usec()
	prefs.apply_rendering(root, 120, 0.85)
	check(prefs.save() == OK, "frame cap and 3D scale save")
	var restored := GamePreferences.new()
	restored.path = prefs.path
	restored.load_preferences()
	check(restored.frame_limit == 120 and restored.render_scale == 0.85, "rendering preferences survive restart")
	prefs.apply_rendering(root, -1, NAN)
	check(prefs.frame_limit == 120 and prefs.render_scale == 1.0 and Engine.max_fps == 120, "invalid rendering values fall back to the native 120 FPS target")
	DirAccess.remove_absolute(prefs.path)
	ground.queue_free()
	await process_frame
	print("Render budget: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

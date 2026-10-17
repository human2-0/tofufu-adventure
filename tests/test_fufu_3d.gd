extends SceneTree
## Imported material/volume, independent looping pivots and real village placement.

const DISPLAY := preload("res://game/world/farm/fufu_3d_display.tscn")
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if condition: return
	failures += 1
	printerr("FAIL: ", message)

func _run() -> void:
	var first := DISPLAY.instantiate() as Fufu3DDisplay
	var second := DISPLAY.instantiate() as Fufu3DDisplay
	second.walking = false
	root.add_child(first)
	root.add_child(second)
	check(first.animation.current_animation == "Walk", "village display starts its authored walk")
	check(second.animation.current_animation == "Idle", "another instance can idle independently")
	for clip in ["Walk", "Idle"]:
		check(first.animation.has_animation(clip), "portable model imports " + clip)
		check(first.animation.get_animation(clip).loop_mode == Animation.LOOP_LINEAR, clip + " loops")
	first.animation.pause()
	second.animation.pause()
	var model := first.get_node("Model/Fufu3D") as Node3D
	var body := model.get_node("BodyPivot/BeanBody") as MeshInstance3D
	var volume := body.mesh.get_aabb().size
	check(volume.x > 1.1 and volume.y > 1.35 and volume.z > .89, "Fufu is a plump oval bean with full depth")
	check(volume.x / volume.y > .78 and volume.x / volume.y < .90, "bean retains the reference's full oval silhouette")
	var skin_points: PackedVector3Array = body.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var upper := Vector2.ZERO
	var lower := Vector2.ZERO
	for point in skin_points:
		if point.y > 1.50: upper += Vector2(point.x, 1)
		if point.y < .20: lower += Vector2(point.x, 1)
	var bend := upper.x / upper.y - lower.x / lower.y
	check(bend > .04 and bend < .12, "bean crown has a restrained curve above its full lower belly")
	var meshes: Array[MeshInstance3D] = []
	_collect(model, meshes)
	check(meshes.size() >= 15, "authored sprout, eyes, cheeks, hands, feet and ink import")
	for view in meshes:
		for surface in view.mesh.get_surface_count():
			var material := view.mesh.surface_get_material(surface) as StandardMaterial3D
			check(material != null and material.albedo_texture != null, "generated texture applied to " + str(view.name))
		check(view.visibility_range_end == 48.0, "village study keeps a bounded draw distance")
		if str(view.name) in Fufu3DDisplay.PAINTED_MARKS:
			check(view.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "painted face marks do not cast sticker-like shadows")
	var right_foot := model.get_node("RightFootPivot") as Node3D
	var left_foot := model.get_node("LeftFootPivot") as Node3D
	var right_shoulder := model.get_node("BodyPivot/RightShoulder") as Node3D
	var sprout := model.get_node("BodyPivot/SproutPivot") as Node3D
	first.animation.seek(1.25 * .25, true)
	var right_height := right_foot.position.y
	var sprout_angle := sprout.rotation.z
	check(right_height > left_foot.position.y + .05, "one foot lifts while the other supports the body")
	check(absf(right_shoulder.rotation.x) > .05 and absf(sprout_angle) > .03, "walk lightly swings hands and sprout")
	first.animation.seek(1.25 * .75, true)
	check(left_foot.position.y > right_foot.position.y + .05, "opposite half-cycle exchanges the support foot")
	check(sprout.rotation.z * sprout_angle < 0, "sprout sways across the walking cycle")
	check(is_zero_approx((second.get_node("Model/Fufu3D/BodyPivot/RightShoulder") as Node3D).rotation.x), "animation never changes another instance")
	for index in 33:
		first.animation.seek(index * 1.25 / 32, true)
		for foot in [right_foot, left_foot]:
			var mesh := foot.get_child(0) as MeshInstance3D
			var points: PackedVector3Array = mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			for point in points:
				check((foot.transform * point).y > -0.003, "animated foot stays above the display surface")
	first.queue_free()
	second.queue_free()
	await process_frame
	var village := preload("res://game/world/farm/meadow.tscn").instantiate() as Meadow
	root.add_child(village)
	await physics_frame
	var display := village.get_node("Fufu3DDisplay") as Fufu3DDisplay
	var at := MeadowVillage.FUFU_STUDY
	check(display != null, "real village contains the animated study after scenery batching")
	check(display.position.is_equal_approx(village.ground_point(at.x, at.y)), "display uses the shared terrain height")
	check(not MeadowVillageGround.lawn(at), "grass cannot grow through the display base")
	for index in 8:
		var edge := at + Vector2.from_angle(index * TAU / 8) * 1.2
		check(not MeadowGrass.habitat(village.terrain, edge.x, edge.y), "display clearing allows for wind-bent grass")
	check(MeadowVillageGround.path_distance(at) > 2.0, "display leaves the courtyard footpath clear")
	var shape := display.get_node("DisplayBody/CollisionShape3D") as CollisionShape3D
	check(shape.shape is CylinderShape3D, "small base retains its physical support")
	var from := display.global_position + Vector3(0, 1, 0)
	var to := display.global_position + Vector3(0, -.1, 0)
	var hit := village.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, 1))
	check(not hit.is_empty() and hit.get("collider") == shape.get_parent(), "display base matches its visible top")
	village.queue_free()
	await process_frame
	if failures == 0: print("Fufu 3D display: PASS")
	quit(1 if failures else 0)

func _collect(parent: Node, result: Array[MeshInstance3D]) -> void:
	for child in parent.get_children():
		if child is MeshInstance3D: result.append(child)
		_collect(child, result)

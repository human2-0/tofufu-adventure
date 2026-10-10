extends SceneTree
## Surface batching must preserve textures; shared meshes retain per-actor feedback.

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if value: return
	failures += 1
	printerr("FAIL: ", message)

func triangles(mesh: Mesh) -> int:
	var total := 0
	for index in mesh.get_surface_count(): total += mesh.surface_get_array_index_len(index) / 3
	return total

func _run() -> void:
	var ornaments := Node3D.new()
	root.add_child(ornaments)
	for kind in ["brick", "timber", "roof", "concrete"]:
		var view := MeadowGeometry.box(ornaments, Vector3(1, 1, 1), Vector3.ONE, Color.WHITE)
		MeadowSurfaces.apply(view, kind)
		check(view.material_override.uv1_world_triplanar, "texture scale uses stable world coordinates through batching")
	StaticDecorationBatch.build(ornaments)
	check(ornaments.get_child_count() == 4, "equal tint with four different textures remains four surfaces after batching")
	var types: Array[String] = []
	for view: MeshInstance3D in ornaments.get_children():
		var material := view.mesh.surface_get_material(0)
		types.append(material.get_meta("meadow_surface"))
		check(material.albedo_texture != null and material.albedo_texture.get_width() >= 1024, "baked surface retains imported texture")
		check(material.albedo_texture.get_image().has_mipmaps(), "painted surfaces retain mipmaps for distant buildings")
		check(triangles(view.mesh) == 12, "texturing retains exact box geometry")
	check(types.size() == 4 and "brick" in types and "concrete" in types, "batch keeps every distinct material role")
	var a := ArmoredSnailVisuals.new()
	var b := ArmoredSnailVisuals.new()
	root.add_child(a)
	root.add_child(b)
	var armor_a := a._shell.get_child(0) as MeshInstance3D
	var armor_b := b._shell.get_child(0) as MeshInstance3D
	check(armor_a.mesh == armor_b.mesh and armor_a.material_override != armor_b.material_override, "snails share immutable armor mesh but own feedback material")
	check(triangles(armor_a.mesh) <= 4096, "plate and spiral detail stay within bounded triangle budget")
	var bounds := armor_a.mesh.get_aabb()
	check(bounds.size.x <= 1.30 and bounds.size.y <= 1.10 and bounds.size.z <= 1.30, "new armor remains within original shell envelope")
	check(bounds.size.y >= 1.0, "lower shell lining covers the original dome rather than leaving exposed protected body")
	a.set_shell_health(20)
	a.present(Vector3.ZERO, Vector3.BACK, 0, 0, 0.25)
	check(armor_a.material_override.albedo_color != armor_b.material_override.albedo_color, "damage patina stays local to damaged snail")
	a.set_shell_health(0)
	check(not a._shell.visible and b._shell.visible, "broken armor disappears without affecting another snail")
	var bee_a := BeeVisuals.new()
	var bee_b := BeeVisuals.new()
	root.add_child(bee_a)
	root.add_child(bee_b)
	var body_a := bee_a._body.get_node("ShapedStripedBody") as MeshInstance3D
	var body_b := bee_b._body.get_node("ShapedStripedBody") as MeshInstance3D
	check(body_a.mesh == body_b.mesh and body_a.material_override != body_b.material_override, "bees share organic mesh while keeping individual warning state")
	check(triangles(body_a.mesh) <= 1500 and triangles(BeeMesh.wing()) <= 180, "bee body and wing meshes stay bounded")
	var original := bee_a._wings[0].rotation.z
	bee_a.present(Vector3.RIGHT, 0.7, 0.03)
	check(bee_a._wings[0].rotation.z != original, "veined wings retain animated beating")
	check(body_a.material_override.emission_enabled and not body_b.material_override.emission_enabled, "attack warning affects only attacking bee")
	for node in [ornaments, a, b, bee_a, bee_b]: node.queue_free()
	for i in 3: await process_frame
	await create_timer(0.1).timeout
	print("Meadow meshes: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

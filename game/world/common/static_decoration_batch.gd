class_name StaticDecorationBatch
extends RefCounted
## Bake plain immutable ornaments into local tiles; scripted views/colliders stay intact.

const TILE_SIZE: float = 16.0

static func build(root: Node3D) -> void:
	var groups: Dictionary[String, Dictionary] = {}
	_collect(root, root, groups)
	for key: String in groups:
		var group := groups[key]
		var surface: SurfaceTool = group.surface
		surface.set_material(DecorationMeshBake.material(group.material))
		surface.index()
		var view := MeshInstance3D.new()
		view.name = "StaticOrnaments_" + key
		view.position = group.origin
		view.mesh = surface.commit()
		view.cast_shadow = group.shadow
		view.layers = group.layers
		root.add_child(view)

static func _collect(parent: Node3D, root: Node3D, groups: Dictionary[String, Dictionary]) -> void:
	for child in parent.get_children():
		if not child is Node3D or child.get_script() != null: continue
		var node := child as Node3D
		if node is MeshInstance3D and _eligible(node):
			_append(node, root, groups)
		elif not node is GeometryInstance3D and not node is CollisionObject3D:
			_collect(node, root, groups)

static func _eligible(view: MeshInstance3D) -> bool:
	if view.get_meta("cutaway_ornament", false): return false
	# Named views may be referenced by presentation even without their own script.
	if not str(view.name).begins_with("@") and view.name != "MeshInstance3D": return false
	if view.mesh == null or view.mesh.get_surface_count() != 1 or not _static_children(view): return false
	if not view.visible or view.material_overlay != null or view.visibility_range_end > 0 or view.visibility_range_begin > 0: return false
	if view.mesh is not PrimitiveMesh and not (view.mesh is ArrayMesh and view.get_meta("static_ornament_mesh", false)): return false
	var material := view.material_override if view.material_override != null else view.mesh.surface_get_material(0)
	if not material is StandardMaterial3D or not material.get_meta("static_meadow_ornament", false): return false
	if material.next_pass != null and material.next_pass != DecorationMeshBake.INK: return false
	if material.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED or material.grow: return false
	if material.uv1_triplanar and not material.uv1_world_triplanar: return false
	if material.uv2_triplanar and not material.uv2_world_triplanar: return false
	return material.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and absf(view.global_basis.determinant()) > 0.000001

static func _static_children(view: MeshInstance3D) -> bool:
	for body in view.get_children():
		if not body is StaticBody3D or body.get_script() != null: return false
		for shape in body.get_children():
			if not shape is CollisionShape3D or shape.get_script() != null: return false
	return true

static func _append(view: MeshInstance3D, root: Node3D, groups: Dictionary[String, Dictionary]) -> void:
	var pose := root.global_transform.affine_inverse() * view.global_transform
	var tile := Vector2i(floori(pose.origin.x / TILE_SIZE), floori(pose.origin.z / TILE_SIZE))
	var material := view.material_override if view.material_override != null else view.mesh.surface_get_material(0)
	var key := "%d_%d_%s_%d_%d" % [tile.x, tile.y, _material_signature(material), view.cast_shadow, view.layers]
	var origin := Vector3(tile.x * TILE_SIZE, 0, tile.y * TILE_SIZE)
	if not groups.has(key):
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		surface.set_custom_format(0, SurfaceTool.CUSTOM_RGBA_FLOAT)
		groups[key] = {"surface": surface, "material": material, "origin": origin, "shadow": view.cast_shadow, "layers": view.layers}
	pose.origin -= origin
	DecorationMeshBake.append(groups[key].surface, view.mesh, pose)
	if view.get_child_count() > 0:
		# Keep the original collider parent and transform, just as terrain tiles do.
		view.mesh = null
	else:
		view.get_parent().remove_child(view)
		view.free()

static func _material_signature(material: StandardMaterial3D) -> String:
	var values: Array = []
	for property in material.get_property_list():
		var key: String = property.name
		if not property.usage & PROPERTY_USAGE_STORAGE: continue
		if key.begins_with("resource_") or key.begins_with("metadata/"): continue
		values.append([key, material.get(key)])
	return str(values).sha256_text()

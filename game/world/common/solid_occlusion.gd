class_name SolidOcclusion
extends RefCounted
## Explicit opaque architecture only. Children follow visual cutaways and visibility.

static func box(view: MeshInstance3D) -> void:
	if not view.mesh is BoxMesh or view.has_node("SolidOcclusion"): return
	var size := (view.mesh as BoxMesh).size
	# Small trim is a poor occluder and adds CPU rasterization work.
	if maxf(size.x * size.y, maxf(size.x * size.z, size.y * size.z)) < 16.0: return
	if view.visibility_range_begin > 0.0 or view.visibility_range_end > 0.0: return
	var material := view.material_override if view.material_override != null else view.mesh.surface_get_material(0)
	if material == null: return
	if material is BaseMaterial3D and material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED: return
	var shape := BoxOccluder3D.new()
	shape.size = size * 0.98
	var occluder := OccluderInstance3D.new()
	occluder.name = "SolidOcclusion"
	occluder.occluder = shape
	view.add_child(occluder)

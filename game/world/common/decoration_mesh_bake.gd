class_name DecorationMeshBake
extends RefCounted
## Preserve lighting, UVs and authored ink extrusion when baking scaled ornaments.

const INK: ShaderMaterial = preload("res://game/world/common/ink_outline.tres")
const BAKED_INK: Shader = preload("res://game/world/common/decoration_outline.gdshader")

static func material(source: StandardMaterial3D) -> StandardMaterial3D:
	if source.next_pass == null: return source
	var result := source.duplicate() as StandardMaterial3D
	var outline := ShaderMaterial.new()
	outline.shader = BAKED_INK
	outline.set_shader_parameter("width", source.next_pass.get_shader_parameter("width"))
	result.next_pass = outline
	return result

static func append(surface: SurfaceTool, mesh: Mesh, pose: Transform3D) -> void:
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var normal_basis := pose.basis.inverse().transposed()
	var mirrored := pose.basis.determinant() < 0.0
	var count := indices.size() if not indices.is_empty() else vertices.size()
	for triangle in range(0, count, 3):
		for corner in 3:
			var offset := triangle + (2 - corner if mirrored else corner)
			var index := indices[offset] if not indices.is_empty() else offset
			_vertex(surface, arrays, index, pose, normal_basis, mirrored)

static func _vertex(surface: SurfaceTool, arrays: Array, index: int, pose: Transform3D, normal_basis: Basis, mirrored: bool) -> void:
	var normal: Vector3 = arrays[Mesh.ARRAY_NORMAL][index]
	surface.set_normal((normal_basis * normal).normalized())
	# The original outline extrudes in mesh space before the instance's scale.
	var ink_offset := pose.basis * normal
	surface.set_custom(0, Color(ink_offset.x, ink_offset.y, ink_offset.z, 0))
	var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT] if arrays[Mesh.ARRAY_TANGENT] != null else PackedFloat32Array()
	var tangent := Vector3.RIGHT
	var handedness := 1.0
	if not tangents.is_empty():
		tangent = Vector3(tangents[index * 4], tangents[index * 4 + 1], tangents[index * 4 + 2])
		handedness = tangents[index * 4 + 3]
	surface.set_tangent(Plane((pose.basis * tangent).normalized(), -handedness if mirrored else handedness))
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR] if arrays[Mesh.ARRAY_COLOR] != null else PackedColorArray()
	surface.set_color(colors[index] if not colors.is_empty() else Color.WHITE)
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] if arrays[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
	var uvs2: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2] if arrays[Mesh.ARRAY_TEX_UV2] != null else PackedVector2Array()
	surface.set_uv(uvs[index] if not uvs.is_empty() else Vector2.ZERO)
	surface.set_uv2(uvs2[index] if not uvs2.is_empty() else Vector2.ZERO)
	surface.add_vertex(pose * arrays[Mesh.ARRAY_VERTEX][index])

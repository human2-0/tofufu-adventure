class_name SwordTrail
extends MeshInstance3D
## Brief ribbon following the actual cutting blade; presentation only.

var _edges: Array[Vector3] = []
var _material: StandardMaterial3D

func _ready() -> void:
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.vertex_color_use_as_albedo = true
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED

func record(pose: Transform3D, tuning: CombatTuning, cutting: bool, heavy: bool, length: float = -1.0) -> void:
	visible = cutting
	if not cutting:
		_edges.clear()
		mesh = null
		return
	_edges.append(pose.origin)
	_edges.append(pose * Vector3(0, 0, -(tuning.blade_length if length < 0.0 else length)))
	while _edges.size() > 14:
		_edges.pop_front()
		_edges.pop_front()
	if _edges.size() < 4:
		return
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(_edges)
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for index in _edges.size():
		var tint := Color(1, 0.8, 0.35) if heavy else Color(0.8, 0.96, 1)
		tint.a = float(index) / _edges.size() * 0.35
		colors.append(tint)
	for index in range(0, _edges.size() - 2, 2):
		indices.append_array(PackedInt32Array([index, index + 1, index + 3, index, index + 3, index + 2]))
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var ribbon := ArrayMesh.new()
	ribbon.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	ribbon.surface_set_material(0, _material)
	mesh = ribbon

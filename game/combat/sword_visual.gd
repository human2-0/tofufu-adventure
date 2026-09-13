class_name SwordVisual
extends Node3D
## Calibrated 2D weapon art follows the same hand pose as the physical blade.
## Atlas pivots calibrate every view's actual steel base/tip to world blade size.

const ATLAS: Texture2D = preload("res://assets/weapons/sword/sword-eight-directions.png")
const GUARDS: Array[Vector2] = [Vector2(177,212), Vector2(635,226), Vector2(1109,246), Vector2(1573,226), Vector2(268,648), Vector2(697,611), Vector2(1108,604), Vector2(1520,608)]
const TIPS: Array[Vector2] = [Vector2(418,212), Vector2(807,86), Vector2(1109,61), Vector2(1410,86), Vector2(27,648), Vector2(520,762), Vector2(1108,816), Vector2(1698,762)]
const WIDTHS: Array[float] = [56, 53, 57, 53, 55, 53, 61, 53]
const GRIPS: Array[Vector2] = [Vector2(118,213), Vector2(588,268), Vector2(1109,301), Vector2(1619,265), Vector2(331,648), Vector2(739,575), Vector2(1108,550), Vector2(1475,570)]
var tuning: CombatTuning
var debug_visible: bool = false
var _debug: MeshInstance3D
var _sprite: MeshInstance3D
var _meshes: Array[ArrayMesh] = []
var _material: StandardMaterial3D
var _physical_pose: Transform3D
var _hand: Vector3
var _hand_plane: Basis
var _outward: float = 1.0
var _in_front: bool = false
var _attachment: float = 0.0
var _index: int = 0
var _has_hand: bool = false
var _has_pose: bool = false

func _ready() -> void:
	_material = StandardMaterial3D.new()
	_material.albedo_texture = ATLAS
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	_material.alpha_scissor_threshold = 0.35
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	for index in 8:
		_meshes.append(_build_view(index))
	_sprite = MeshInstance3D.new()
	_sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_sprite)
	_debug = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(tuning.blade_width, tuning.blade_thickness, tuning.blade_length)
	var tint := StandardMaterial3D.new()
	tint.albedo_color = Color(0.1, 1, 0.4, 0.3)
	tint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	box.material = tint
	_debug.mesh = box
	_debug.visible = false
	add_child(_debug)

func present(pose: Transform3D, aim: Vector2, charge: float, cutting: bool = false, attachment: float = 0.0) -> void:
	_index = SwordGeometry.direction_index(aim)
	_sprite.mesh = _meshes[_index]
	_physical_pose = pose
	_attachment = 0.0 if cutting else clampf(attachment, 0.0, 1.0)
	_has_pose = true
	_apply_pose()
	_debug.visible = debug_visible and cutting
	_debug.global_transform = SwordGeometry.blade_transform(pose, tuning)
	_material.albedo_color = Color(1, 0.83, 0.45) if charge >= 1.0 else Color.WHITE

func follow_hand(hand: Vector3, plane: Basis, outward: float, in_front: bool) -> void:
	_hand = hand
	_hand_plane = plane
	_outward = outward
	_in_front = in_front
	_has_hand = true
	if _has_pose:
		_apply_pose()

func _apply_pose() -> void:
	_sprite.global_transform = _physical_pose
	if not _has_hand or _attachment <= 0.0:
		return
	var blade := (_hand_plane.y + _hand_plane.x * _outward * 0.55).normalized()
	var width := blade.cross(_hand_plane.z).normalized()
	var basis := Basis(width, -blade.cross(width), -blade)
	# Front-facing hands hold the knife over the body; rear views hide overlap.
	var grip := _hand + _hand_plane.z * (0.035 if _in_front else -0.035)
	var held := Transform3D(basis, grip - basis * calibrated_vertex(GRIPS[_index], _index))
	_sprite.global_transform = _physical_pose.interpolate_with(held, _attachment)

func calibrated_vertex(pixel: Vector2, index: int) -> Vector3:
	var axis := (TIPS[index] - GUARDS[index]).normalized()
	var perpendicular := Vector2(-axis.y, axis.x)
	var offset := pixel - GUARDS[index]
	var along := offset.dot(axis) / GUARDS[index].distance_to(TIPS[index]) * tuning.blade_length
	var across := offset.dot(perpendicular) / WIDTHS[index] * tuning.blade_width
	return Vector3(across, 0, -along)

func _build_view(index: int) -> ArrayMesh:
	var size := Vector2(ATLAS.get_size())
	var cell := size / Vector2(4, 2)
	var origin := Vector2(index % 4, index / 4) * cell
	var corners: Array[Vector2] = [origin, origin + Vector2(cell.x, 0), origin + cell, origin + Vector2(0, cell.y)]
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	for corner in corners:
		vertices.append(calibrated_vertex(corner, index))
		uvs.append(corner / size)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, _material)
	return mesh

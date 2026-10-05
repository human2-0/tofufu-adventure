@tool
class_name NaturalTreeVisuals
extends RefCounted
## Shared broadleaf tree art, cached as bounded variants with two draw surfaces.

static var _variants: Dictionary[int, ArrayMesh] = {}
const FRUIT_ANCHORS: Array[Vector3] = [Vector3(-0.85, 2.07, 1.03), Vector3(-0.35, 2.48, 1.20), Vector3(0.4, 2.14, 1.2), Vector3(0.95, 2.46, 0.92)]

static func build(parent: Node3D, orchard: bool = false) -> MeshInstance3D:
	var variant := posmod(roundi(parent.position.x * 3.0 + parent.position.z * 7.0), 8)
	var key := variant + (8 if orchard else 0)
	if not _variants.has(key): _variants[key] = _build_mesh(variant, orchard)
	var view := MeshInstance3D.new()
	view.name = "NaturalCrown"
	view.mesh = _variants[key]
	view.extra_cull_margin = 0.05
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	TreeShadowMesh.build(parent)
	parent.add_child(view)
	return view

static func _build_mesh(variant: int, orchard: bool) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 94271 + variant * 139 + (483 if orchard else 0)
	var wood := SurfaceTool.new()
	var leaves := SurfaceTool.new()
	wood.begin(Mesh.PRIMITIVE_TRIANGLES)
	leaves.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bend := Vector3(rng.randf_range(-0.08, 0.08), 0, rng.randf_range(-0.08, 0.08))
	var fork := Vector3(0, 1.35, 0) + bend
	var leader := Vector3(0, 2.6, 0) + bend * 2.0
	TreeBranchMesh.add_segment(wood, Vector3.ZERO, fork, 0.32, 0.19)
	TreeBranchMesh.add_segment(wood, fork, leader, 0.19, 0.06)
	_add_roots(wood, rng)
	_add_limbs(wood, leaves, rng, fork, orchard)
	TreeLeafMesh.add_spray(leaves, rng, leader + Vector3.UP * 0.36, Vector3(0.57, 0.53, 0.58), orchard)
	TreeLeafMesh.add_spray(leaves, rng, leader + Vector3(-0.25, 0.15, 0.2), Vector3(0.55, 0.48, 0.55), orchard)
	if orchard: _add_fruit_spurs(wood, leaves, rng)
	return _commit(wood, leaves)

static func _add_fruit_spurs(wood: SurfaceTool, leaves: SurfaceTool, rng: RandomNumberGenerator) -> void:
	for anchor in FRUIT_ANCHORS:
		var tip := anchor + Vector3.UP * 0.22
		var start := Vector3(anchor.x * 0.45, anchor.y - 0.15, 0.5)
		TreeBranchMesh.add_segment(wood, start, tip, 0.045, 0.012)
		TreeLeafMesh.add_spray(leaves, rng, tip + Vector3(0, 0.12, -0.18), Vector3(0.30, 0.23, 0.28), true)

static func _add_roots(wood: SurfaceTool, rng: RandomNumberGenerator) -> void:
	for index in 5:
		var angle := TAU * index / 5.0 + rng.randf_range(-0.15, 0.15)
		var end := Vector3(cos(angle), 0, sin(angle)) * rng.randf_range(0.42, 0.63)
		end.y = 0.025
		TreeBranchMesh.add_segment(wood, Vector3(0, 0.22, 0), end, 0.13, 0.025)

static func _add_limbs(wood: SurfaceTool, leaves: SurfaceTool, rng: RandomNumberGenerator, fork: Vector3, orchard: bool) -> void:
	for index in 7:
		var angle := TAU * index / 7.0 + rng.randf_range(-0.2, 0.2)
		var radial := Vector3(cos(angle), 0, sin(angle))
		var reach := rng.randf_range(0.72, 1.05) * (1.15 if orchard else 1.0)
		var start := fork + Vector3.UP * rng.randf_range(-0.35, 0.38)
		var elbow := radial * reach * 0.58 + Vector3(0, start.y + 0.38, 0)
		var tip := radial * reach + Vector3(0, rng.randf_range(2.05, 2.66), 0)
		TreeBranchMesh.add_segment(wood, start, elbow, 0.12, 0.075)
		TreeBranchMesh.add_segment(wood, elbow, tip, 0.075, 0.028)
		for split in 2:
			var sideways := Vector3(-radial.z, 0, radial.x) * (0.28 if split == 0 else -0.28)
			var twig := tip + sideways + Vector3.UP * rng.randf_range(0.15, 0.38)
			TreeBranchMesh.add_segment(wood, elbow.lerp(tip, 0.65), twig, 0.04, 0.009)
			TreeLeafMesh.add_spray(leaves, rng, twig, Vector3(0.50, 0.43, 0.50), orchard)

static func _commit(wood: SurfaceTool, leaves: SurfaceTool) -> ArrayMesh:
	var bark := StandardMaterial3D.new()
	bark.vertex_color_use_as_albedo = true
	bark.roughness = 1.0
	bark.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	wood.set_material(bark)
	wood.generate_normals()
	wood.index()
	var mesh := wood.commit()
	var foliage := ShaderMaterial.new()
	foliage.shader = preload("res://game/world/common/tree_leaves.gdshader")
	leaves.set_material(foliage)
	leaves.generate_normals()
	leaves.index()
	leaves.commit(mesh)
	return mesh

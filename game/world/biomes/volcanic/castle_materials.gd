class_name CastleMaterials
extends RefCounted
## Shared world-projected surfaces; every wall and stair keeps the same stone scale.

const SURFACE: Shader = preload("res://game/world/biomes/volcanic/castle_stone.gdshader")
const MASONRY: Texture2D = preload("res://assets/environment/lava_castle/basalt-masonry.png")
const PAVERS: Texture2D = preload("res://assets/environment/lava_castle/ash-flagstones.png")
const WEAVE: Texture2D = preload("res://assets/environment/lava_castle/royal-crimson-weave.png")
static var _materials: Dictionary[String, Material] = {}

static func stone(color: Color, floor_surface: bool = false) -> ShaderMaterial:
	return _surface("floor" if floor_surface else "wall", color.lightened(0.62), PAVERS if floor_surface else MASONRY, 6.0 if floor_surface else 4.8)

static func cloth() -> ShaderMaterial:
	return _surface("cloth", Color.WHITE, WEAVE, 3.5, 0.012)

static func metal(color: Color, metallic: float = 0.7) -> StandardMaterial3D:
	var key := "metal" + color.to_html() + str(metallic)
	if _materials.has(key): return _materials[key] as StandardMaterial3D
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = 0.64
	_materials[key] = material
	return material

static func ornament(kind: String) -> Material:
	match kind:
		"bronze": return metal(Color("be9158"))
		"iron": return metal(Color("38363e"), 0.8)
		"dark": return stone(Color("30313a"))
		"cloth": return cloth()
		"glass": return _glass()
		_: return stone(Color("c0b294"), true)

static func box(parent: Node3D, at: Vector3, size: Vector3, color: Color, floor_surface: bool = false) -> MeshInstance3D:
	var view := MeadowGeometry.box(parent, at, size, color)
	view.material_override = stone(color, floor_surface)
	SolidOcclusion.box(view)
	return view

static func _surface(role: String, color: Color, texture: Texture2D, scale_meters: float, depth: float = 0.055) -> ShaderMaterial:
	var key := role + color.to_html()
	if _materials.has(key): return _materials[key] as ShaderMaterial
	var material := ShaderMaterial.new()
	material.shader = SURFACE
	material.set_shader_parameter("surface_texture", texture)
	material.set_shader_parameter("tint", color)
	material.set_shader_parameter("tile_size", scale_meters)
	material.set_shader_parameter("relief", depth)
	_materials[key] = material
	return material

static func _glass() -> StandardMaterial3D:
	if _materials.has("glass"): return _materials["glass"] as StandardMaterial3D
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("c38954")
	material.emission_enabled = true
	material.emission = Color("df7f38")
	material.emission_energy_multiplier = 0.35
	material.roughness = 0.6
	_materials["glass"] = material
	return material

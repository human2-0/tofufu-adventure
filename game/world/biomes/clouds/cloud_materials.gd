class_name CloudMaterials
extends RefCounted
## Cached, world-scaled heavenly surfaces keep veins and weave consistent on props.

const CLOUD: Texture2D = preload("res://assets/environment/cloud_realm/pearl-clouds-soft.png")
const MARBLE: Texture2D = preload("res://assets/environment/cloud_realm/olympian-marble.png")
const SILK: Texture2D = preload("res://assets/environment/cloud_realm/laurel-silk.png")
const FRIEZE: Texture2D = preload("res://assets/environment/cloud_realm/greek-key.svg")
const MOSAIC: Texture2D = preload("res://assets/environment/cloud_realm/laurel-mosaic.svg")
static var _cache: Dictionary[String, Material] = {}

static func cloud(color: Color = Color.WHITE) -> StandardMaterial3D:
	return _surface("cloud", CLOUD, color, 8.0, 0.045)

static func marble(color: Color = Color("dedbd1")) -> StandardMaterial3D:
	return _surface("marble", MARBLE, color, 3.0)

static func silk(color: Color = Color.WHITE) -> StandardMaterial3D:
	return _surface("silk", SILK, color, 2.5)

static func gold() -> StandardMaterial3D:
	if _cache.has("gold"): return _cache.gold as StandardMaterial3D
	var material := MeadowGeometry.material(Color("d9b769"))
	material.next_pass = null
	material.metallic = 0.45
	material.roughness = 0.5
	_cache.gold = material
	return material

static func water() -> ShaderMaterial:
	if _cache.has("water"): return _cache.water as ShaderMaterial
	var material := ShaderMaterial.new()
	material.shader = preload("res://game/world/biomes/clouds/cloud_fountain.gdshader")
	material.set_shader_parameter("cloud_texture", CLOUD)
	_cache.water = material
	return material

static func illustrated(texture: Texture2D) -> StandardMaterial3D:
	var key := texture.resource_path
	if _cache.has(key): return _cache[key] as StandardMaterial3D
	var material := MeadowGeometry.material(Color("e0ddce"))
	material.next_pass = null
	material.albedo_texture = texture
	_cache[key] = material
	return material

static func _surface(role: String, texture: Texture2D, tint: Color, meters: float, glow: float = 0.0) -> StandardMaterial3D:
	var key := role + tint.to_html()
	if _cache.has(key): return _cache[key] as StandardMaterial3D
	var material := MeadowGeometry.material(tint)
	material.next_pass = null
	material.albedo_texture = texture
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3.ONE / meters
	material.vertex_color_use_as_albedo = true
	material.emission_enabled = glow > 0
	material.emission = tint
	material.emission_energy_multiplier = glow
	_cache[key] = material
	return material

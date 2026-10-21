class_name GigalopolisMaterials
extends RefCounted
## One textured palette for the factory, city blocks, walkways and expedition camps.

const STONE: Texture2D = preload("res://assets/environment/gigalopolis/limestone.png")
const METAL: Texture2D = preload("res://assets/environment/gigalopolis/teal-metal.png")
const PAVING: Texture2D = preload("res://assets/environment/gigalopolis/paving.png")
const CANVAS: Texture2D = preload("res://assets/environment/gigalopolis/canvas.png")
const ROOF: Texture2D = preload("res://assets/environment/gigalopolis/east/roof.png")
const GLASS: Texture2D = preload("res://assets/environment/gigalopolis/east/glass.png")
const BRICK: Texture2D = preload("res://assets/environment/gigalopolis/east/brick.png")
const FRIEZE: Texture2D = preload("res://assets/environment/gigalopolis/east/frieze.png")
const FLOOR: Texture2D = preload("res://assets/environment/gigalopolis/interiors/floor.png")
const WOOD: Texture2D = preload("res://assets/environment/gigalopolis/interiors/wood.png")
const RUG: Texture2D = preload("res://assets/environment/gigalopolis/interiors/rug.png")
const PLASTER: Texture2D = preload("res://assets/environment/gigalopolis/interiors/plaster.png")
static var _materials: Dictionary[String, StandardMaterial3D] = {}

static func surface(kind: String) -> StandardMaterial3D:
	if _materials.has(kind): return _materials[kind]
	var result := MeadowGeometry.material(Color.WHITE)
	var texture: Texture2D = STONE
	var repeat := 0.22
	match kind:
		"floor": texture = FLOOR
		"wood": texture = WOOD
		"rug": texture = RUG
		"plaster": texture = PLASTER
		"roof": texture = ROOF
		"glass":
			texture = GLASS
			repeat = 0.35
		"brick": texture = BRICK
		"frieze":
			texture = FRIEZE
			repeat = 0.35
		"metal": texture = METAL
		"paving":
			texture = PAVING
			repeat = 0.32
		"canvas":
			texture = CANVAS
			repeat = 0.7
		"brass":
			texture = METAL
			result.albedo_color = Color("eac183")
		"dark":
			texture = METAL
			result.albedo_color = Color("586f6b")
	result.albedo_texture = texture
	result.uv1_triplanar = true
	result.uv1_world_triplanar = true
	result.uv1_scale = Vector3.ONE * repeat
	result.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_materials[kind] = result
	return result

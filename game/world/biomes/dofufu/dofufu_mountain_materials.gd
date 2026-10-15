class_name DofufuMountainMaterials
extends RefCounted
## Shared immutable material variants for the authored natural material atlas.

const ATLAS: Texture2D = preload("res://assets/environment/dofufu_mountains/natural-surfaces.png")
var _materials: Dictionary[int, ShaderMaterial] = {}

func surface(tile: int) -> ShaderMaterial:
	if not _materials.has(tile):
		var material := ShaderMaterial.new()
		material.shader = preload("res://game/world/biomes/dofufu/mountain_props.gdshader")
		material.set_shader_parameter("surfaces", ATLAS)
		material.set_shader_parameter("tile", tile)
		_materials[tile] = material
	return _materials[tile]

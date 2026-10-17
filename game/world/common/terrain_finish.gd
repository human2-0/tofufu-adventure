class_name TerrainFinish
extends RefCounted
## One subtle painted grain across grass, sand and snow transition surfaces.

const GRAIN: Texture2D = preload("res://assets/environment/biome_transitions/ground-grain.png")

static func create() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://game/world/common/terrain_finish.gdshader")
	material.set_shader_parameter("ground_grain", GRAIN)
	return material

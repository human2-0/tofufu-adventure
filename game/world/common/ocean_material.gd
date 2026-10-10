class_name OceanMaterial
extends RefCounted
## One bounded, screen-copy-free water implementation for every ocean region.

const SHADER: Shader = preload("res://game/world/common/ocean_water.gdshader")

static func create(encoding: Vector2 = Vector2(16, -8), shallow: Color = Color("33a8a6"), deep: Color = Color("063d61")) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("bed_encoding", encoding)
	material.set_shader_parameter("color_shallow", shallow)
	material.set_shader_parameter("color_deep", deep)
	return material

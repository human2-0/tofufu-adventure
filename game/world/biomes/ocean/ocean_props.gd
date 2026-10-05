class_name OceanProps
extends RefCounted
## Hand-built underwater silhouettes without an external art dependency.

static func coral(parent: Node3D, at: Vector3, size: float, color: Color) -> void:
	for i in 5:
		var angle := i * TAU / 5.0
		var branch := MeadowGeometry.box(parent, at + Vector3(cos(angle) * size * 0.24, size * 0.36, sin(angle) * size * 0.24), Vector3(size * 0.16, size * 0.82, size * 0.16), color)
		branch.rotation.z = sin(angle) * 0.55

static func kelp(parent: Node3D, at: Vector3, height: float) -> void:
	var material := ShaderMaterial.new()
	material.shader = preload("res://game/world/biomes/ocean/ocean_kelp.gdshader")
	material.set_shader_parameter("stem_height", height)
	for i in 3:
		var blade := MeadowGeometry.box(parent, at + Vector3((i - 1) * 0.18, height * 0.5, 0), Vector3(0.18, height, 0.09), Color("397d66"))
		blade.rotation.z = (i - 1) * 0.25
		blade.material_override = material

static func sea_rock(parent: Node3D, at: Vector3, size: Vector3) -> void:
	MeadowGeometry.rock(parent, at + Vector3.UP * size.y * 0.5, size, Color("3d6570"), true)

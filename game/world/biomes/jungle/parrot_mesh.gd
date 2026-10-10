class_name ParrotMesh
extends RefCounted
## Shared textured surfaces; feathers are closed folded vanes with real thickness.

static var _sphere: SphereMesh
static var _material: ShaderMaterial

static func surface() -> SurfaceTool:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	return tool

static func finish(tool: SurfaceTool) -> ArrayMesh:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = preload("res://game/world/biomes/jungle/parrot_feathers.gdshader")
		_material.set_shader_parameter("feather_texture", preload("res://assets/characters/parrot/feather.svg"))
	tool.set_material(_material)
	tool.index()
	return tool.commit()

static func oval(tool: SurfaceTool, at: Vector3, size: Vector3, color: Color, patterned: bool = false, tilt: float = 0.0) -> void:
	if _sphere == null:
		_sphere = SphereMesh.new()
		_sphere.radius = 0.5
		_sphere.height = 1
		_sphere.radial_segments = 28
		_sphere.rings = 14
	var arrays := _sphere.get_mesh_arrays()
	var basis := Basis(Vector3.RIGHT, tilt).scaled(size)
	var normals := basis.inverse().transposed()
	color.a = 0.4 if patterned else 0.0
	for index: int in arrays[Mesh.ARRAY_INDEX]:
		tool.set_color(color)
		tool.set_uv(arrays[Mesh.ARRAY_TEX_UV][index])
		tool.set_normal((normals * arrays[Mesh.ARRAY_NORMAL][index]).normalized())
		tool.add_vertex(at + basis * arrays[Mesh.ARRAY_VERTEX][index])

static func feather(tool: SurfaceTool, root: Vector3, tip: Vector3, width: float, color: Color, plane_normal: Vector3 = Vector3.UP) -> void:
	var along := tip - root
	var across := plane_normal.cross(along).normalized()
	color.a = 1.0
	for ring in 6:
		for side in 4:
			for corner in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var t := float(ring + corner.x) / 6.0
				var edge := posmod(side + corner.y, 4)
				var angle := edge * PI * 0.5
				var vane := pow(maxf(0.015, sin(t * PI)), 0.65) * width
				var offset := across * sin(angle) * vane + plane_normal * cos(angle) * 0.024
				tool.set_color(color)
				tool.set_normal((across * sin(angle) * 0.3 + plane_normal * cos(angle)).normalized())
				tool.set_uv(Vector2(sin(angle) * 0.5 + 0.5, t))
				tool.add_vertex(root + along * t + offset - plane_normal * t * t * 0.09)

static func hooked_bill(tool: SurfaceTool) -> void:
	for ring in 6:
		for side in 12:
			for corner in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var t := float(ring + corner.x) / 6.0
				var angle: float = (side + corner.y) * TAU / 12.0
				var width := 0.17 * pow(1.0 - t, 0.7) + 0.003
				var center := Vector3(0, 1.22 - t * 0.40, -1.10 - sin(t * PI * 0.7) * 0.25)
				var color := Color("ffe6ad") if t < 0.62 else Color("273548")
				color.a = 0.0
				tool.set_color(color)
				tool.set_uv(Vector2.ZERO)
				tool.set_normal(Vector3(cos(angle), 0.35, sin(angle)).normalized())
				tool.add_vertex(center + Vector3(cos(angle) * width, 0, sin(angle) * width * 0.72))

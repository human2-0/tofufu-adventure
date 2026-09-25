class_name RiverFishArt
extends RefCounted
## Small cream-bellied, amber-backed fish with a forked tail and paired fins.

static func build() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var body := SphereMesh.new()
	body.radius = 1.0
	body.height = 2.0
	body.radial_segments = 12
	body.rings = 6
	var arrays := body.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for index in indices:
		var p := vertices[index] * Vector3(0.105, 0.14, 0.36)
		surface.set_color(Color("e7a658") if p.y > 0.01 else Color("f4e8b7"))
		surface.add_vertex(p)
	for side in [-1.0, 1.0]:
		_tri(surface, Vector3(0, 0, 0.28), Vector3(side * 0.2, 0.04, 0.54), Vector3(0, 0, 0.43), Color("cc7953"))
		_tri(surface, Vector3(side * 0.08, -0.01, -0.07), Vector3(side * 0.23, -0.05, 0.14), Vector3(side * 0.06, -0.05, 0.17), Color("e7bb74"))
		_tri(surface, Vector3(side * 0.094, 0.075, -0.19), Vector3(side * 0.098, 0.035, -0.20), Vector3(side * 0.094, 0.055, -0.24), Color("343f44"))
	_tri(surface, Vector3(0, 0.10, -0.09), Vector3(0, 0.26, 0.12), Vector3(0, 0.10, 0.24), Color("c98956"))
	surface.generate_normals()
	var mesh := surface.commit()
	var material := ShaderMaterial.new()
	material.shader = preload("res://game/world/river_fish.gdshader")
	mesh.surface_set_material(0, material)
	return mesh

static func _tri(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	for p in [a, b, c]:
		surface.set_color(color)
		surface.add_vertex(p)

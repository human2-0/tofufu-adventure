extends RefCounted
## Small beveled ivory panels and tapered feathers for the Olympian weapon models.

static func panel(size: Vector3) -> ArrayMesh:
	var x := size.x * 0.5
	var y := size.y * 0.5
	var bevel := minf(x, y) * 0.25
	var outline: Array[Vector2] = [Vector2(-x + bevel, -y), Vector2(x - bevel, -y), Vector2(x, -y + bevel), Vector2(x, y - bevel), Vector2(x - bevel, y), Vector2(-x + bevel, y), Vector2(-x, y - bevel), Vector2(-x, -y + bevel)]
	return _extrude(outline, size.z)

static func feather(length: float, width: float) -> ArrayMesh:
	var outline: Array[Vector2] = [Vector2(-length * 0.5, -width * 0.25), Vector2(-length * 0.4, -width * 0.5), Vector2(length * 0.1, -width * 0.42), Vector2(length * 0.5, 0), Vector2(length * 0.1, width * 0.42), Vector2(-length * 0.4, width * 0.5), Vector2(-length * 0.5, width * 0.25)]
	return _extrude(outline, 0.035)

static func _extrude(outline: Array[Vector2], depth: float) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in outline.size():
		var next := (index + 1) % outline.size()
		var a := Vector3(outline[index].x, outline[index].y, depth * 0.5)
		var b := Vector3(outline[next].x, outline[next].y, depth * 0.5)
		var c := Vector3(b.x, b.y, -depth * 0.5)
		var d := Vector3(a.x, a.y, -depth * 0.5)
		# Clockwise triangles face outward in Godot.
		for vertex: Vector3 in [Vector3(0, 0, depth * 0.5), b, a, Vector3(0, 0, -depth * 0.5), d, c, a, b, c, a, c, d]:
			surface.set_uv(Vector2(vertex.x, vertex.y))
			surface.add_vertex(vertex)
	surface.generate_normals()
	return surface.commit()

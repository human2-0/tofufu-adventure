@static_unload
class_name ArmoredShellMesh
extends RefCounted
## One shared curved armor mesh with separated plates and a raised side spiral.

static var _mesh: ArrayMesh

static func create() -> ArrayMesh:
	if _mesh != null: return _mesh
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	_lining(surface)
	for band in 6:
		for panel in 12:
			_plate(surface, band, panel)
	for side in [-1.0, 1.0]:
		var points := PackedVector3Array()
		for index in 73:
			var t := float(index) / 72
			var angle := t * TAU * 1.8
			var radius := lerpf(0.035, 0.42, t)
			var y := sin(angle) * radius
			var z := cos(angle) * radius
			var x := sqrt(maxf(0.0, 1.0 - pow(y / 0.53, 2) - pow(z / 0.62, 2))) * 0.62
			points.append(Vector3(side * (x + 0.004), y, z))
		_tube(surface, points, 0.018, Color("d9bc86"))
	var lip := PackedVector3Array()
	for index in 49:
		var angle := index * TAU / 48
		lip.append(Vector3(cos(angle) * 0.565, -0.22, sin(angle) * 0.565))
	_tube(surface, lip, 0.028, Color("614d3d"))
	surface.index()
	_mesh = surface.commit()
	return _mesh

static func _lining(surface: SurfaceTool) -> void:
	for row in 8:
		for column in 16:
			var a := Vector2(column * TAU / 16, lerpf(-PI / 2, PI / 2, row / 8.0))
			var b := Vector2((column + 1) * TAU / 16, a.y)
			var c := Vector2(b.x, lerpf(-PI / 2, PI / 2, (row + 1) / 8.0))
			var d := Vector2(a.x, c.y)
			for point: Vector2 in [a, b, c, a, c, d]:
				var unit := Vector3(cos(point.x) * cos(point.y), sin(point.y), sin(point.x) * cos(point.y))
				surface.set_normal((unit / Vector3(0.61, 0.52, 0.61)).normalized())
				surface.set_color(Color("88755b"))
				surface.set_uv(Vector2(point.x / TAU, point.y / PI + 0.5))
				surface.add_vertex(unit * Vector3(0.61, 0.52, 0.61))

static func _plate(surface: SurfaceTool, band: int, panel: int) -> void:
	var lower := -0.42 + band * (PI / 2 + 0.42) / 6 + 0.012
	var upper := -0.42 + (band + 1) * (PI / 2 + 0.42) / 6 - 0.012
	var start := panel * TAU / 12 + (band % 2) * PI / 12 + 0.012
	var end := start + TAU / 12 - 0.024
	var color := Color.WHITE.lerp(Color("cbb488"), ((band + panel * 3) % 5) * 0.06)
	for row in 3:
		for column in 3:
			var a := Vector2(lerpf(start, end, column / 3.0), lerpf(lower, upper, row / 3.0))
			var b := Vector2(lerpf(start, end, (column + 1) / 3.0), a.y)
			var c := Vector2(b.x, lerpf(lower, upper, (row + 1) / 3.0))
			var d := Vector2(a.x, c.y)
			for point: Vector2 in [a, b, c, a, c, d]:
				var unit := Vector3(cos(point.x) * cos(point.y), sin(point.y), sin(point.x) * cos(point.y))
				var at := unit * Vector3(0.62, 0.53, 0.62)
				surface.set_normal((unit / Vector3(0.62, 0.53, 0.62)).normalized())
				surface.set_color(color)
				surface.set_uv(Vector2(point.x / TAU, point.y / PI + 0.5))
				surface.add_vertex(at)

static func _tube(surface: SurfaceTool, points: PackedVector3Array, radius: float, color: Color) -> void:
	for index in points.size() - 1:
		var forward := (points[index + 1] - points[index]).normalized()
		var right := forward.cross(Vector3.UP).normalized()
		if right.length_squared() < 0.01: right = Vector3.RIGHT
		var up := right.cross(forward).normalized()
		for segment in 6:
			var a := segment * TAU / 6
			var b := (segment + 1) * TAU / 6
			var n1 := right * cos(a) + up * sin(a)
			var n2 := right * cos(b) + up * sin(b)
			var offsets := [n1, n2, n1, n2, n2, n1]
			var origins := [points[index], points[index + 1], points[index + 1], points[index], points[index + 1], points[index]]
			for vertex in 6:
				surface.set_normal(offsets[vertex])
				surface.set_color(color)
				surface.set_uv(Vector2.ZERO)
				surface.add_vertex(origins[vertex] + offsets[vertex] * radius)

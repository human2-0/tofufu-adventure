@static_unload
class_name BeeMesh
extends RefCounted
## Shared shaped abdomen/thorax mesh and four veined, curved wing membranes.

static var _body: ArrayMesh
static var _wing: ArrayMesh

static func body() -> ArrayMesh:
	if _body != null: return _body
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	_ellipsoid(surface, Vector3(0, 0, -0.19), Vector3(0.31, 0.28, 0.47), true, Color("f2bd3e"))
	_ellipsoid(surface, Vector3(0, 0.02, 0.22), Vector3(0.25, 0.26, 0.27), false, Color("c59339"))
	_ellipsoid(surface, Vector3(0, 0.045, 0.5), Vector3(0.23, 0.23, 0.22), false, Color("efc756"))
	surface.index()
	_body = surface.commit()
	return _body

static func wing() -> ArrayMesh:
	if _wing != null: return _wing
	var membrane := SurfaceTool.new()
	membrane.begin(Mesh.PRIMITIVE_TRIANGLES)
	var veins := SurfaceTool.new()
	veins.begin(Mesh.PRIMITIVE_TRIANGLES)
	_blade(membrane, veins, Vector3(0, 0, 0.07), Vector2(0.64, 0.26), -0.1)
	_blade(membrane, veins, Vector3(0.03, -0.025, -0.12), Vector2(0.42, 0.19), -0.33)
	membrane.index()
	_wing = membrane.commit()
	veins.index()
	veins.commit(_wing)
	return _wing

static func _ellipsoid(surface: SurfaceTool, at: Vector3, size: Vector3, striped: bool, tint: Color) -> void:
	for ring in 12:
		var color := Color("423529") if striped and ring in [2, 3, 6, 7, 10] else tint
		for segment in 16:
			var a := Vector2(segment * TAU / 16, -PI / 2 + ring * PI / 12)
			var b := Vector2((segment + 1) * TAU / 16, a.y)
			var c := Vector2(b.x, -PI / 2 + (ring + 1) * PI / 12)
			var d := Vector2(a.x, c.y)
			for point: Vector2 in [a, c, b, a, d, c]:
				var unit := Vector3(cos(point.x) * cos(point.y), sin(point.x) * cos(point.y), sin(point.y))
				surface.set_normal((unit / size).normalized())
				surface.set_color(color)
				surface.set_uv(Vector2(point.x / TAU, point.y / PI + 0.5))
				surface.add_vertex(at + unit * size)

static func _blade(surface: SurfaceTool, veins: SurfaceTool, at: Vector3, size: Vector2, sweep: float) -> void:
	var points := PackedVector3Array()
	for index in 17:
		var angle := index * TAU / 16
		var reach := (1.0 - cos(angle)) * 0.5
		points.append(at + Vector3(reach * size.x, sin(angle) * 0.014, sin(angle) * size.y + reach * sweep))
	var center := at + Vector3(size.x * 0.43, 0.025, sweep * 0.43)
	for index in 16:
		for point: Vector3 in [center, points[index + 1], points[index]]:
			surface.set_normal(Vector3.UP)
			surface.set_color(Color.WHITE)
			surface.set_uv(Vector2(point.x, point.z))
			surface.add_vertex(point)
		_line(veins, points[index], points[index + 1], 0.004)
	for index in [3, 6, 10, 13]: _line(veins, at, points[index], 0.004)

static func _line(surface: SurfaceTool, start: Vector3, end: Vector3, width: float) -> void:
	var offset := (end - start).cross(Vector3.UP).normalized() * width
	for point: Vector3 in [start - offset, end + offset, end - offset, start - offset, start + offset, end + offset]:
		surface.set_normal(Vector3.UP)
		surface.set_color(Color.WHITE)
		surface.set_uv(Vector2.ZERO)
		surface.add_vertex(point + Vector3.UP * 0.004)

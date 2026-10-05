@tool
class_name TreeBranchMesh
extends RefCounted
## Tapered, ridged wood joined into one mesh, with bark-colored facets.

static func add_segment(surface: SurfaceTool, start: Vector3, end: Vector3, base: float, tip: float) -> void:
	var direction := (end - start).normalized()
	var across := direction.cross(Vector3.FORWARD).normalized()
	if across.length_squared() < 0.01: across = Vector3.RIGHT
	var around := direction.cross(across).normalized()
	for side in 10:
		var a := TAU * side / 10.0
		var b := TAU * (side + 1) / 10.0
		var r0 := across * cos(a) + around * sin(a)
		var r1 := across * cos(b) + around * sin(b)
		var ridge0 := 1.0 + 0.09 * sin(side * 2.7)
		var ridge1 := 1.0 + 0.09 * sin((side + 1) * 2.7)
		var low0 := start + r0 * base * ridge0
		var low1 := start + r1 * base * ridge1
		var high0 := end + r0 * tip * ridge0
		var high1 := end + r1 * tip * ridge1
		var color := Color("6a4930").lightened(0.08 * float(side % 3))
		_triangle(surface, low0, high0, low1, color)
		_triangle(surface, low1, high0, high1, color)
		_triangle(surface, high0, end, high1, color.darkened(0.1))

static func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	surface.set_color(color)
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)

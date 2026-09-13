class_name SoybeanPlant
extends Node3D
## Authored 3D trifoliate plant and cutaway pod; no quest decisions.

@export var occupant_offset: Vector3 = Vector3(0, -2.35, 0.2)

var pivot: Node3D
var pod: Node3D
var seat: Marker3D
var left_shell: Node3D
var right_shell: Node3D
var stem: MeshInstance3D

func _ready() -> void:
	_segment(self, Vector3(-2.2, 0, -0.6), Vector3(-1.8, 3.2, -0.6), 0.13, Color("4e7750"))
	_segment(self, Vector3(-1.8, 3.2, -0.6), Vector3(-1.4, 6.3, -0.6), 0.09, Color("719851"))
	_segment(self, Vector3(-1.5, 5.6, -0.6), Vector3(0, 5.5, 0), 0.06, Color("739452"))
	for i in 4:
		var origin := Vector3(-2.05 + i * 0.16, 1.5 + i * 1.15, -0.6)
		var side := -1.0 if i % 2 == 0 else 1.0
		var tip := origin + Vector3(side * 1.2, 0.55, -0.4)
		_segment(self, origin, tip, 0.045, Color("6c9656"))
		for leaf in 3:
			var angle := -1.0 + leaf * 1.0
			var end := tip + Vector3(sin(angle) * 1.4, 0.28, -cos(angle) * 1.4)
			_leaf(tip, end)

	# Smaller seed pods keep the oversized nursery pod recognizably on a soy plant.
	for i in 3:
		var at := Vector3(-2.5 - i * 0.25, 2.7 + i * 0.8, -0.5)
		_segment(self, at + Vector3(0.5, 0.7, 0), at, 0.025, Color("7d9251"))
		for bean in 3:
			_ellipsoid(self, at + Vector3(0, -bean * 0.28, 0), Vector3(0.2, 0.23, 0.14), Color("aabc6b"))
	pivot = Node3D.new()
	pivot.position = Vector3(0, 5.5, 0)
	add_child(pivot)
	stem = _segment(pivot, Vector3.ZERO, Vector3(0, -0.55, 0), 0.045, Color("b7a566"))
	pod = Node3D.new()
	pivot.add_child(pod)
	left_shell = _valve(-1.0)
	right_shell = _valve(1.0)
	seat = Marker3D.new()
	seat.position = occupant_offset
	pod.add_child(seat)

func _leaf(start: Vector3, end: Vector3) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var across := (end - start).cross(Vector3.UP).normalized()
	for row in 12:
		for side: float in [-1.0, 1.0]:
			var t := row / 12.0
			var u := (row + 1) / 12.0
			var a := start.lerp(end, t) + Vector3.UP * sin(t * PI) * 0.12
			var b := start.lerp(end, u) + Vector3.UP * sin(u * PI) * 0.12
			var edge_a := a + across * side * sin(t * PI) * 0.35 - Vector3.UP * 0.05
			var edge_b := b + across * side * sin(u * PI) * 0.35 - Vector3.UP * 0.05
			for vertex in [a, b, edge_b, a, edge_b, edge_a]:
				surface.add_vertex(vertex)
	surface.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = surface.commit()
	var material := _material(Color("84ac62"))
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material_override = material
	add_child(mesh)
	_segment(self, start + Vector3.UP * 0.05, end, 0.012, Color("c0cf81"))

func _valve(side: float) -> Node3D:
	var shell := Node3D.new()
	pod.add_child(shell)
	# Continuous tapered hull, with a pale inner lining and rolled green lip.
	_hull(shell, side, 1.0, Color("78954e"))
	_hull(shell, side, 0.95, Color("c8ce87"))
	for i in 24:
		var t := 0.015 + i * 0.97 / 24.0
		var next := 0.015 + (i + 1) * 0.97 / 24.0
		var at := _hull_point(t, 1.85, side)
		var end := _hull_point(next, 1.85, side)
		_segment(shell, at, end, 0.036, Color("9bb56b"))
		if i % 2 == 0:
			_segment(shell, at, at + Vector3(side * 0.055, 0.015, 0.035), 0.005, Color("e1ddb0"))
	return shell

func _hull(parent: Node3D, side: float, shrink: float, color: Color) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in 32:
		for col in 12:
			var corners: Array[Vector2] = [Vector2(row, col), Vector2(row + 1, col), Vector2(row + 1, col + 1), Vector2(row, col + 1)]
			for index in [0, 1, 2, 0, 2, 3]:
				var uv := corners[index] / Vector2(32, 12)
				var point := _hull_point(clampf(uv.x, 0.001, 0.999), uv.y * 1.85, side)
				point.x *= shrink
				point.z = point.z * shrink + (1.0 - shrink) * 0.3
				surface.add_vertex(point)
	surface.generate_normals()
	var instance := MeshInstance3D.new()
	instance.mesh = surface.commit()
	var material := _material(color)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	instance.material_override = material
	parent.add_child(instance)

func _hull_point(t: float, angle: float, side: float) -> Vector3:
	var radius := pow(sin(t * PI), 0.55) * (0.73 + 0.045 * cos(t * TAU * 3))
	return Vector3(side * radius * sin(angle), -0.48 - t * 2.2, -radius * 0.55 * cos(angle))

func present(angle: float, fall: float, opening: float) -> void:
	pivot.rotation.z = angle * (1.0 - fall)
	pivot.position.y = lerpf(5.5, 2.6, fall)
	stem.visible = fall <= 0.0
	left_shell.position = Vector3(-opening * 0.85, -opening * 0.15, 0)
	right_shell.position = Vector3(opening * 0.85, -opening * 0.15, 0)
	left_shell.rotation.z = opening * -0.55
	right_shell.rotation.z = opening * 0.55

func _ellipsoid(parent: Node3D, at: Vector3, dimensions: Vector3, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 24
	mesh.rings = 12
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	instance.scale = dimensions
	instance.material_override = _material(color)
	parent.add_child(instance)
	return instance

func _segment(parent: Node3D, start: Vector3, end: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.75
	mesh.bottom_radius = radius
	mesh.height = start.distance_to(end)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = (start + end) * 0.5
	var axis := (end - start).normalized()
	var across := axis.cross(Vector3.FORWARD).normalized()
	instance.basis = Basis(across, axis, across.cross(axis))
	instance.material_override = _material(color)
	parent.add_child(instance)
	return instance

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	return material

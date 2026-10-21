class_name GigalopolisProfiles
extends RefCounted
## Capped roof profiles and cylindrical structures share the city's generated paint.

static func roof(parent: Node3D, at: Vector3, width: float, depth: float, rise: float, vaulted: bool = false) -> void:
	var profile: Array[Vector2] = [Vector2(-width * 0.5, 0)]
	if vaulted:
		for index in range(1, 13):
			var angle: float = PI - index * PI / 12
			profile.append(Vector2(cos(angle) * width * 0.5, sin(angle) * rise))
	else:
		profile.append(Vector2(0, rise))
		profile.append(Vector2(width * 0.5, 0))
	_prism(parent, at, profile, depth, "roof")

static func _prism(parent: Node3D, at: Vector3, profile: Array[Vector2], depth: float, kind: String) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in profile.size():
		var a := profile[index]
		var b := profile[(index + 1) % profile.size()]
		var front := Vector3(a.x, a.y, depth * 0.5)
		var next := Vector3(b.x, b.y, depth * 0.5)
		_quad(surface, front, front - Vector3.BACK * depth, next - Vector3.BACK * depth, next)
	for index in range(1, profile.size() - 1):
		for side: float in [-1, 1]:
			var order := PackedInt32Array([0, index, index + 1] if side > 0 else [0, index + 1, index])
			for vertex in order:
				var point := profile[vertex]
				surface.add_vertex(Vector3(point.x, point.y, side * depth * 0.5))
	surface.generate_normals()
	var view := MeshInstance3D.new()
	view.position = at
	view.mesh = surface.commit()
	view.material_override = GigalopolisMaterials.surface(kind)
	view.set_meta("static_ornament_mesh", true)
	parent.add_child(view)
	view.create_trimesh_collision()

static func sawtooth(parent: Node3D, at: Vector3, width: float, depth: float, rise: float) -> void:
	var points: Array[Vector2] = [Vector2(-width * 0.5, 0), Vector2(width * 0.46, rise), Vector2(width * 0.5, rise), Vector2(width * 0.5, 0)]
	_prism(parent, at, points, depth, "roof")
	GigalopolisGeometry.box(parent, at + Vector3(width * 0.5 + 0.12, rise * 0.5, 0), Vector3(0.18, rise * 0.7, depth - 0.8), "glass")

static func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for vertex: Vector3 in [a, b, c, a, c, d]: surface.add_vertex(vertex)

static func cylinder(parent: Node3D, at: Vector3, radius: float, height: float, kind: String, solid: bool = false) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	var view := MeshInstance3D.new()
	view.position = at
	view.mesh = mesh
	view.material_override = GigalopolisMaterials.surface(kind)
	parent.add_child(view)
	if solid:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var collider := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = radius
		shape.height = height
		collider.shape = shape
		body.add_child(collider)
		view.add_child(body)
	return view

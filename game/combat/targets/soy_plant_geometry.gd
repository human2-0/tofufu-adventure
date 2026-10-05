class_name SoyPlantGeometry
extends RefCounted
## Botanical pieces baked by color into a handful of meshes per growth stage.

var _surfaces: Dictionary[Color, SurfaceTool] = {}

func segment(from: Vector3, to: Vector3, radius: float, color: Color) -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius * 0.72
	cylinder.bottom_radius = radius
	cylinder.height = from.distance_to(to)
	cylinder.radial_segments = 6
	var up := (to - from).normalized()
	var right := up.cross(Vector3.FORWARD).normalized()
	if right.is_zero_approx(): right = Vector3.RIGHT
	_add(cylinder, Transform3D(Basis(right, up, right.cross(up)), (from + to) * 0.5), color)

func oval(at: Vector3, size: Vector3, color: Color) -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 10
	sphere.rings = 5
	_add(sphere, Transform3D(Basis.from_scale(size), at), color)

func leaf(base: Vector3, tip: Vector3, width: float, color: Color) -> void:
	var axis := tip - base
	var side := axis.cross(Vector3.UP).normalized() * width
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for section in 8:
		var u := section / 8.0
		var v := (section + 1) / 8.0
		for flank in [-1.0, 1.0]:
			var a := _leaf_point(base, axis, side, u, 0)
			var b := _leaf_point(base, axis, side, u, flank)
			var c := _leaf_point(base, axis, side, v, flank)
			var d := _leaf_point(base, axis, side, v, 0)
			var triangles := [a, b, c, a, c, d] if flank > 0 else [a, c, b, a, d, c]
			for point: Vector3 in triangles: surface.add_vertex(point)
	surface.generate_normals()
	_add(surface.commit(), Transform3D.IDENTITY, color)
	var vein := color.lightened(0.22)
	segment(base + Vector3.UP * 0.004, tip + Vector3.UP * 0.004, 0.005, vein)
	for index in 3:
		var u := 0.26 + index * 0.18
		for flank in [-1.0, 1.0]:
			segment(_leaf_point(base, axis, side, u, 0) + Vector3.UP * 0.005,
				_leaf_point(base, axis, side, u + 0.15, flank * 0.78) + Vector3.UP * 0.005, 0.002, vein)

func _leaf_point(base: Vector3, axis: Vector3, side: Vector3, u: float, flank: float) -> Vector3:
	var breadth := pow(sin(u * PI), 0.85)
	return base + axis * u + side * breadth * flank + Vector3.UP * breadth * (0.028 - absf(flank) * 0.04)

func flower(at: Vector3, facing: Vector3) -> void:
	oval(at - facing * 0.012, Vector3(0.026, 0.037, 0.026), Color("547b38"))
	oval(at + Vector3.UP * 0.024, Vector3(0.043, 0.045, 0.019), Color("be8acb"))
	for side in [-1.0, 1.0]:
		oval(at + Vector3(side * 0.027, 0, 0.017), Vector3(0.027, 0.021, 0.02), Color("dcb3de"))
	oval(at + Vector3(0, -0.012, 0.03), Vector3(0.018, 0.021, 0.024), Color("f3dca5"))

func pod(at: Vector3, lean: Vector3) -> void:
	var green := Color("91a64d")
	var direction := (Vector3.DOWN + lean * 0.35).normalized()
	var previous := at
	segment(at + Vector3.UP * 0.05, at, 0.009, Color("6a8b3b"))
	for index in 3:
		var center := at + direction * (0.065 + index * 0.085)
		oval(center, Vector3(0.058, 0.075, 0.045), green)
		var seam := center + Vector3(0, 0, 0.044)
		segment(previous, seam, 0.004, Color("c2cd7a"))
		previous = seam
		# Fine pale hairs catch the light on the pod's outer edge.
		for side in [-1.0, 1.0]:
			var edge := center + Vector3(side * 0.051, 0, 0.012)
			segment(edge, edge + Vector3(side * 0.012, 0.009, 0), 0.0015, Color("d2d59a"))
	segment(previous, at + direction * 0.33, 0.009, green)

func bake(parent: Node3D) -> void:
	for color: Color in _surfaces:
		var instance := MeshInstance3D.new()
		instance.mesh = _surfaces[color].commit()
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.9
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		instance.material_override = material
		parent.add_child(instance)
	_surfaces.clear()

func _add(mesh: Mesh, transform: Transform3D, color: Color) -> void:
	if not _surfaces.has(color):
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		_surfaces[color] = surface
	var surface := _surfaces[color]
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var normal_basis := transform.basis.inverse().transposed()
	for index in (indices.size() if not indices.is_empty() else vertices.size()):
		var vertex_index := indices[index] if not indices.is_empty() else index
		surface.set_normal((normal_basis * normals[vertex_index]).normalized())
		surface.add_vertex(transform * vertices[vertex_index])

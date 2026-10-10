class_name CloudTemple
extends RefCounted
## Fluted colonnades, Greek-key entablature and winged laurel pediments.

static func column(parent: Node3D, at: Vector3) -> void:
	CloudCraft.cylinder(parent, at + Vector3.UP * 0.15, 0.43, 0.22, CloudMaterials.marble())
	var profile: Array[Vector2] = [Vector2(0.35, 0.25), Vector2(0.32, 4.3)]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 80:
		for corner in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
			var angle: float = (i + corner.x) * TAU / 80.0
			var point := profile[corner.y]
			var radius: float = point.x - (1.0 + cos(angle * 20.0)) * 0.019
			surface.add_vertex(at + Vector3(cos(angle) * radius, point.y, sin(angle) * radius))
	surface.generate_normals()
	CloudCraft.view(parent, surface.commit(), Vector3.ZERO, CloudMaterials.marble())
	for y in [0.28, 4.25, 4.42]:
		CloudCraft.ring(parent, at + Vector3.UP * y, 0.39, 0.055, CloudMaterials.gold())
	CloudCraft.cylinder(parent, at + Vector3.UP * 4.4, 0.42, 0.3, CloudMaterials.marble(), 0.52)
	CloudCraft.box(parent, at + Vector3.UP * 4.64, Vector3(1.08, 0.22, 1.08), CloudMaterials.marble())

static func roof(parent: Node3D, size: Vector2) -> void:
	var roof := CloudRoof.new()
	parent.add_child(roof)
	parent = roof
	for z in [-size.y * 0.5 - 0.3, size.y * 0.5 + 0.3]:
		var frieze := CloudCraft.box(parent, Vector3(0, 4.97, z), Vector3(size.x + 1.1, 0.45, 0.18), CloudMaterials.illustrated(CloudMaterials.FRIEZE))
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		var points: Array[Vector3] = [Vector3(-size.x * 0.54, 5.3, z), Vector3(0, 7.2, z), Vector3(size.x * 0.54, 5.3, z)]
		if z < 0: points.reverse()
		for at in points:
			surface.add_vertex(at)
		surface.generate_normals()
		var pediment := CloudCraft.view(parent, surface.commit(), Vector3.ZERO, CloudMaterials.marble(Color("c6c9dd")))
		CloudOrnaments.wreath(parent, Vector3(0, 6.1, z + signf(z) * 0.1), 0.65, true)
	for side in [-1, 1]:
		var pitch := CloudCraft.box(parent, Vector3(side * size.x * 0.27, 6.25, 0), Vector3(size.x * 0.6, 0.18, size.y + 1.7), CloudMaterials.marble(Color("d7c9de")))
		pitch.rotation.z = -side * atan2(1.9, size.x * 0.54)
		var trim := CloudCraft.box(parent, Vector3(side * size.x * 0.27, 6.3, size.y * 0.5 + 0.85), Vector3(size.x * 0.6, 0.13, 0.15), CloudMaterials.gold())
		trim.rotation.z = pitch.rotation.z

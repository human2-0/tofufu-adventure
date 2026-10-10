class_name CloudCourtyards
extends RefCounted
## Marble mosaics follow the existing cloud floor; paths keep their physical height.

static func build(parent: Node3D) -> void:
	_patch(parent, Vector2(-8, 270), Vector2(18, 15), true)
	_patch(parent, Vector2(4, 335), Vector2(14, 17), true)
	_patch(parent, Vector2(43, 286), Vector2(9, 7), false)
	for destination in [Vector2(-8, 254), Vector2(39, 285), Vector2(-49, 290), Vector2(4, 327)]:
		_path(parent, Vector2(-8, 277), destination)

static func _patch(parent: Node3D, center: Vector2, size: Vector2, mosaic: bool) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var columns := ceili(size.x)
	var rows := ceili(size.y)
	for y in rows:
		for x in columns:
			for corner in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]:
				var uv := Vector2((x + corner.x) / columns, (y + corner.y) / rows)
				var at := center + (uv - Vector2.ONE * 0.5) * size
				surface.set_uv(uv)
				surface.add_vertex(CloudTerrain.point(at.x, at.y, 0.028))
	surface.generate_normals()
	var material: Material = CloudMaterials.illustrated(CloudMaterials.MOSAIC) if mosaic else CloudMaterials.marble()
	CloudCraft.view(parent, surface.commit(), Vector3.ZERO, material)

static func _path(parent: Node3D, from: Vector2, to: Vector2) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := ceili(from.distance_to(to) / 1.5)
	var side := (to - from).orthogonal().normalized()
	for step in count:
		for triangle in [[Vector2(0, -1), Vector2(0, 1), Vector2(1, -1)], [Vector2(1, -1), Vector2(0, 1), Vector2(1, 1)]]:
			var points: Array[Vector2] = []
			for corner: Vector2 in triangle:
				var at := from.lerp(to, (step + corner.x) / count) + side * corner.y * 1.3
				if CloudTerrain.contains(at): points.append(at)
			if points.size() != 3: continue
			for at in points: surface.add_vertex(CloudTerrain.point(at.x, at.y, 0.02))
	surface.generate_normals()
	CloudCraft.view(parent, surface.commit(), Vector3.ZERO, CloudMaterials.marble(Color("d4dce0")))

class_name CloudPathDetails
extends RefCounted
## Small flowers and path lamps share spatial batches instead of hundreds of nodes.

static func build(parent: Node3D) -> void:
	var stems: Array[Transform3D] = []
	var peach: Array[Transform3D] = []
	var lilac: Array[Transform3D] = []
	var posts: Array[Transform3D] = []
	var lamps: Array[Transform3D] = []
	for island in CloudTerrain.ISLANDS:
		var center := CloudTerrain.CENTER + Vector2(island.x, island.y)
		for i in 6:
			var at := center + Vector2(cos(i * TAU / 6), sin(i * TAU / 6)) * (island.z * 0.76)
			for flower in 5:
				var base := CloudTerrain.point(at.x + cos(flower * 2.4) * 0.6, at.y + sin(flower * 2.4) * 0.6)
				stems.append(Transform3D(Basis.IDENTITY, base + Vector3.UP * 0.22))
				var pose := Transform3D(Basis.IDENTITY.scaled(Vector3(0.2, 0.12, 0.2)), base + Vector3.UP * 0.5)
				if flower % 2: peach.append(pose)
				else: lilac.append(pose)
		var hub := CloudTerrain.CENTER + CloudTerrain.HUB
		var count := maxi(1, int(center.distance_to(hub) / 9))
		for step in range(1, count):
			var at := hub.lerp(center, float(step) / count)
			var side := (center - hub).orthogonal().normalized() * 3.6
			for offset in [-side, side]:
				var base := CloudTerrain.point(at.x + offset.x, at.y + offset.y)
				posts.append(Transform3D(Basis.IDENTITY, base + Vector3.UP * 0.65))
				lamps.append(Transform3D(Basis(Vector3.FORWARD, PI * 0.25), base + Vector3.UP * 1.45))
	SceneryInstances.build(parent, "FlowerStems", _box(Vector3(0.06, 0.44, 0.06), Color("91b9a4")), stems, 180)
	SceneryInstances.build(parent, "PeachBlossoms", _bloom(Color("ffd7ba")), peach, 180)
	SceneryInstances.build(parent, "LilacBlossoms", _bloom(Color("e8c1ed")), lilac, 180)
	SceneryInstances.build(parent, "PathLampPosts", _box(Vector3(0.13, 1.3, 0.13), Color("cba777")), posts, 180)
	SceneryInstances.build(parent, "GoldenPathLamps", _box(Vector3(0.32, 0.32, 0.32), Color("ffe8a4")), lamps, 180)

static func _box(size: Vector3, color: Color) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := MeadowGeometry.material(color)
	material.next_pass = null
	mesh.material = material
	return mesh

static func _bloom(color: Color) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = 1
	mesh.height = 2
	mesh.radial_segments = 8
	mesh.rings = 4
	var material := MeadowGeometry.material(color)
	material.next_pass = null
	mesh.material = material
	return mesh

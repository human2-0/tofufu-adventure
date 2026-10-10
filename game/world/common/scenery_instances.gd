class_name SceneryInstances
extends RefCounted
## Fixed-density cosmetic meshes in independently culled spatial batches.

const TILE_SIZE: float = 16.0
const MAX_BATCH: int = 512

static func build(parent: Node3D, title: String, mesh: Mesh, poses: Array[Transform3D], distance: float = 100.0) -> Node3D:
	var root := Node3D.new()
	root.name = title
	parent.add_child(root)
	var tiles: Dictionary[Vector2i, Array] = {}
	for pose: Transform3D in poses:
		var key := Vector2i(floori(pose.origin.x / TILE_SIZE), floori(pose.origin.z / TILE_SIZE))
		if not tiles.has(key): tiles[key] = []
		tiles[key].append(pose)
	for key: Vector2i in tiles:
		for start in range(0, tiles[key].size(), MAX_BATCH):
			var origin := Vector3(key.x * TILE_SIZE, 0, key.y * TILE_SIZE)
			var multi := MultiMesh.new()
			multi.transform_format = MultiMesh.TRANSFORM_3D
			multi.mesh = mesh
			multi.instance_count = mini(MAX_BATCH, tiles[key].size() - start)
			for i in multi.instance_count:
				var pose: Transform3D = tiles[key][start + i]
				pose.origin -= origin
				multi.set_instance_transform(i, pose)
			var view := MultiMeshInstance3D.new()
			view.name = "Tile_%d_%d_%d" % [key.x, key.y, start]
			view.position = origin
			view.multimesh = multi
			view.visibility_range_end = distance
			view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(view)
	return root

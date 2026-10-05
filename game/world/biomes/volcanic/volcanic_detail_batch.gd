class_name VolcanicDetailBatch
extends RefCounted
## Small scenery shares meshes/materials in spatial tiles so distant detail is culled.

var _tiles: Dictionary[String, Array] = {}
var _meshes: Dictionary[String, Mesh] = {}

func add(kind: String, at: Vector3, size: Vector3, color: Color, angle: float) -> void:
	var key := "%s:%d:%d" % [kind, floori(at.x / 40), floori(at.z / 40)]
	if not _tiles.has(key): _tiles[key] = []
	_tiles[key].append([Transform3D(Basis(Vector3.UP, angle).scaled(size), at), color, kind])

func build(parent: Node3D) -> void:
	for key in _tiles:
		var rows: Array = _tiles[key]
		var pool := MultiMeshInstance3D.new()
		pool.name = "VolcanicDetail_" + key.replace(":", "_")
		pool.multimesh = MultiMesh.new()
		pool.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		pool.multimesh.use_colors = true
		pool.multimesh.mesh = _mesh(rows[0][2])
		pool.multimesh.instance_count = rows.size()
		for i in rows.size():
			pool.multimesh.set_instance_transform(i, rows[i][0])
			pool.multimesh.set_instance_color(i, rows[i][1].srgb_to_linear())
			if rows[i][2] == "basalt": _collision(parent, rows[i][0])
		pool.visibility_range_end = 230.0 if rows[0][2] == "basalt" else 115.0
		pool.visibility_range_end_margin = 12.0
		pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(pool)

func _mesh(kind: String) -> Mesh:
	if _meshes.has(kind): return _meshes[kind]
	var mesh: PrimitiveMesh
	if kind in ["basalt", "crystal"]:
		var column := CylinderMesh.new()
		column.top_radius = 0.7 if kind == "basalt" else 0.0
		column.bottom_radius = 1.0
		column.height = 2.0
		column.radial_segments = 6
		mesh = column
	else:
		var stone := SphereMesh.new()
		stone.radius = 1.0
		stone.height = 2.0
		stone.radial_segments = 8
		stone.rings = 4
		mesh = stone
	var material := MeadowGeometry.material(Color.WHITE)
	material.vertex_color_use_as_albedo = true
	material.next_pass = null
	mesh.material = material
	_meshes[kind] = mesh
	return mesh

func _collision(parent: Node3D, pose: Transform3D) -> void:
	# Large columns retain physical blocking while tiny beach litter stays cosmetic.
	var body := StaticBody3D.new()
	body.name = "VolcanicBasaltCollision"
	body.collision_layer = 1
	body.collision_mask = 0
	body.transform = Transform3D(pose.basis.orthonormalized(), pose.origin)
	var size := pose.basis.get_scale()
	var vertices := PackedVector3Array()
	for i in 6:
		var angle := i * TAU / 6
		vertices.append(Vector3(sin(angle), -1, cos(angle)) * size)
		vertices.append(Vector3(sin(angle) * 0.7, 1, cos(angle) * 0.7) * size)
	var shape := ConvexPolygonShape3D.new()
	shape.points = vertices
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	parent.add_child(body)

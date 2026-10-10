class_name GroundOcclusion
extends Node3D
## Exact opaque heightfield tiles, enabled only when the camera is above each tile.

const TILE_SIZE: float = 24.0
const INSET: float = 0.04
var _tiles: Array[OccluderInstance3D] = []
var _tops: Array[float] = []

static func build(ground: MeshInstance3D) -> GroundOcclusion:
	var result := GroundOcclusion.new()
	result.name = "GroundOcclusion"
	result._build(ground.mesh.surface_get_arrays(0))
	ground.add_child(result)
	return result

func _ready() -> void:
	process_priority = -18 # Camera interpolation precedes local visibility decisions.

func _build(arrays: Array) -> void:
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var count := indices.size() if not indices.is_empty() else vertices.size()
	var tiles: Dictionary[Vector2i, PackedVector3Array] = {}
	for triangle in range(0, count, 3):
		var at := vertices[indices[triangle] if not indices.is_empty() else triangle]
		var key := Vector2i(floori(at.x / TILE_SIZE), floori(at.z / TILE_SIZE))
		if not tiles.has(key): tiles[key] = PackedVector3Array()
		var points := tiles[key]
		for corner in 3:
			points.append(vertices[indices[triangle + corner] if not indices.is_empty() else triangle + corner])
		tiles[key] = points
	for points: PackedVector3Array in tiles.values(): _tile(points)

func _tile(points: PackedVector3Array) -> void:
	var top := -INF
	var indices := PackedInt32Array()
	for i in points.size():
		top = maxf(top, points[i].y)
		points[i].y -= INSET
		indices.append(i)
	var shape := ArrayOccluder3D.new()
	shape.set_arrays(points, indices)
	var tile := OccluderInstance3D.new()
	tile.occluder = shape
	tile.visible = false
	add_child(tile)
	_tiles.append(tile)
	_tops.append(top)

func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera != null: present(camera.global_position)

func present(camera_position: Vector3) -> void:
	var height := to_local(camera_position).y
	for i in _tiles.size():
		# A one-sided floor is invisible from below; it must never hide the sky there.
		_tiles[i].visible = height > _tops[i] + INSET

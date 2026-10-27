class_name GigalopolisInteriorView
extends Node
## Height-aware local cutaways never remove floors or physical roof collision.

var actor: Player
var camera: Camera3D
var rooms: Array[Node3D] = []
var _cutaway: bool = true

func _process(_delta: float) -> void:
	var focus: Node3D = camera.target if camera is CameraFollow and camera.target != null else actor
	var indoors := false
	var indoor_camera := false
	for room in rooms:
		indoors = indoors or _inside(room, focus.global_position)
		indoor_camera = indoor_camera or _inside(room, camera.global_position)
	# A camera already inside the room sees its intact ceiling and walls.
	indoors = indoors and not indoor_camera
	# Outdoor views already show every wall/roof; avoid resubmitting unchanged geometry.
	if not indoors and not _cutaway: return
	_cutaway = indoors
	for room in rooms:
		var at := room.to_local(focus.global_position)
		var size: Vector3 = room.get_meta("city_size")
		var floor_y: float = room.get_meta("city_floor")
		var inside := indoors and absf(at.x) < size.x / 2 + 0.6 and absf(at.z) < size.z / 2 + 0.6 and at.y > floor_y - 0.6 and at.y < size.y - 0.4
		var bounds := AABB(Vector3(-size.x / 2, floor_y, -size.z / 2), Vector3(size.x, float(room.get_meta("city_roof_height")) - floor_y, size.z))
		var blocks := indoors and not inside and bounds.intersects_segment(room.to_local(camera.global_position), at + Vector3.UP) != null
		var direction := room.to_local(camera.global_position) - at
		for roof: MeshInstance3D in room.get_meta("interior_roofs"):
			roof.visible = not inside and not blocks
		for wall: MeshInstance3D in room.get_meta("interior_walls"):
			var toward := room.to_local(wall.global_position) - at
			wall.visible = not blocks and (not inside or Vector2(direction.x, direction.z).dot(Vector2(toward.x, toward.z)) <= 0)

func _inside(room: Node3D, point: Vector3) -> bool:
	var local := room.to_local(point)
	var size: Vector3 = room.get_meta("city_size")
	return absf(local.x) < size.x / 2 - 0.1 and absf(local.z) < size.z / 2 - 0.1 and local.y > float(room.get_meta("city_floor")) - 0.5 and local.y < size.y - 0.4

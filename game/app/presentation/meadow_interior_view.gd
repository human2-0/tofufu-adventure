class_name MeadowInteriorView
extends Node
## Local cutaway presentation keeps actors visible without changing solid geometry.

var actor: Node3D
var camera: Camera3D
var buildings: Array[Node3D] = []

func _process(_delta: float) -> void:
	for building in buildings:
		var size: Vector2 = building.get_meta("map_footprint")
		var at := building.to_local(actor.global_position)
		var inside := absf(at.x) < size.x / 2 + 1 and absf(at.z) < size.y / 2 + 1
		for roof: MeshInstance3D in building.get_meta("interior_roofs"):
			roof.visible = not inside
		var direction := building.to_local(camera.global_position) - at
		for wall: MeshInstance3D in building.get_meta("interior_walls"):
			var toward_wall := wall.position - at
			wall.visible = not inside or Vector2(direction.x, direction.z).dot(Vector2(toward_wall.x, toward_wall.z)) <= 0

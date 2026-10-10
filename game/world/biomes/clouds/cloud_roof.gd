class_name CloudRoof
extends Node3D
## One cutaway per complete pediment/roof prevents disconnected floating pieces.

func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera != null: visible = camera.global_position.distance_squared_to(global_position) >= 484

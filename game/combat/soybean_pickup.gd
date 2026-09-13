class_name SoybeanPickup
extends Sprite3D
## Drops settle under gravity, then latch onto a nearby collector and fly to them.

signal collected
@export var collector: Node3D
@export var attraction_radius: float = 3.5
@export var collection_radius: float = 0.28
@export var attraction_speed: float = 14.0
@export var attraction_acceleration: float = 32.0
var _age: float = 0.0
var _attracted: bool = false
var _collected: bool = false
var _speed: float = 3.0
var _fall_speed: float = 3.0
var _grounded: bool = false

func _ready() -> void:
	texture = preload("res://assets/combat/soybean.svg")
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	pixel_size = 0.01
	position.y += 0.3

func _physics_process(delta: float) -> void:
	if _collected:
		return
	_age += delta
	if _age > 60.0:
		queue_free()
		return
	if is_instance_valid(collector) and _age > 0.25:
		var destination := collector.global_position + Vector3.UP * 0.45
		if (_attracted or global_position.distance_to(destination) <= attraction_radius) and _clear_path(destination):
			_attracted = true
			_follow(destination, delta)
			return
	_settle(delta)
	offset.y = sin(_age * 4.0) * 7.0 if _grounded else 0.0

func _follow(destination: Vector3, delta: float) -> void:
	offset.y = 0.0
	_grounded = false
	_fall_speed = 0.0
	_speed = move_toward(_speed, attraction_speed, attraction_acceleration * delta)
	global_position = global_position.move_toward(destination, _speed * delta)
	if global_position.distance_to(destination) <= collection_radius:
		_collected = true
		collected.emit()
		queue_free()

func _clear_path(destination: Vector3) -> bool:
	var ray := PhysicsRayQueryParameters3D.create(global_position, destination, 1)
	return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func _settle(delta: float) -> void:
	if _grounded:
		return
	_fall_speed -= 14.0 * delta
	var destination := global_position + Vector3.UP * _fall_speed * delta
	if _fall_speed < 0.0:
		var ray := PhysicsRayQueryParameters3D.create(global_position, destination - Vector3.UP * 0.2, 1)
		var floor_hit := get_world_3d().direct_space_state.intersect_ray(ray)
		if not floor_hit.is_empty():
			destination = floor_hit.position + Vector3.UP * 0.2
			_grounded = true
			_fall_speed = 0.0
	global_position = destination

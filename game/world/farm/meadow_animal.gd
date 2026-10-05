class_name MeadowAnimal
extends Node3D
## Local decorative cats and poultry, with seeded bounded strolls on the ground.

var kind: String = "cat"
var home: Vector2
var roam_radius: float = 4.0
var ground_point: Callable
var seed_value: int = 1
var _rng := RandomNumberGenerator.new()
var _target: Vector2
var _pause: float = 0.0

func _ready() -> void:
	_rng.seed = seed_value
	_target = home
	position = ground_point.call(home.x, home.y)
	if kind == "cat": _cat()
	else: _chicken()

func _cat() -> void:
	var color: Color = [Color("c09162"), Color("4e5554"), Color("e2d9be"), Color("a7a296")][seed_value % 4]
	MeadowGeometry.rock(self, Vector3(0, 0.28, 0), Vector3(0.22, 0.23, 0.42), color)
	MeadowGeometry.rock(self, Vector3(0, 0.47, -0.3), Vector3(0.23, 0.23, 0.21), color)
	for side in [-1.0, 1.0]:
		var ear := MeadowGeometry.box(self, Vector3(side * 0.15, 0.69, -0.3), Vector3(0.12, 0.22, 0.12), color)
		ear.rotation.z = side * 0.25
		for z in [-0.26, 0.26]:
			MeadowGeometry.rock(self, Vector3(side * 0.14, 0.12, z), Vector3(0.065, 0.14, 0.065), color)
		MeadowGeometry.rock(self, Vector3(side * 0.1, 0.51, -0.49), Vector3(0.035, 0.04, 0.015), Color("bcd681"))
	var tail := MeadowGeometry.box(self, Vector3(0, 0.53, 0.46), Vector3(0.09, 0.55, 0.09), color)
	tail.rotation.x = 0.45

func _chicken() -> void:
	var young := kind == "chick"
	var color := Color("f6d777") if young else Color("eee6cd")
	MeadowGeometry.rock(self, Vector3(0, 0.4, 0), Vector3(0.27, 0.3, 0.35), color)
	MeadowGeometry.rock(self, Vector3(0, 0.65, -0.25), Vector3(0.18, 0.19, 0.18), color)
	MeadowGeometry.rock(self, Vector3(0, 0.64, -0.46), Vector3(0.09, 0.05, 0.12), Color("d99736"))
	if not young: MeadowGeometry.rock(self, Vector3(0, 0.86, -0.24), Vector3(0.07, 0.12, 0.12), Color("be4235"))
	for side in [-1.0, 1.0]:
		MeadowGeometry.box(self, Vector3(side * 0.09, 0.12, 0), Vector3(0.035, 0.24, 0.035), Color("c48a3e"))
	if young: scale = Vector3.ONE * 0.55

func _physics_process(delta: float) -> void:
	_pause -= delta
	if _pause > 0: return
	var at := Vector2(position.x, position.z)
	if at.distance_to(_target) < 0.1:
		var angle := _rng.randf_range(0, TAU)
		_target = home + Vector2(cos(angle), sin(angle)) * _rng.randf_range(0.3, roam_radius)
		_pause = _rng.randf_range(1, 4)
		return
	var next := at.move_toward(_target, delta * (0.6 if kind == "cat" else 0.3))
	var point: Vector3 = ground_point.call(next.x, next.y)
	var query := PhysicsRayQueryParameters3D.create(position + Vector3.UP * 0.25, point + Vector3.UP * 0.25, 1)
	if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
		_target = at
		_pause = 1.0
		return
	position = point
	rotation.y = atan2(at.x - _target.x, at.y - _target.y)

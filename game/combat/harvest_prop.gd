class_name HarvestProp
extends Node3D
## Renewable 3D breakable with an explicit damage receiver and loot signal.

signal harvested(at: Vector3, count: int)
@export_enum("Soy", "Crate", "Boulder") var kind: int = 0
var target: Damageable
var _body: StaticBody3D
var _regrow: float = 0.0
var _leaves: Array[MeshInstance3D] = []
var _time: float = 0.0

func _ready() -> void:
	_body = StaticBody3D.new()
	_body.collision_layer = 1
	_body.collision_mask = 0
	add_child(_body)
	target = Damageable.new()
	target.maximum = [20.0, 40.0, 90.0][kind]
	target.position.y = 0.6
	target.body = _body
	add_child(target)
	target.depleted.connect(_break_apart)
	target.hit.connect(_hit)
	_build_shape()

func _physics_process(delta: float) -> void:
	if _regrow > 0.0:
		_regrow -= delta
		if _regrow <= 0.0:
			visible = true
			_body.collision_layer = 1
			target.restore()

func _process(delta: float) -> void:
	_time += delta
	for leaf in _leaves:
		leaf.rotation.z = sin(_time * 1.8 + position.x + leaf.position.y) * 0.12

func _break_apart() -> void:
	harvested.emit(global_position, 2 if kind == 0 else 1)
	CombatEffects.burst(get_parent(), global_position, "SOY +2" if kind == 0 else "SMASH!", Color(0.8, 1, 0.6))
	visible = false
	_body.collision_layer = 0
	_regrow = 28.0

func _hit(_amount: float, _direction: Vector3) -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(1.2, 0.75, 1.2), 0.07)
	tween.tween_property(self, "scale", Vector3.ONE, 0.15)

func _build_shape() -> void:
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.45, 0.9, 0.45) if kind == 0 else Vector3(1.1, 1.1, 1.1)
	collider.shape = box
	collider.position.y = box.size.y * 0.5
	_body.add_child(collider)
	if kind == 0:
		_build_soy()
	elif kind == 1:
		_box(Vector3(1.1, 1.1, 1.1), Vector3(0, 0.55, 0), Color("aa714b"))
		for y in [0.15, 0.95]:
			_box(Vector3(1.16, 0.14, 1.16), Vector3(0, y, 0), Color("604c3b"))
		for x in [-0.4, 0.4]:
			_box(Vector3(0.1, 1.15, 1.15), Vector3(x, 0.56, 0), Color("ddb57a"))
	else:
		var rock := SphereMesh.new()
		rock.radius = 0.8
		rock.height = 1.3
		rock.radial_segments = 7
		rock.rings = 4
		_mesh(rock, Vector3(0, 0.6, 0), Color("869d9b"))

func _build_soy() -> void:
	_box(Vector3(0.09, 1.3, 0.09), Vector3(0, 0.65, 0), Color("5a753e"))
	for i in 5:
		var leaf := SphereMesh.new()
		leaf.radius = 0.3
		leaf.height = 0.18
		leaf.radial_segments = 7
		leaf.rings = 4
		var side := -1.0 if i % 2 == 0 else 1.0
		_leaves.append(_mesh(leaf, Vector3(side * 0.24, 0.45 + i * 0.17, 0), Color("71a74a")))
		var pod := SphereMesh.new()
		pod.radius = 0.12
		pod.height = 0.33
		_mesh(pod, Vector3(side * 0.22, 0.3 + i * 0.17, 0.12), Color("d5d77a"))

func _box(size: Vector3, at: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	_mesh(mesh, at, color)

func _mesh(mesh: PrimitiveMesh, at: Vector3, color: Color) -> MeshInstance3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	_body.add_child(instance)
	return instance

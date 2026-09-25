class_name FactoryCrate
extends Node3D
## Single-use breakable supply crate; loot decision belongs to dungeon composition.

signal broken(at: Vector3)
var target: Damageable
var _body: StaticBody3D

func _ready() -> void:
	_body = StaticBody3D.new()
	_body.collision_layer = 1
	_body.collision_mask = 0
	add_child(_body)
	var collision := CollisionShape3D.new()
	var bounds := BoxShape3D.new()
	bounds.size = Vector3(1.1, 1.0, 1.1)
	collision.shape = bounds
	collision.position.y = 0.5
	_body.add_child(collision)
	_box(Vector3(0, 0.5, 0), Vector3(1.08, 1.0, 1.08), Color("a88358"))
	for x in [-0.42, 0.42]: _box(Vector3(x, 0.52, 0.02), Vector3(0.1, 1.06, 1.13), Color("574b3d"))
	for y in [0.12, 0.88]: _box(Vector3(0, y, 0), Vector3(1.14, 0.1, 1.14), Color("dbc291"))
	var badge := Sprite3D.new()
	badge.texture = preload("res://assets/factory/soy_milk.svg")
	badge.pixel_size = 0.006
	badge.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	badge.position = Vector3(0, 0.55, 0.59)
	add_child(badge)
	target = Damageable.new()
	target.maximum = 35.0
	target.body = _body
	target.position.y = 0.5
	add_child(target)
	target.depleted.connect(_on_broken)

func _on_broken() -> void:
	_body.collision_layer = 0
	broken.emit(global_position)
	queue_free()

func _box(at: Vector3, size: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material = material
	var view := MeshInstance3D.new()
	view.mesh = mesh
	view.position = at
	add_child(view)

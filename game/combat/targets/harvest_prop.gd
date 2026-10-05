class_name HarvestProp
extends Node3D
## Renewable 3D breakable with an explicit damage receiver and loot signal.

signal harvested(at: Vector3, count: int)
@export_enum("Soy", "Crate", "Boulder") var kind: int = 0
var target: Damageable
var _body: StaticBody3D
var _regrow: float = 0.0
const SOY_REGROW_SECONDS: float = 60.0
var soy_visual: SoyPlantVisual

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
	target.damage_filter = _filter_damage
	_build_shape()

func _physics_process(delta: float) -> void:
	if _regrow > 0.0:
		_regrow = maxf(0.0, _regrow - delta)
		if is_zero_approx(_regrow): _regrow = 0.0
		if _regrow <= 0.0:
			target.restore()
			if kind == 0: target.invulnerability = 0.0
		present_growth()

func _filter_damage(amount: float, _direction: Vector3, _kind: Damageable.HitKind) -> float:
	return amount if _regrow <= 0.0 else 0.0

func present_growth() -> void:
	visible = kind == 0 or _regrow <= 0.0
	_body.collision_layer = 1 if _regrow <= 0.0 else 0
	if soy_visual != null:
		soy_visual.present(1.0 - clampf(_regrow / SOY_REGROW_SECONDS, 0.0, 1.0))

func _break_apart() -> void:
	# Currency enters the world only through soy plants (and mobs in encounter wiring).
	harvested.emit(global_position, 2 if kind == 0 else 0)
	CombatEffects.burst(get_parent(), global_position, "SOY +2" if kind == 0 else "SMASH!", Color(0.8, 1, 0.6))
	_regrow = SOY_REGROW_SECONDS if kind == 0 else 28.0
	present_growth()

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
		soy_visual = SoyPlantVisual.new()
		add_child(soy_visual)
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

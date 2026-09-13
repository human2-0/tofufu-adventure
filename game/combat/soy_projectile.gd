class_name SoyProjectile
extends Node3D
## Continuous segment collision prevents fast beans tunnelling through actors/walls.

var velocity: Vector3
var shooter: CollisionObject3D
var targets: Array[Damageable] = []
var authoritative: bool = true
var remaining: float = 1.5
var initial_path_start := Vector3.ZERO
var check_initial_path: bool = false
var visual_origin := Vector3.ZERO
var _sprite: Sprite3D
var _age: float = 0.0
var _visual_correction := Vector3.ZERO
var body_damage: float = 20.0
var head_damage: float = 40.0

func _ready() -> void:
	var sprite := Sprite3D.new()
	_sprite = sprite
	sprite.texture = preload("res://assets/combat/soybean.svg")
	sprite.pixel_size = 0.0018
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(sprite)

func _physics_process(delta: float) -> void:
	if _age == 0.0:
		_visual_correction = visual_origin - global_position
	_age += delta
	var destination := global_position + velocity * delta
	var exclude: Array[RID] = []
	if is_instance_valid(shooter): exclude.append(shooter.get_rid())
	var space := get_world_3d().direct_space_state
	var hit: Dictionary = {}
	if check_initial_path:
		var clearance := PhysicsRayQueryParameters3D.create(initial_path_start, global_position, 3, exclude)
		hit = space.intersect_ray(clearance)
	check_initial_path = false
	if hit.is_empty():
		var ray := PhysicsRayQueryParameters3D.create(global_position, destination, 3, exclude)
		hit = space.intersect_ray(ray)
	if not hit.is_empty():
		if authoritative: _hit(hit.collider, hit.position)
		queue_free()
		return
	global_position = destination
	remaining -= delta
	if remaining <= 0.0: queue_free()

func _hit(body: Object, point: Vector3) -> void:
	for target in targets:
		if not is_instance_valid(target) or target.body != body: continue
		var headshot := target.is_headshot(point)
		var amount := head_damage if headshot else body_damage
		if target.damage(amount, velocity.normalized() * 2.0):
			CombatEffects.burst(get_parent(), point, "40 HEAD!" if headshot else "20", Color("ffe4a0"))
		return

func _process(delta: float) -> void:
	_visual_correction = _visual_correction.move_toward(Vector3.ZERO, delta * 18.0)
	_sprite.global_position = global_position + _visual_correction

func place_visual(at: Vector3) -> void:
	visual_origin = at
	_visual_correction = at - global_position
	_sprite.global_position = at

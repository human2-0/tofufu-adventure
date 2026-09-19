class_name SoyProjectile
extends Node3D
## Continuous segment collision prevents fast beans tunnelling through actors/walls.

signal weapon_trained(weapon: String)

var owner_health: Damageable
var reflected_by: Damageable
var reflections: int = 0
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
	remaining -= delta
	if remaining <= 0.0:
		queue_free()
		return
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
		if _reflect(hit): return
		LiquidImpact.spawn(get_parent(), hit.position, hit.normal)
		if authoritative: _hit(hit.collider, hit.position)
		queue_free()
		return
	global_position = destination


func _hit(body: Object, point: Vector3) -> void:
	var receivers: Array[Damageable] = targets.duplicate()
	if is_instance_valid(owner_health) and owner_health not in receivers: receivers.append(owner_health)
	for target in receivers:
		if not is_instance_valid(target) or target.body != body: continue
		var headshot := target.is_headshot(point)
		var amount := head_damage if headshot else body_damage
		if target.damage(amount, velocity.normalized() * 2.0, Damageable.HitKind.SOY):
			CombatEffects.burst(get_parent(), point, "%d HEAD!" % int(amount) if headshot else str(int(amount)), Color("ffe4a0"))
			if target.trains_weapons:
				if is_instance_valid(reflected_by): reflected_by.reflected_hit.emit("shooting")
				elif reflections == 0: weapon_trained.emit("shooting")
		return

func _process(delta: float) -> void:
	_visual_correction = _visual_correction.move_toward(Vector3.ZERO, delta * 18.0)
	_sprite.global_position = global_position + _visual_correction

func place_visual(at: Vector3) -> void:
	visual_origin = at
	_visual_correction = at - global_position
	_sprite.global_position = at

func _reflect(hit: Dictionary) -> bool:
	var receivers: Array[Damageable] = targets.duplicate()
	if is_instance_valid(owner_health) and owner_health not in receivers: receivers.append(owner_health)
	for target in receivers:
		if not is_instance_valid(target) or target.body != hit.collider: continue
		var normal := target.reflection_normal(velocity, hit.position, authoritative)
		if normal.is_zero_approx() or reflections >= 4: return false
		velocity = velocity.bounce(normal)
		global_position = hit.position + normal * 0.04
		shooter = target.body
		reflected_by = target
		reflections += 1
		_visual_correction = Vector3.ZERO
		return true
	return false

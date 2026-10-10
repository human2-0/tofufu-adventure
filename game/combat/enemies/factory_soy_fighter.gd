class_name FactorySoyFighter
extends FactoryBean
## Fixed-roster factory foe with separate knife and finite Soyjet cycles.

signal sprayed(amount: float, source: Vector3, victim: Node3D)
signal stance_changed(stance: String)

const RESERVOIR_SECONDS: float = 1.8
const REFILL_SECONDS: float = 2.0
const SPRAY_INTERVAL: float = 0.24
const SPRAY_DAMAGE: float = 4.0
const KNIFE_DAMAGE: float = 11.0

var _milk: float = RESERVOIR_SECONDS
var _refill: float = 0.0
var _spray_wait: float = 0.0
var _knife_wait: float = 0.0
var _knife_windup: float = 0.0
var _stance: String = "idle"

func _physics_process(delta: float) -> void:
	if not _alive or not is_instance_valid(quarry): return
	if reaction.step(delta): return
	var offset := quarry.global_position - global_position
	offset.y = 0.0
	var distance := offset.length()
	if distance < 10.0: targeting.emit(quarry)
	_spray_wait = maxf(0.0, _spray_wait - delta)
	_knife_wait = maxf(0.0, _knife_wait - delta)
	_refill = maxf(0.0, _refill - delta)
	var direction := Vector3.ZERO
	if reaction.stagger > 0.0 or (not is_on_floor() and velocity.y != 0.0):
		_set_stance("stagger")
	elif _knife_windup > 0.0:
		_knife_windup -= delta
		if _knife_windup <= 0.0:
			_warning.visible = false
			if distance < 2.2 and _clear_attack(): attacked.emit(KNIFE_DAMAGE * damage_scale, global_position)
			_knife_wait = 1.2
			_set_stance("knife recovery")
	elif distance < 1.8 and _knife_wait <= 0.0:
		_knife_windup = 0.7
		_warning.text = "! Knife"
		_warning.visible = true
		_set_stance("knife windup")
	elif distance >= 2.2 and distance <= 7.5 and _milk > 0.0 and _refill <= 0.0 and _clear_attack():
		_set_stance("Soyjet")
		_milk = maxf(0.0, _milk - delta)
		if _spray_wait <= 0.0:
			_spray_wait = SPRAY_INTERVAL
			if _clear_spray(): sprayed.emit(SPRAY_DAMAGE * damage_scale, global_position, quarry)
		if _milk <= 0.0:
			_refill = REFILL_SECONDS
			_set_stance("reservoir recovery")
	elif _refill > 0.0:
		_set_stance("reservoir recovery")
	elif distance < 9.0 and _clear_attack():
		_set_stance("approach")
		direction = offset.normalized() * SPEED[kind]
	else:
		_set_stance("idle")
	if _refill <= 0.0 and _milk <= 0.0: _milk = RESERVOIR_SECONDS
	velocity.x = direction.x + _knockback.x
	velocity.z = direction.z + _knockback.z
	velocity.y -= 25.0 * delta
	_knockback = _knockback.move_toward(Vector3.ZERO, 18.0 * delta)
	move_and_slide()

func _clear_spray() -> bool:
	var from := global_position + Vector3.UP * 0.8
	var to := quarry.global_position + Vector3.UP * 0.8
	var query := PhysicsRayQueryParameters3D.create(from, to, 3, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.get("collider") == quarry

func _set_stance(next: String) -> void:
	if _stance == next: return
	_stance = next
	stance_changed.emit(next)

func _on_hit(amount: float, direction: Vector3) -> void:
	super._on_hit(amount, direction)
	_knife_windup = 0.0
	_warning.visible = false
	_set_stance("stagger")

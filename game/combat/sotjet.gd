class_name Sotjet
extends Node
## Slot-4 pressure stream and per-instance regenerating soymilk reservoir.

signal weapon_trained(weapon: String)
var actor: CollisionObject3D
var tuning := SotjetTuning.new()
var selected: bool = false
var aiming: bool = false
var firing: bool = false
var milk: float = 100.0
var sequence: int = 0
var origin := Vector3.ZERO
var velocity := Vector3.ZERO
var flow: SotjetFlow
var visual: SotjetVisual
var _refill_wait: float = 0.0
var _burst: int = 0
var _replica: bool = false
var _replica_age: float = 1.0
var _last_sequence: int = -1

func _ready() -> void:
	milk = tuning.capacity
	visual = SotjetVisual.new()
	add_child(visual)
	flow = SotjetFlow.new()
	flow.shooter = actor
	flow.tuning = tuning
	flow.weapon_trained.connect(weapon_trained.emit)
	add_child(flow)

func step(held: bool, precise: bool, aim: Vector2, aim_point: Vector3, delta: float) -> void:
	aiming = selected and precise
	visual.visible = selected
	visual.facing = aim
	var was_firing := firing
	firing = selected and held and milk >= tuning.consumption * delta
	if firing:
		if not was_firing: _burst += 1
		milk = maxf(0.0, milk - tuning.consumption * delta)
		_refill_wait = tuning.refill_delay
		origin = muzzle_position(aim)
		velocity = (aim_point - origin).normalized() * tuning.speed
		if velocity.is_zero_approx(): velocity = Vector3(aim.x, 0, aim.y) * tuning.speed
		sequence += 1
		flow.emit_milk(origin, velocity, _burst, actor.global_position + Vector3.UP * 0.78)
	else:
		_refill_wait = maxf(0.0, _refill_wait - delta)
		if _refill_wait <= 0.0 and not held: milk = minf(tuning.capacity, milk + tuning.refill_rate * delta)
	_present_nozzle()

func muzzle_position(aim: Vector2) -> Vector3:
	var forward := Vector3(aim.x, 0, aim.y).normalized()
	return actor.global_position + Vector3.UP * 0.78 + forward.cross(Vector3.UP) * 0.32 + forward * 0.5

func _present_nozzle() -> void:
	visual.refresh()
	flow.visual.nozzle = visual.muzzle_position()
	flow.visual.pouring = firing and (not _replica or _replica_age <= 0.2)

func use_replica() -> void:
	_replica = true
	flow.authoritative = false

func present(state: Dictionary, facing: Vector2) -> void:
	selected = state.get("jet", false)
	aiming = selected and state.get("jet_ads", false)
	milk = state.get("milk", tuning.capacity)
	visual.visible = selected
	visual.facing = facing
	var next_sequence := int(state.get("jet_sequence", 0))
	if next_sequence > _last_sequence:
		_replica_age = 0.0
		_last_sequence = next_sequence
	var next_firing: bool = selected and state.get("jet_firing", false)
	if next_firing and not firing: _burst += 1
	firing = next_firing
	origin = CombatState._vector(state.get("jet_origin", [0,0,0]))
	velocity = CombatState._vector(state.get("jet_velocity", [0,0,0]))
	_present_nozzle()

func _physics_process(delta: float) -> void:
	if not _replica: return
	_replica_age += delta
	if firing and _replica_age <= 0.2:
		flow.emit_milk(origin, velocity, _burst, actor.global_position + Vector3.UP * 0.78)
	flow.visual.pouring = firing and _replica_age <= 0.2

func reset() -> void:
	firing = false
	aiming = false
	_refill_wait = tuning.refill_delay
	flow.clear()

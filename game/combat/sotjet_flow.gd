class_name SotjetFlow
extends Node3D
## Bounded ballistic fluid parcels and swept first-contact hits on physics ticks.

signal weapon_trained(weapon: String)
var owner_health: Damageable
var shooter: CollisionObject3D
var targets: Array[Damageable] = []
var tuning: SotjetTuning
var authoritative: bool = true
var push_multiplier: float = 1.0
var damage_multiplier: float = 1.0
var parcels: Array[SotjetParcel] = []
var visual: SotjetStreamVisual
var _sequence: int = 0
var _clock: float = 0.0
var _splash_until: float = 0.0
var _hit_until: Dictionary[int, float] = {}

func _ready() -> void:
	visual = SotjetStreamVisual.new()
	visual.parcels = parcels
	visual.radius = tuning.radius
	add_child(visual)

func emit_milk(origin: Vector3, velocity: Vector3, burst: int, path_start: Vector3) -> void:
	if parcels.size() >= 96: return
	# Sweep actor-to-nozzle too, so the outboard muzzle cannot bypass cover.
	var parcel := SotjetParcel.new()
	if visual.nozzle_provider.is_valid():
		parcel.visual_offset = Vector3(visual.nozzle_provider.call()) - origin
	parcel.position = origin
	parcel.previous = origin
	parcel.velocity = velocity
	parcel.burst = burst
	parcel.excluded_body = shooter
	var blocked := _ray(path_start, origin, shooter)
	if not blocked.is_empty() and not _resolve(parcel, blocked): return
	_sequence += 1
	parcel.sequence = _sequence
	parcels.append(parcel)

func _physics_process(delta: float) -> void:
	_clock += delta
	for index in range(parcels.size() - 1, -1, -1):
		var parcel := parcels[index]
		parcel.advance(delta, tuning.gravity)
		if parcel.age >= tuning.lifetime:
			parcels.remove_at(index)
			continue
		var hit := _ray(parcel.previous, parcel.position, parcel.excluded_body)
		if not hit.is_empty():
			if not _resolve(parcel, hit): parcels.remove_at(index)
	for id: int in _hit_until.keys():
		if _hit_until[id] <= _clock: _hit_until.erase(id)

func _ray(from: Vector3, to: Vector3, excluded_body: CollisionObject3D) -> Dictionary:
	var excluded: Array[RID] = []
	if is_instance_valid(excluded_body): excluded.append(excluded_body.get_rid())
	var ray := PhysicsRayQueryParameters3D.create(from, to, 3, excluded)
	return get_world_3d().direct_space_state.intersect_ray(ray)

func _impact(hit: Dictionary, velocity: Vector3, reflected_by: Damageable = null, reflections: int = 0) -> void:
	if _clock >= _splash_until:
		visual.splash(hit.position, hit.normal)
		_splash_until = _clock + 0.08
	if not authoritative: return
	for target in _receivers():
		if not is_instance_valid(target) or target.body != hit.collider: continue
		var id := target.get_instance_id()
		if _hit_until.has(id): return
		_hit_until[id] = _clock + tuning.damage_interval
		var damage := tuning.damage_per_second * tuning.damage_interval * damage_multiplier
		var impulse := Vector3(velocity.x, 0.0, velocity.z).normalized() * tuning.push_speed * push_multiplier
		if target.damage(damage, impulse, Damageable.HitKind.SOY):
			if target.current > 0.0 and target.invulnerability <= 0.0: target.pushed.emit(impulse)
			CombatEffects.damage_number(self, target, target.last_hit_amount)
			if target.trains_weapons:
				if is_instance_valid(reflected_by): reflected_by.reflected_hit.emit("shooting")
				elif reflections == 0: weapon_trained.emit("shooting")
		return

func clear() -> void:
	parcels.clear()
	_hit_until.clear()
	visual.pouring = false

func _receivers() -> Array[Damageable]:
	var result := targets.duplicate()
	if is_instance_valid(owner_health) and owner_health not in result: result.append(owner_health)
	return result

func _resolve(parcel: SotjetParcel, hit: Dictionary) -> bool:
	for target in _receivers():
		if not is_instance_valid(target) or target.body != hit.collider: continue
		var normal := target.reflection_normal(parcel.velocity, hit.position, authoritative)
		if normal.is_zero_approx() or parcel.reflections >= 4: break
		parcel.velocity = parcel.velocity.bounce(normal)
		parcel.position = hit.position + normal * 0.04
		parcel.previous = parcel.position
		parcel.excluded_body = target.body
		parcel.reflected_by = target
		parcel.reflections += 1
		return true
	_impact(hit, parcel.velocity, parcel.reflected_by, parcel.reflections)
	return false

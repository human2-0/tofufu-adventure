class_name PlayerCombat
extends Node
## Wind-up, cutting arc and recovery. Only the swept steel deals damage.

signal weapon_trained(weapon: String)
var sword_damage_multiplier: float = 1.0
var fist_damage_multiplier: float = 1.0
var attack_speed_multiplier: float = 1.0
var incoming_damage_multiplier: float = 1.0
var _trained: bool = false

signal charge_changed(value: float)
signal struck(strength: float, hits: int)

@export var actor: Node3D
@export var tuning: CombatTuning = CombatTuning.new()
var equipment: PlayerEquipment
var targets: Array[Damageable] = []
var rules: MeleeRules
var sotjet: Sotjet
var gun: SoyGun
var sword: SwordVisual
var active: bool = false
var attack_aim: Vector2 = Vector2.DOWN
var _elapsed: float = 0.0
var _strength: float = 0.0
var _hit_targets: Array[Damageable] = []
var _shape: BoxShape3D
var _previous_at: Vector3
var _previous_progress: float = 0.0
var _trail: SwordTrail

func _ready() -> void:
	rules = MeleeRules.new(tuning)
	equipment = PlayerEquipment.new()
	equipment.combat = self
	add_child(equipment)
	sword = SwordVisual.new()
	sword.tuning = tuning
	add_child(sword)
	_trail = SwordTrail.new()
	add_child(_trail)
	gun = SoyGun.new()
	gun.actor = actor as CollisionObject3D
	gun.tuning = tuning
	add_child(gun)
	sotjet = Sotjet.new()
	sotjet.actor = actor as CollisionObject3D
	add_child(sotjet)
	_shape = BoxShape3D.new()
	_shape.size = Vector3(tuning.blade_width, tuning.blade_thickness, tuning.blade_length)

func step(aim: Vector2, held: bool, delta: float, resting_aim: Vector2 = Vector2.ZERO) -> void:
	held = held and not equipment.suppress_slash()
	var strength := rules.step(held, delta, attack_speed_multiplier)
	charge_changed.emit(rules.charge)
	if strength >= 0.0 and not active:
		strike(aim, strength)
	var progress := -1.0
	var facing := aim if held or resting_aim.is_zero_approx() else resting_aim
	var heavy := _strength >= 1.0
	if active:
		var duration := tuning.heavy_swing_seconds if heavy else tuning.swing_seconds
		_elapsed = minf(duration, _elapsed + delta * attack_speed_multiplier)
		progress = _elapsed / duration
		_sample_sweep(progress)
		facing = attack_aim
		if progress >= 1.0:
			active = false
	var pose := SwordGeometry.pose(actor.global_position, facing, progress, tuning, heavy)
	if equipment.guarding:
		facing = equipment.facing
		pose = SwordGeometry.guard_pose(actor.global_position, facing, tuning)
	var cutting := active and SwordGeometry.cutting(progress, tuning)
	var attachment := 1.0
	if active:
		attachment = 1.0 - smoothstep(0.0, tuning.cut_start, progress) if progress < tuning.cut_start else smoothstep(tuning.cut_end, 1.0, progress)
	if equipment.guarding:
		attachment = 0.0
	sword.present(pose, facing, maxf(rules.charge, _strength if active else 0.0), cutting, attachment)
	_trail.record(pose, tuning, cutting, heavy)

func strike(aim: Vector2, strength: float) -> void:
	if active or equipment.suppress_slash():
		return
	active = true
	attack_aim = SwordGeometry.direction(aim)
	_strength = clampf(strength, 0, 1)
	_elapsed = 0.0
	_hit_targets.clear()
	_trained = false
	_previous_at = actor.global_position
	_previous_progress = 0.0

func reset() -> void:
	equipment.reset()
	gun.reset()
	sotjet.reset()
	active = false
	rules = MeleeRules.new(tuning)
	_hit_targets.clear()
	_trail.record(Transform3D.IDENTITY, tuning, false, false)

func _sample_sweep(progress: float) -> void:
	var heavy := _strength >= 1.0
	var radius := tuning.hand_radius + tuning.grip_length + tuning.blade_length
	var arc := deg_to_rad(tuning.heavy_arc_degrees if heavy else tuning.light_arc_degrees)
	var travel := actor.global_position.distance_to(_previous_at)
	travel += (progress - _previous_progress) / (tuning.cut_end - tuning.cut_start) * (arc + 1.2) * radius
	var samples := maxi(1, ceili(travel / (tuning.blade_width * 0.4)))
	for index in samples:
		var fraction := float(index + 1) / samples
		var sample_progress := lerpf(_previous_progress, progress, fraction)
		if SwordGeometry.cutting(sample_progress, tuning):
			var at := _previous_at.lerp(actor.global_position, fraction)
			_resolve_blade(at, SwordGeometry.pose(at, attack_aim, sample_progress, tuning, heavy))
	_previous_at = actor.global_position
	_previous_progress = progress

func _resolve_blade(at: Vector3, pose: Transform3D) -> void:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _shape
	query.transform = SwordGeometry.blade_transform(pose, tuning)
	query.collision_mask = 3
	query.margin = 0.0
	if actor is CollisionObject3D:
		query.exclude = [actor.get_rid()]
	var overlaps := actor.get_world_3d().direct_space_state.intersect_shape(query, 64)
	for overlap in overlaps:
		for target in targets:
			if not is_instance_valid(target) or target in _hit_targets or target.current <= 0.0:
				continue
			if target.body == overlap.collider and _unobstructed(at, target):
				_damage(target)

func _unobstructed(at: Vector3, target: Damageable) -> bool:
	var origin := at + Vector3.UP * tuning.hand_height
	var query := PhysicsRayQueryParameters3D.create(origin, target.global_position, 1)
	var obstacle := actor.get_world_3d().direct_space_state.intersect_ray(query)
	return obstacle.is_empty() or obstacle.collider == target.body

func _damage(target: Damageable) -> void:
	var heavy := _strength >= 1.0
	var damage := (tuning.heavy_damage if heavy else tuning.light_damage) * sword_damage_multiplier
	var direction := Vector3(attack_aim.x, 0, attack_aim.y)
	if target.damage(damage, direction * (12.0 if heavy else 5.0)):
		_hit_targets.append(target)
		if target.trains_weapons and not _trained:
			_trained = true
			weapon_trained.emit("sword")
		CombatEffects.burst(self, target.global_position, str(int(damage)), Color(1, 0.86, 0.4))
		struck.emit(_strength, 1)

func ranged_selected() -> bool:
	return gun.selected or sotjet.selected

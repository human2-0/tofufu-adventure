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
signal combo_changed(count: int, critical_chance: float)
signal clashed
@export var actor: Node3D
@export var tuning: CombatTuning = CombatTuning.new()
var equipment: PlayerEquipment
var targets: Array[Damageable] = []
var rules: MeleeRules
var combo: KnifeCombo
var clash: MeleeClash
var owner_health: Damageable
var sotjet: Sotjet
var gun: SoyGun
var sword: SwordVisual
var staff: StaffVisual
var active: bool = false
var attack_aim: Vector2 = Vector2.DOWN
var _elapsed: float = 0.0
var _strength: float = 0.0
var _hit_targets: Array[Damageable] = []
var _shape: BoxShape3D
var _previous_at: Vector3
var _previous_progress: float = 0.0
var _trail: SwordTrail
var attack_style: int = KnifeAttack.Style.SLASH
var critical_roll: Callable
var _attack_critical_chance: float = 0.0
var _secondary_was_held: bool = false
func _ready() -> void:
	rules = MeleeRules.new(tuning)
	combo = KnifeCombo.new(tuning)
	clash = MeleeClash.new()
	equipment = PlayerEquipment.new()
	equipment.combat = self
	add_child(equipment)
	sword = SwordVisual.new()
	sword.tuning = tuning
	add_child(sword)
	staff = StaffVisual.new()
	add_child(staff)
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
func step(aim: Vector2, held: bool, delta: float, resting_aim: Vector2 = Vector2.ZERO, airborne: bool = false, secondary_held: bool = false) -> void:
	held = held and not equipment.suppress_slash()
	if combo.step(delta):
		_emit_combo()
	var strength := rules.step(held, delta, attack_speed_multiplier)
	var secondary_pressed := secondary_held and not _secondary_was_held
	_secondary_was_held = secondary_held
	if secondary_pressed and equipment.staff_selected and not active and not held and rules.cooldown <= 0.0:
		_start_tornado(aim)
	charge_changed.emit(rules.charge)
	if strength >= 0.0 and not active:
		strike(aim, strength, airborne)
	var progress := -1.0
	var facing := aim if held or resting_aim.is_zero_approx() else resting_aim
	var heavy := KnifeAttack.powered(attack_style) or attack_style == StaffAttack.TORNADO
	if active:
		var duration := _attack_duration()
		_elapsed = minf(duration, _elapsed + delta * attack_speed_multiplier)
		progress = _elapsed / duration
		_sample_sweep(progress)
		facing = attack_aim
		if progress >= 1.0:
			active = false
			if combo.finish_attack():
				_emit_combo()
	var pose := _attack_pose(actor.global_position, facing, progress)
	if equipment.guarding:
		facing = equipment.facing
		pose = SwordGeometry.guard_pose(actor.global_position, facing, tuning)
	var cutting := active and SwordGeometry.cutting(progress, tuning)
	clash.record(pose, cutting)
	var attachment := 1.0
	if active:
		attachment = 1.0 - smoothstep(0.0, tuning.cut_start, progress) if progress < tuning.cut_start else smoothstep(tuning.cut_end, 1.0, progress)
	if equipment.guarding:
		attachment = 0.0
	sword.present(pose, facing, maxf(rules.charge, _strength if active else 0.0), cutting, attachment)
	staff.present(pose, rules.charge, active and attack_style == StaffAttack.TORNADO)
	_trail.record(pose, tuning, cutting, heavy, _melee_length())
func strike(aim: Vector2, strength: float, airborne: bool = false) -> void:
	if active or equipment.suppress_slash():
		return
	active = true
	attack_aim = SwordGeometry.direction(aim)
	_strength = clampf(strength, 0, 1)
	attack_style = KnifeAttack.select(_strength, combo.can_stab(), airborne, tuning)
	_set_melee_shape()
	clash.clear()
	_attack_critical_chance = combo.critical_chance()
	combo.begin_attack()
	_elapsed = 0.0
	_hit_targets.clear()
	_trained = false
	_previous_at = actor.global_position
	_previous_progress = 0.0

func _start_tornado(aim: Vector2) -> void:
	rules.cancel_charge()
	rules.cooldown = tuning.staff_tornado_cooldown
	clash.clear()
	active = true
	attack_aim = SwordGeometry.direction(aim)
	attack_style = StaffAttack.TORNADO
	_strength = 0.0
	_attack_critical_chance = 0.0
	combo.begin_attack()
	_set_melee_shape()
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
	_secondary_was_held = false
	clash.clear()
	rules = MeleeRules.new(tuning)
	combo = KnifeCombo.new(tuning)
	attack_style = KnifeAttack.Style.SLASH
	_attack_critical_chance = 0.0
	_hit_targets.clear()
	_trail.record(Transform3D.IDENTITY, tuning, false, false)
	_emit_combo()
func _sample_sweep(progress: float) -> void:
	var heavy := KnifeAttack.powered(attack_style)
	var radius := tuning.hand_radius + tuning.grip_length + _melee_length()
	var travel := actor.global_position.distance_to(_previous_at)
	if attack_style == KnifeAttack.Style.STAB:
		travel += absf(progress - _previous_progress) / (tuning.cut_end - tuning.cut_start) * 1.1
	else:
		var arc := TAU if attack_style == StaffAttack.TORNADO else deg_to_rad(tuning.heavy_arc_degrees if heavy else tuning.light_arc_degrees)
		travel += (progress - _previous_progress) / (tuning.cut_end - tuning.cut_start) * (arc + 1.2) * radius
	var samples := maxi(1, ceili(travel / (_melee_width() * 0.4)))
	for index in samples:
		var fraction := float(index + 1) / samples
		var sample_progress := lerpf(_previous_progress, progress, fraction)
		if SwordGeometry.cutting(sample_progress, tuning):
			var at := _previous_at.lerp(actor.global_position, fraction)
			var pose := _attack_pose(at, attack_aim, sample_progress)
			clash.record(pose, true)
			_resolve_blade(at, pose)
	_previous_at = actor.global_position
	_previous_progress = progress

func _resolve_blade(at: Vector3, pose: Transform3D) -> void:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _shape
	query.transform = pose.translated_local(Vector3(0, 0, -_melee_length() * 0.5))
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
				var opponent := clash.opponent_for(self, target)
				if opponent != null:
					clash.resolve(self, opponent)
					return
				_damage(target)

func _unobstructed(at: Vector3, target: Damageable) -> bool:
	var origin := at + Vector3.UP * tuning.hand_height
	var query := PhysicsRayQueryParameters3D.create(origin, target.global_position, 1)
	var obstacle := actor.get_world_3d().direct_space_state.intersect_ray(query)
	return obstacle.is_empty() or obstacle.collider == target.body

func _damage(target: Damageable) -> void:
	var base_damage := _melee_damage()
	var critical := _attack_critical_chance > 0.0 and _critical_roll() < _attack_critical_chance
	var damage := base_damage * sword_damage_multiplier
	if critical:
		damage *= tuning.combo_critical_damage_multiplier
	var impulse := KnifeAttack.impulse(attack_style, attack_aim, tuning)
	if attack_style == StaffAttack.TORNADO:
		var outward := target.global_position - actor.global_position
		impulse = Vector3(outward.x, 0.0, outward.z).normalized() * 5.0
	var kind := Damageable.HitKind.MELEE if equipment.staff_selected else Damageable.HitKind.KNIFE
	if target.damage(damage, impulse, kind):
		_hit_targets.append(target)
		if combo.confirm_hit():
			_emit_combo()
		if target.trains_weapons and not _trained:
			_trained = true
		weapon_trained.emit("sword")
		var text := "CRIT! %d" % int(damage) if critical else str(int(damage))
		CombatEffects.burst(self, target.global_position, text, Color("ff8f7f") if critical else Color(1, 0.86, 0.4))
		struck.emit(_strength, 1)

func _critical_roll() -> float:
	return float(critical_roll.call()) if critical_roll.is_valid() else randf()

func _emit_combo() -> void:
	combo_changed.emit(combo.count, combo.critical_chance())

func ranged_selected() -> bool:
	return gun.selected or sotjet.selected

func _set_melee_shape() -> void:
	_shape.size = Vector3(_melee_width(), tuning.blade_thickness, _melee_length())

func _melee_length() -> float:
	return tuning.staff_length if equipment.staff_selected else tuning.blade_length

func _melee_width() -> float:
	return tuning.staff_width if equipment.staff_selected else tuning.blade_width

func _melee_tip(pose: Transform3D) -> Vector3:
	return pose * Vector3(0, 0, -_melee_length())

func _melee_damage() -> float:
	if equipment.staff_selected:
		return StaffAttack.damage(attack_style, tuning)
	return KnifeAttack.damage(attack_style, tuning)

func _attack_duration() -> float:
	return StaffAttack.duration(attack_style, tuning)

func _attack_pose(at: Vector3, aim: Vector2, progress: float) -> Transform3D:
	return StaffAttack.pose(attack_style, at, aim, progress, tuning)

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
var vitals := VitalRules.new()
var special_attack: bool = false
var equipment: PlayerEquipment
var targets: Array[Damageable] = []
var rules: MeleeRules
var combo: KnifeCombo
var clash: MeleeClash
var owner_health: Damageable
var sotjet: Sotjet
var gun: SoyGun
var sword: SwordVisual
var podburst := Podburst.new()
var plunge := NoriPlunge.new()
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
	podburst.cooldown = maxf(0.0, podburst.cooldown - delta)
	if plunge.active and not secondary_held: plunge.released = true
	plunge.step(self, delta)
	if plunge.active or plunge.recovery > 0.0:
		sword.present(plunge.pose(actor.global_position), aim, 1.0, true, 0.0)
		return
	held = held and not equipment.suppress_slash()
	if combo.step(delta):
		_emit_combo()
	var strength := rules.step(held, delta, melee_speed())
	var secondary_pressed := secondary_held and not _secondary_was_held
	_secondary_was_held = secondary_held
	if secondary_pressed and equipment.staff_selected and not active and not held and rules.cooldown <= 0.0:
		_start_tornado(aim)
	if secondary_pressed and equipment.pod_selected and not active and not held and not equipment.suppress_slash() and rules.cooldown <= 0.0:
		podburst.fire(self, aim)
	if secondary_pressed and equipment.nori_selected and not active and not held and not equipment.suppress_slash() and rules.cooldown <= 0.0:
		plunge.start(self, aim)
		if plunge.active: return
	charge_changed.emit(rules.charge)
	if strength >= 0.0 and not active:
		strike(aim, strength, airborne)
	var progress := -1.0
	var facing := aim if held or resting_aim.is_zero_approx() else resting_aim
	var heavy := KnifeAttack.powered(attack_style) or attack_style == StaffAttack.TORNADO
	if active:
		var duration := _attack_duration()
		_elapsed = minf(duration, _elapsed + delta * melee_speed())
		progress = _elapsed / duration
		_sample_sweep(progress)
		facing = attack_aim
		if progress >= 1.0:
			active = false
			if combo.finish_attack():
				_emit_combo()
	MeleePose.present(self, facing, progress, heavy)

func strike(aim: Vector2, strength: float, airborne: bool = false) -> void:
	if active or equipment.suppress_slash():
		return
	MeleeStart.strike(self, aim, strength, airborne)

func _start_tornado(aim: Vector2) -> void:
	MeleeStart.tornado(self, aim)

func reset() -> void:
	plunge.cancel()
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
	MeleeSweep.sample_sweep(self, progress)

func _resolve_blade(at: Vector3, pose: Transform3D) -> void:
	MeleeSweep.resolve_blade(self, at, pose)

func _unobstructed(at: Vector3, target: Damageable) -> bool:
	return MeleeSweep.unobstructed(self, at, target)

func _damage(target: Damageable, point: Vector3 = Vector3.INF) -> void:
	MeleeSweep.damage(self, target, point)

func _emit_combo() -> void:
	combo_changed.emit(combo.count, combo.critical_chance())

func ranged_selected() -> bool:
	return gun.selected or sotjet.selected

func _set_melee_shape() -> void:
	_shape.size = Vector3(_melee_width(), tuning.blade_thickness, _melee_length())

func _melee_length() -> float:
	if equipment.nori_selected: return tuning.nori_length
	if equipment.pod_selected: return tuning.pod_length
	return tuning.staff_length if equipment.staff_selected else tuning.blade_length

func _melee_width() -> float:
	if equipment.pod_selected: return tuning.pod_width
	return tuning.staff_width if equipment.staff_selected else tuning.blade_width

func _melee_tip(pose: Transform3D) -> Vector3:
	return pose * Vector3(0, 0, -_melee_length())

func _melee_damage() -> float:
	if equipment.staff_selected:
		return StaffAttack.damage(attack_style, tuning)
	return KnifeAttack.damage(attack_style, tuning) * (1.2 if equipment.pod_selected else 1.0)

func melee_speed() -> float:
	return attack_speed_multiplier * (tuning.nori_speed if equipment.nori_selected else 1.0)

func _attack_duration() -> float:
	return StaffAttack.duration(attack_style, tuning)

func _attack_pose(at: Vector3, aim: Vector2, progress: float) -> Transform3D:
	return StaffAttack.pose(attack_style, at, aim, progress, tuning)

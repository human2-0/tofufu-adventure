class_name PlayerEquipment
extends Node
## Per-actor knife slot, unarmed attacks and directional defence.

signal projectile_defended
signal defended
signal changed(knife_owned: bool, knife_selected: bool, guarding: bool)
signal punch_cadence_updated(remaining: float, total: float, damage: int, hit_rate: float)
var combat: PlayerCombat
var knife_owned: bool = true
var knife_selected: bool = true
var guarding: bool = false
var facing: Vector2 = Vector2.DOWN
var dropped: Node3D
var gun_owned: bool = true
var sotjet_owned: bool = true
var staff_owned: bool = false
var staff_selected: bool = false
var drop_item: Callable
var pickup_item: Callable
var select_item: Callable
var _reflection_feedback: float = 0.0
var _punch_time: float = 0.0

func punch_hit_rate() -> float:
	var cd: float = combat.tuning.punch_cooldown if combat != null and combat.tuning != null else 0.38
	var mult: float = combat.attack_speed_multiplier if combat != null else 1.0
	return mult / cd

func punch_damage() -> int:
	var base: float = combat.tuning.punch_damage if combat != null and combat.tuning != null else 12.0
	var mult: float = combat.fist_damage_multiplier if combat != null else 1.0
	return int(base * mult)

func step(aim: Vector2, guard: bool, punch: bool, drop: bool, pickup: bool, slot: int, delta: float, pickup_id: int = -1) -> void:
	_reflection_feedback = maxf(0.0, _reflection_feedback - delta)
	facing = aim.normalized() if not aim.is_zero_approx() else Vector2.DOWN
	_punch_time = maxf(0.0, _punch_time - delta * combat.attack_speed_multiplier)
	punch_cadence_updated.emit(_punch_time, combat.tuning.punch_cooldown if combat != null else 0.38, punch_damage(), punch_hit_rate())
	if slot != 0 and select_item.is_valid():
		select_item.call(slot)
	elif slot != 0 and not combat.active:
		knife_selected = slot == 1 and knife_owned
		combat.gun.selected = slot == 3 and gun_owned
		combat.sotjet.selected = slot == 4 and sotjet_owned
	if drop and not combat.active:
		_drop()
	if pickup and not combat.active:
		_pickup(pickup_id)
	guarding = guard and knife_owned and knife_selected and not combat.active and _punch_time <= 0.0
	if punch and not combat.ranged_selected() and not combat.active and _punch_time <= 0.0:
		guarding = false
		_punch_time = combat.tuning.punch_cooldown
		_punch()
	if guarding or not melee_selected() or _punch_time > 0.0:
		combat.rules.cancel_charge()
	combat.sword.visible = knife_owned and knife_selected
	combat.staff.visible = staff_owned and staff_selected
	changed.emit(knife_owned, knife_selected, guarding)

func suppress_slash() -> bool:
	return guarding or not melee_selected() or _punch_time > 0.0

func melee_selected() -> bool:
	return (knife_owned and knife_selected) or (staff_owned and staff_selected)

func blocks(source: Vector3) -> bool:
	var offset := source - combat.actor.global_position
	var planar := Vector2(offset.x, offset.z)
	return guarding and not planar.is_zero_approx() and absf(offset.y) < 1.5 and facing.dot(planar.normalized()) >= cos(deg_to_rad(combat.tuning.guard_half_angle))

func defend(source: Vector3) -> bool:
	if not blocks(source):
		return false
	var at := combat.actor.global_position + Vector3(facing.x, 0, facing.y) * 0.65 + Vector3.UP * 0.7
	CombatEffects.sparks(self, at)
	defended.emit()
	return true

func _punch() -> void:
	var at := combat.actor.global_position + Vector3.UP * 0.55
	var forward := Vector3(facing.x, 0, facing.y)
	CombatEffects.punch(self, at + forward * 0.65)
	var trained := false
	for target in combat.targets:
		if not is_instance_valid(target):
			continue
		var offset := target.global_position - at
		if offset.length() > combat.tuning.punch_reach or offset.normalized().dot(forward) < 0.5:
			continue
		var dmg: float = combat.tuning.punch_damage * combat.fist_damage_multiplier
		if combat._unobstructed(combat.actor.global_position, target) and target.damage(dmg, forward * 3.0):
			CombatEffects.burst(self, target.global_position, "-%d POW!" % int(dmg), Color("ffccaa"))
			combat.struck.emit(0.0, 1)
			if target.trains_weapons and not trained:
				trained = true
				combat.weapon_trained.emit("fist")

func _drop() -> void:
	if drop_item.is_valid(): drop_item.call()

func _pickup(id: int = -1) -> void:
	if pickup_item.is_valid(): pickup_item.call(id)

func reset() -> void:
	guarding = false
	_punch_time = 0.0

func restore_save(owned: bool, selected: bool, _at: Vector3) -> void:
	knife_owned = owned
	knife_selected = selected and owned
	changed.emit(knife_owned, knife_selected, false)

func reflection_normal(incoming: Vector3, point: Vector3, confirmed: bool) -> Vector3:
	if not knife_owned or not knife_selected or combat.active or incoming.is_zero_approx(): return Vector3.ZERO
	if absf(point.y - combat.actor.global_position.y) > 1.5: return Vector3.ZERO
	var source := combat.actor.global_position - incoming.normalized()
	if not blocks(source): return Vector3.ZERO
	if confirmed and _reflection_feedback <= 0.0:
		_reflection_feedback = 0.35
		defend(source)
		projectile_defended.emit()
	return Vector3(facing.x, 0, facing.y).normalized()

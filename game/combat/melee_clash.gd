class_name MeleeClash
extends RefCounted
## Host-authoritative knife-to-knife contact. It cancels both attacks before health damage.

var opponents: Array[PlayerCombat] = []
var sequence: int = 0
var _pose: Transform3D
var _ready: bool = false

func record(pose: Transform3D, cutting: bool) -> void:
	_pose = pose
	_ready = cutting

func clear() -> void:
	_ready = false

func opponent_for(attacker: PlayerCombat, target: Damageable) -> PlayerCombat:
	if not _ready or not attacker.equipment.knife_selected:
		return null
	for opponent: PlayerCombat in opponents:
		if not is_instance_valid(opponent) or opponent.actor != target.body:
			continue
		if not opponent.active or not opponent.clash._ready or not opponent.equipment.knife_selected:
			continue
		if _touches(attacker, opponent):
			return opponent
	return null

func resolve(attacker: PlayerCombat, defender: PlayerCombat) -> void:
	_cancel(attacker)
	_cancel(defender)
	var at := (attacker._melee_tip(_pose) + defender._melee_tip(defender.clash._pose)) * 0.5
	CombatEffects.sparks(attacker, at)
	CombatEffects.burst(attacker, defender.actor.global_position, "DODGE!", Color("bcecff"))

func _cancel(combat: PlayerCombat) -> void:
	combat.active = false
	combat.rules.cooldown = maxf(combat.rules.cooldown, combat.tuning.clash_recovery_seconds)
	if combat.combo.finish_attack(): combat._emit_combo()
	combat.clash.clear()
	combat.clash.sequence += 1
	if combat.owner_health != null:
		combat.owner_health.invulnerability = maxf(combat.owner_health.invulnerability, combat.tuning.clash_dodge_seconds)
	combat.clashed.emit()

func _touches(first: PlayerCombat, second: PlayerCombat) -> bool:
	var radius := (first._melee_width() + second._melee_width()) * 0.5 + first.tuning.clash_margin
	var first_tip := first._melee_tip(_pose)
	var second_tip := second._melee_tip(second.clash._pose)
	for sample in 7:
		var point := _pose.origin.lerp(first_tip, sample / 6.0)
		if _distance_to_segment(point, second.clash._pose.origin, second_tip) <= radius:
			return true
	return false

func _distance_to_segment(point: Vector3, start: Vector3, end: Vector3) -> float:
	var segment := end - start
	var length_squared := segment.length_squared()
	if length_squared <= 0.0001: return point.distance_to(start)
	var fraction := clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(start + segment * fraction)

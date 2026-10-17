class_name BengalClawHits
extends RefCounted
## One contact per dash target; the final cone is a separate hit with shared practice.

var contacted: Array[Damageable] = []
var trained: bool = false

func reset() -> void:
	contacted.clear()
	trained = false

func dash_distance(combat: PlayerCombat, point: Vector3) -> float:
	var at := combat.actor.global_position
	var aim := combat.claws.aim
	var maximum := BengalClaws.DASH_SPEED * BengalClaws.DASH_SECONDS
	var distance := maximum
	var best := INF
	for target in combat.targets:
		if not _eligible(combat, target): continue
		var offset := target.global_position - at
		var planar := Vector2(offset.x, offset.z)
		if planar.length() > maximum + 0.8 or absf(offset.y) > 1.5 or planar.normalized().dot(aim) < 0.94: continue
		if not combat._unobstructed(at, target): continue
		var score := target.global_position.distance_squared_to(point) if point.is_finite() else planar.length_squared()
		if score >= best: continue
		best = score
		distance = clampf(planar.length() - 0.85, 0.0, maximum)
		combat.claws.aim = planar.normalized() if not planar.is_zero_approx() else aim
	return distance

func sweep(combat: PlayerCombat, from: Vector3, to: Vector3) -> void:
	for target in combat.targets:
		if not combat.claws.dashing or combat.replica_view: return
		if not _eligible(combat, target) or target in contacted: continue
		var point := Geometry3D.get_closest_point_to_segment(target.global_position, from + Vector3.UP * 0.55, to + Vector3.UP * 0.55)
		var offset := target.global_position - point
		if Vector2(offset.x, offset.z).length() > 1.05 or absf(offset.y) > 1.5: continue
		if not combat._unobstructed(point - Vector3.UP * 0.55, target): continue
		if _hit(combat, target, false, false): contacted.append(target)

func strike(combat: PlayerCombat, reality: bool) -> void:
	if combat.replica_view: return
	var aim := combat.claws.aim if reality else combat.equipment.facing
	var forward := Vector3(aim.x, 0, aim.y)
	var at := combat.actor.global_position + Vector3.UP * 0.55
	BengalRiftVFX.slash(combat, at + forward * (1.2 if reality else 0.8), reality, forward)
	for target in combat.targets:
		if not combat.claws.selected: return
		if not _eligible(combat, target): continue
		var offset := target.global_position - at
		if offset.length() > (BengalClaws.RIFT_REACH if reality else BengalClaws.REACH) or offset.normalized().dot(forward) < 0.5: continue
		if combat._unobstructed(combat.actor.global_position, target): _hit(combat, target, reality, not reality)

func _hit(combat: PlayerCombat, target: Damageable, reality: bool, normal: bool) -> bool:
	if combat.replica_view: return false
	var amount := combat.claws.damage(combat) * (3.0 if reality else 1.0)
	var aim := combat.claws.aim if not normal else combat.equipment.facing
	# Dash contact leaves the victim in place for the separate finishing cut.
	var impulse := Vector3(aim.x, 0, aim.y) * (3.0 if reality or normal else 0.0)
	if not target.damage(amount, impulse, Damageable.HitKind.MELEE): return false
	if reality: target.paralyze(BengalClaws.PARALYSIS)
	combat.vitals.confirmed_hit(normal)
	combat.struck.emit(1.0 if reality else 0.0, 1)
	CombatEffects.burst(combat, target.global_position, str(int(amount)), Color("c3a6ff") if reality else Color("ffcf89"))
	if target.trains_weapons and not trained:
		trained = true
		combat.weapon_trained.emit("fist")
		combat.speed_gear_trained.emit(1)
	return true

func _eligible(combat: PlayerCombat, target: Damageable) -> bool:
	return is_instance_valid(target) and target != combat.owner_health and target.current > 0.0

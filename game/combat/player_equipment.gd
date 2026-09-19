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
var dropped: SwordVisual
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

func step(aim: Vector2, guard: bool, punch: bool, drop: bool, pickup: bool, slot: int, delta: float) -> void:
	_reflection_feedback = maxf(0.0, _reflection_feedback - delta)
	facing = aim.normalized() if not aim.is_zero_approx() else Vector2.DOWN
	_punch_time = maxf(0.0, _punch_time - delta * combat.attack_speed_multiplier)
	punch_cadence_updated.emit(_punch_time, combat.tuning.punch_cooldown if combat != null else 0.38, punch_damage(), punch_hit_rate())
	if slot != 0 and not combat.active:
		knife_selected = slot == 1 and knife_owned
		combat.gun.selected = slot == 3
		combat.sotjet.selected = slot == 4
	if drop and knife_owned and not combat.active:
		_drop()
	if pickup:
		_pickup()
	guarding = guard and knife_owned and knife_selected and not combat.active and _punch_time <= 0.0
	if punch and not combat.ranged_selected() and not combat.active and _punch_time <= 0.0:
		guarding = false
		_punch_time = combat.tuning.punch_cooldown
		_punch()
	if guarding or not knife_selected or _punch_time > 0.0:
		combat.rules.cancel_charge()
	combat.sword.visible = knife_owned and knife_selected
	changed.emit(knife_owned, knife_selected, guarding)

func suppress_slash() -> bool:
	return guarding or not knife_owned or not knife_selected or _punch_time > 0.0

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
	knife_owned = false
	knife_selected = false
	combat.rules.cancel_charge()
	dropped = SwordVisual.new()
	dropped.tuning = combat.tuning
	add_child(dropped)
	var origin := combat.actor.global_position
	var at := origin + Vector3(facing.y, 0, -facing.x) * 0.9
	var clearance := PhysicsRayQueryParameters3D.create(origin + Vector3.UP * 0.5, at + Vector3.UP * 0.5, 1)
	if not combat.actor.get_world_3d().direct_space_state.intersect_ray(clearance).is_empty():
		at = origin
	var ray := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.2, at + Vector3.DOWN * 30, 1)
	var hit := combat.actor.get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty():
		at = hit.position
	dropped.global_position = at
	dropped.present(SwordGeometry.pose(at - Vector3.UP * 0.35, Vector2.RIGHT, -1.0, combat.tuning), Vector2.RIGHT, 0.0)
	var label := Label3D.new()
	label.text = "[E] KNIFE"
	label.font_size = 28
	label.pixel_size = 0.008
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	dropped.add_child(label)
	label.position.y = 0.85

func _pickup() -> void:
	if not is_instance_valid(dropped) or combat.actor.global_position.distance_to(dropped.global_position) > 1.8:
		return
	var ray := PhysicsRayQueryParameters3D.create(combat.actor.global_position + Vector3.UP * 0.5, dropped.global_position + Vector3.UP * 0.5, 1)
	if not combat.actor.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
		return
	dropped.queue_free()
	dropped = null
	knife_owned = true
	knife_selected = true
	combat.gun.selected = false
	combat.sotjet.selected = false

func reset() -> void:
	guarding = false
	_punch_time = 0.0

func restore_save(owned: bool, selected: bool, at: Vector3) -> void:
	if not owned:
		_drop()
		dropped.global_position = at
		dropped.present(SwordGeometry.pose(at - Vector3.UP * 0.35, Vector2.RIGHT, -1.0, combat.tuning), Vector2.RIGHT, 0.0)
	knife_owned = owned
	knife_selected = selected and owned
	changed.emit(knife_owned, knife_selected, false)

func present_dropped(owned: bool, at: Vector3) -> void:
	if owned:
		if is_instance_valid(dropped): dropped.queue_free()
		dropped = null
		return
	if not is_instance_valid(dropped):
		dropped = SwordVisual.new()
		dropped.tuning = combat.tuning
		add_child(dropped)
		var label := Label3D.new()
		label.text = "KNIFE · Pick up"
		label.font_size = 28
		label.pixel_size = 0.008
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		dropped.add_child(label)
		label.position.y = 0.85
	dropped.global_position = at
	dropped.present(SwordGeometry.pose(at - Vector3.UP * 0.35, Vector2.RIGHT, -1.0, combat.tuning), Vector2.RIGHT, 0.0)

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

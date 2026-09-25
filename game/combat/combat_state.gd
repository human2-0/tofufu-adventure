class_name CombatState
extends RefCounted
## Value snapshots and replica presentation. Applying a snapshot never deals damage.

static func capture(combat: PlayerCombat) -> Dictionary:
	var equipment := combat.equipment
	var drop := equipment.dropped.global_position if is_instance_valid(equipment.dropped) else Vector3.ZERO
	return {"world_drops": true, "gun_owned": equipment.gun_owned, "sotjet_owned": equipment.sotjet_owned, "staff_owned": equipment.staff_owned, "staff": equipment.staff_selected, "jet": combat.sotjet.selected, "milk": combat.sotjet.milk, "jet_ads": combat.sotjet.aiming,
		"jet_firing": combat.sotjet.firing, "jet_sequence": combat.sotjet.sequence,
		"jet_origin": _array(combat.sotjet.origin), "jet_velocity": _array(combat.sotjet.velocity), "recoil": combat.gun.recoil.heat, "gun": combat.gun.selected, "ads": combat.gun.aiming, "shot": combat.gun.shot_sequence,
		"shot_origin": _array(combat.gun.shot_origin), "shot_velocity": _array(combat.gun.shot_velocity), "owned": equipment.knife_owned, "selected": equipment.knife_selected, "guard": equipment.guarding,
		"active": combat.active, "aim": [combat.attack_aim.x, combat.attack_aim.y],
		"facing": [equipment.facing.x, equipment.facing.y], "charge": combat.rules.charge,
		"strength": combat._strength, "style": combat.attack_style, "elapsed": combat._elapsed, "punch": equipment._punch_time,
		"combo": combat.combo.count, "combo_window": combat.combo.window_remaining, "clash": combat.clash.sequence,
		"cooldown": combat.rules.cooldown, "drop": [drop.x, drop.y, drop.z]}

static func restore(combat: PlayerCombat, state: Dictionary) -> void:
	combat.reset()
	combat.equipment.gun_owned = state.get("gun_owned", true)
	combat.equipment.sotjet_owned = state.get("sotjet_owned", true)
	combat.equipment.staff_owned = state.get("staff_owned", false)
	combat.equipment.staff_selected = state.get("staff", false) and combat.equipment.staff_owned
	combat.gun.selected = state.get("gun", false)
	combat.sotjet.selected = state.get("jet", false)
	combat.sotjet.milk = state.get("milk", combat.sotjet.tuning.capacity)
	combat.gun.shot_sequence = int(state.get("shot", 0))
	combat.equipment.knife_owned = state.owned
	combat.equipment.knife_selected = state.selected and state.owned and not combat.equipment.staff_selected
	combat.equipment._punch_time = state.punch
	combat.rules.cooldown = state.cooldown
	combat.attack_style = int(state.get("style", KnifeAttack.Style.HEAVY if state.get("strength", 0.0) >= 1.0 else KnifeAttack.Style.SLASH))
	combat.combo.restore(int(state.get("combo", 0)), float(state.get("combo_window", 0.0)))
	combat.clash.sequence = int(state.get("clash", 0))

static func present(combat: PlayerCombat, state: Dictionary, resting_aim: Vector2) -> void:
	var new_clash := int(state.get("clash", 0)) > combat.clash.sequence
	combat.clash.sequence = int(state.get("clash", 0))
	combat.gun.selected = state.get("gun", false)
	combat.sotjet.present(state, Vector2(state.facing[0], state.facing[1]))
	combat.gun.recoil.heat = state.get("recoil", 0.0)
	combat.gun.aiming = state.get("ads", false)
	combat.gun.visual.visible = combat.gun.selected
	combat.gun.visual.facing = Vector2(state.facing[0], state.facing[1])
	combat.gun.present_shot(int(state.get("shot", 0)), _vector(state.get("shot_origin", [0,0,0])), _vector(state.get("shot_velocity", [0,0,0])))
	combat.active = state.active
	combat.attack_aim = Vector2(state.aim[0], state.aim[1])
	combat.attack_style = int(state.get("style", KnifeAttack.Style.HEAVY if state.get("strength", 0.0) >= 1.0 else KnifeAttack.Style.SLASH))
	var equipment := combat.equipment
	equipment.gun_owned = state.get("gun_owned", true)
	equipment.sotjet_owned = state.get("sotjet_owned", true)
	equipment.staff_owned = state.get("staff_owned", false)
	equipment.staff_selected = state.get("staff", false) and equipment.staff_owned
	var new_punch: bool = state.punch > equipment._punch_time + 0.1
	equipment._punch_time = state.punch
	equipment.knife_owned = state.owned
	equipment.knife_selected = state.selected and not equipment.staff_selected
	equipment.guarding = state.guard
	equipment.facing = Vector2(state.facing[0], state.facing[1])
	combat.sword.visible = state.owned and state.selected
	combat.staff.visible = equipment.staff_owned and equipment.staff_selected
	var heavy := KnifeAttack.powered(combat.attack_style)
	var duration := combat._attack_duration()
	var progress: float = clampf(state.elapsed / duration, 0, 1) if state.active else -1.0
	var aim := Vector2(state.aim[0], state.aim[1]) if state.active else resting_aim
	var pose := combat._attack_pose(combat.actor.global_position, aim, progress)
	var attachment := 1.0
	if state.active:
		attachment = 1.0 - smoothstep(0.0, combat.tuning.cut_start, progress) if progress < combat.tuning.cut_start else smoothstep(combat.tuning.cut_end, 1.0, progress)
	if state.guard:
		aim = equipment.facing
		pose = SwordGeometry.guard_pose(combat.actor.global_position, aim, combat.tuning)
		attachment = 0.0
	var cutting: bool = state.active and SwordGeometry.cutting(progress, combat.tuning)
	combat.sword.present(pose, aim, maxf(state.charge, state.strength if state.active else 0), cutting, attachment)
	combat.staff.present(pose, state.charge, state.active and combat.attack_style == StaffAttack.TORNADO)
	combat._trail.record(pose, combat.tuning, cutting, heavy, combat._melee_length())
	if new_clash:
		CombatEffects.sparks(combat, combat.actor.global_position + Vector3.UP * 0.8)
	if new_punch:
		CombatEffects.punch(combat, combat.actor.global_position + Vector3(aim.x * 0.65, 0.55, aim.y * 0.65))

static func _array(value: Vector3) -> Array:
	return [value.x, value.y, value.z]

static func _vector(value: Array) -> Vector3:
	return Vector3(value[0], value[1], value[2])

class_name CombatState
extends RefCounted
## Value snapshots and replica presentation. Applying a snapshot never deals damage.

static func capture(combat: PlayerCombat) -> Dictionary:
	var equipment := combat.equipment
	var drop := equipment.dropped.global_position if is_instance_valid(equipment.dropped) else Vector3.ZERO
	var state := {"enhanced": combat.equipment.weapon_enhanced, "celestial": equipment.celestial_weapon, "nori": equipment.nori_selected, "plunging": combat.plunge.active, "plunge_recovery": combat.plunge.recovery, "plunge_sequence": combat.plunge.sequence, "plunge_at": _array(combat.plunge.impact_at), "plunge_cooldown": combat.plunge.cooldown, "vitals": combat.vitals.capture(), "pod": equipment.pod_selected, "podburst": combat.podburst.sequence, "pod_cooldown": combat.podburst.cooldown, "world_drops": true, "gun_owned": equipment.gun_owned, "sotjet_owned": equipment.sotjet_owned, "staff_owned": equipment.staff_owned, "staff": equipment.staff_selected, "jet": combat.sotjet.selected, "milk": combat.sotjet.milk, "jet_ads": combat.sotjet.aiming,
		"jet_firing": combat.sotjet.firing, "jet_sequence": combat.sotjet.sequence,
		"jet_origin": _array(combat.sotjet.origin), "jet_velocity": _array(combat.sotjet.velocity), "recoil": combat.gun.recoil.heat, "gun": combat.gun.selected, "ads": combat.gun.aiming, "shot": combat.gun.shot_sequence,
		"shot_origin": _array(combat.gun.shot_origin), "shot_velocity": _array(combat.gun.shot_velocity), "owned": equipment.knife_owned, "selected": equipment.knife_selected, "guard": equipment.guarding,
		"active": combat.active, "aim": [combat.attack_aim.x, combat.attack_aim.y],
		"facing": [equipment.facing.x, equipment.facing.y], "gun_magazine": combat.gun.magazine, "gun_reload": combat.gun.reload_remaining,
		"gun_charge": combat.gun.charge_elapsed, "ricochet": combat.gun.ricochet_sequence,
		"ricochet_origin": _array(combat.gun.ricochet_origin), "ricochet_velocity": _array(combat.gun.ricochet_velocity), "charge": combat.rules.charge,
		"strength": combat._strength, "style": combat.attack_style, "elapsed": combat._elapsed, "hit_pause": combat.hit_pause, "punch": equipment._punch_time, "punch_sequence": equipment.punch_sequence,
		"combo": combat.combo.count, "chain": combat.combo.chain, "combo_window": combat.combo.window_remaining, "clash": combat.clash.sequence,
		"cooldown": combat.rules.cooldown, "drop": [drop.x, drop.y, drop.z]}

	state.merge(BengalClawsState.capture(combat))
	state.merge(AngelBowState.capture(combat.bow))
	return state

static func restore(combat: PlayerCombat, state: Dictionary) -> void:
	combat.equipment.weapon_enhanced = state.get("enhanced", false)
	combat.gun.magazine_capacity = SoyGun.MAGAZINE_SIZE + (5 if combat.equipment.weapon_enhanced and state.get("gun", false) else 0)
	combat.reset()
	BengalClawsState.apply(combat, state, false)
	AngelBowState.apply(combat.bow, state, false)
	combat.vitals.restore(state.get("vitals", {}))
	CelestialCombat.apply(combat, int(state.get("celestial", 0)))
	combat.podburst.cooldown = state.get("pod_cooldown", 0.0)
	combat.equipment.pod_selected = state.get("pod", false)
	combat.sword.set_pod(combat.equipment.pod_selected)
	combat.equipment.nori_selected = state.get("nori", false)
	combat.sword.set_nori(combat.equipment.nori_selected)
	combat.plunge.cooldown = state.get("plunge_cooldown", 0.0)
	combat.equipment.gun_owned = state.get("gun_owned", true)
	combat.equipment.sotjet_owned = state.get("sotjet_owned", true)
	combat.equipment.staff_owned = state.get("staff_owned", false)
	combat.equipment.staff_selected = state.get("staff", false) and combat.equipment.staff_owned
	combat.gun.selected = state.get("gun", false)
	combat.sotjet.selected = state.get("jet", false)
	combat.sotjet.consumption_multiplier = 0.8 if combat.sotjet.selected and combat.equipment.weapon_enhanced else 1.0
	combat.sotjet.milk = state.get("milk", combat.sotjet.tuning.capacity)
	combat.gun.shot_sequence = int(state.get("shot", 0))
	combat.gun.magazine = int(state.get("gun_magazine", SoyGun.MAGAZINE_SIZE))
	combat.gun.reload_remaining = float(state.get("gun_reload", 0.0))
	combat.gun.charge_elapsed = float(state.get("gun_charge", 0.0))
	combat.gun.ricochet_sequence = int(state.get("ricochet", 0))
	combat.gun.ricochet_origin = _vector(state.get("ricochet_origin", [0, 0, 0]))
	combat.gun.ricochet_velocity = _vector(state.get("ricochet_velocity", [0, 0, 0]))
	combat.equipment.knife_owned = state.owned
	combat.equipment.knife_selected = state.selected and state.owned and not combat.equipment.staff_selected
	combat.equipment._punch_time = state.punch
	combat.equipment.punch_sequence = int(state.get("punch_sequence", 0))
	combat.rules.cooldown = state.cooldown
	combat.attack_style = int(state.get("style", KnifeAttack.Style.HEAVY if state.get("strength", 0.0) >= 1.0 else KnifeAttack.Style.SLASH))
	combat.combo.restore(int(state.get("combo", 0)), float(state.get("combo_window", 0.0)), int(state.get("chain", -1)))
	combat.clash.sequence = int(state.get("clash", 0))

static func present(combat: PlayerCombat, state: Dictionary, resting_aim: Vector2) -> void:
	AngelBowState.apply(combat.bow, state, true)
	BengalClawsState.apply(combat, state, true)
	combat.equipment.weapon_enhanced = state.get("enhanced", false)
	combat.gun.magazine_capacity = SoyGun.MAGAZINE_SIZE + (5 if combat.equipment.weapon_enhanced and state.get("gun", false) else 0)
	combat.vitals.restore(state.get("vitals", {}))
	CelestialCombat.apply(combat, int(state.get("celestial", 0)))
	combat.podburst.cooldown = state.get("pod_cooldown", 0.0)
	combat.equipment.pod_selected = state.get("pod", false)
	combat.sword.set_pod(combat.equipment.pod_selected)
	combat.equipment.nori_selected = state.get("nori", false)
	combat.sword.set_nori(combat.equipment.nori_selected)
	combat.plunge.cooldown = state.get("plunge_cooldown", 0.0)
	if int(state.get("plunge_sequence", 0)) > combat.plunge.sequence:
		NoriPlungeVFX.impact(combat, _vector(state.get("plunge_at", [0,0,0])), combat.tuning.nori_plunge_radius)
	combat.plunge.sequence = int(state.get("plunge_sequence", 0))
	combat.plunge.active = state.get("plunging", false)
	if int(state.get("podburst", 0)) > combat.podburst.sequence:
		Podburst.visual(combat, Vector2(state.aim[0], state.aim[1]))
	combat.podburst.sequence = int(state.get("podburst", 0))
	var new_clash := int(state.get("clash", 0)) > combat.clash.sequence
	combat.clash.sequence = int(state.get("clash", 0))
	combat.gun.selected = state.get("gun", false)
	combat.sotjet.present(state, Vector2(state.facing[0], state.facing[1]))
	combat.gun.recoil.heat = state.get("recoil", 0.0)
	combat.gun.aiming = state.get("ads", false)
	combat.gun.visual.visible = combat.gun.selected
	combat.gun.visual.facing = Vector2(state.facing[0], state.facing[1])
	combat.gun.present_shot(int(state.get("shot", 0)), _vector(state.get("shot_origin", [0,0,0])), _vector(state.get("shot_velocity", [0,0,0])))
	combat.gun.magazine = int(state.get("gun_magazine", SoyGun.MAGAZINE_SIZE))
	combat.gun.reload_remaining = float(state.get("gun_reload", 0.0))
	combat.gun.charge_elapsed = float(state.get("gun_charge", 0.0))
	combat.gun.present_ricochet(int(state.get("ricochet", 0)), _vector(state.get("ricochet_origin", [0,0,0])), _vector(state.get("ricochet_velocity", [0,0,0])))
	combat.rules.charge = state.charge
	combat.rules.cooldown = state.cooldown
	combat.plunge.recovery = state.get("plunge_recovery", 0.0)
	combat.active = state.active
	combat._elapsed = float(state.elapsed)
	combat._strength = float(state.strength)
	combat.hit_pause = float(state.get("hit_pause", 0.0))
	combat.attack_aim = Vector2(state.aim[0], state.aim[1])
	combat.attack_style = int(state.get("style", KnifeAttack.Style.HEAVY if state.get("strength", 0.0) >= 1.0 else KnifeAttack.Style.SLASH))
	var equipment := combat.equipment
	equipment.gun_owned = state.get("gun_owned", true)
	equipment.sotjet_owned = state.get("sotjet_owned", true)
	equipment.staff_owned = state.get("staff_owned", false)
	equipment.staff_selected = state.get("staff", false) and equipment.staff_owned
	var new_punch: bool = int(state.get("punch_sequence", 0)) > equipment.punch_sequence if state.has("punch_sequence") else state.punch > equipment._punch_time + 0.1
	equipment.punch_sequence = int(state.get("punch_sequence", equipment.punch_sequence))
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
	if state.get("plunging", false) or state.get("plunge_recovery", 0.0) > 0.0:
		pose = NoriPlunge.pose(combat.actor.global_position)
		attachment = 0.0
		cutting = false
	combat.sword.present(pose, aim, maxf(state.charge, state.strength if state.active else 0), cutting, attachment)
	combat.staff.present(pose, state.charge, state.active and combat.attack_style == StaffAttack.TORNADO, 0.0 if cutting else attachment)
	combat._trail.record(pose, combat.tuning, cutting, heavy, combat._melee_length())
	if new_clash:
		CombatEffects.sparks(combat, combat.actor.global_position + Vector3.UP * 0.8)
	if new_punch and combat.claws.selected:
		BengalRiftVFX.slash(combat, combat.actor.global_position + Vector3(equipment.facing.x * 0.8, 0.55, equipment.facing.y * 0.8), false)
	elif new_punch:
		CombatEffects.punch(combat, combat.actor.global_position + Vector3(equipment.facing.x * 0.65, 0.55, equipment.facing.y * 0.65), equipment.punch_sequence, equipment.punch_outfit, equipment.facing, combat.attack_speed_multiplier)

static func _array(value: Vector3) -> Array:
	return [value.x, value.y, value.z]

static func _vector(value: Array) -> Vector3:
	return Vector3(value[0], value[1], value[2])

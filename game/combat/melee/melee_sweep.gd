class_name MeleeSweep
extends RefCounted
## Authoritative swept contact, occlusion, clash and damage resolution.

static func sample_sweep(combat: PlayerCombat, progress: float) -> void:
	var heavy := KnifeAttack.powered(combat.attack_style)
	var radius := combat.tuning.hand_radius + combat.tuning.grip_length + combat._melee_length()
	var travel := combat.actor.global_position.distance_to(combat._previous_at)
	if combat.attack_style == KnifeAttack.Style.STAB:
		travel += absf(progress - combat._previous_progress) / (combat.tuning.cut_end - combat.tuning.cut_start) * 1.1
	else:
		var arc := TAU if combat.attack_style == StaffAttack.TORNADO else deg_to_rad(combat.tuning.heavy_arc_degrees if heavy else combat.tuning.light_arc_degrees)
		travel += (progress - combat._previous_progress) / (combat.tuning.cut_end - combat.tuning.cut_start) * (arc + 1.2) * radius
	var samples := maxi(1, ceili(travel / (combat._melee_width() * 0.4)))
	for index in samples:
		var fraction := float(index + 1) / samples
		var sample_progress := lerpf(combat._previous_progress, progress, fraction)
		if SwordGeometry.cutting(sample_progress, combat.tuning):
			var at := combat._previous_at.lerp(combat.actor.global_position, fraction)
			var pose := combat._attack_pose(at, combat.attack_aim, sample_progress)
			combat.clash.record(pose, true)
			combat._resolve_blade(at, pose)
			if not combat.active or combat.hit_pause > 0.0:
				combat._elapsed = sample_progress * combat._attack_duration()
				combat._previous_at = at
				combat._previous_progress = sample_progress
				return
	combat._previous_at = combat.actor.global_position
	combat._previous_progress = progress

static func resolve_blade(combat: PlayerCombat, at: Vector3, pose: Transform3D) -> void:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = combat._shape
	query.transform = pose.translated_local(Vector3(0, 0, -combat._melee_length() * 0.5))
	query.collision_mask = 3
	query.margin = 0.0
	if combat.actor is CollisionObject3D:
		query.exclude = [combat.actor.get_rid()]
	var overlaps := combat.actor.get_world_3d().direct_space_state.intersect_shape(query, 64)
	for overlap in overlaps:
		for target in combat.targets:
			if not is_instance_valid(target) or target in combat._hit_targets or target.current <= 0.0:
				continue
			if target.body == overlap.collider and combat._unobstructed(at, target):
				var opponent := combat.clash.opponent_for(combat, target)
				if opponent != null:
					combat.clash.resolve(combat, opponent)
					return
				var point := Geometry3D.get_closest_point_to_segment(target.global_position, pose.origin, pose.origin - pose.basis.z * combat._melee_length())
				combat._damage(target, point)

static func unobstructed(combat: PlayerCombat, at: Vector3, target: Damageable) -> bool:
	var origin := at + Vector3.UP * combat.tuning.hand_height
	var query := PhysicsRayQueryParameters3D.create(origin, target.global_position, 1)
	var obstacle := combat.actor.get_world_3d().direct_space_state.intersect_ray(query)
	return obstacle.is_empty() or obstacle.collider == target.body

static func damage(combat: PlayerCombat, target: Damageable, point: Vector3 = Vector3.INF) -> void:
	var base_damage := combat._melee_damage()
	var critical := combat._attack_critical_chance > 0.0 and critical_roll(combat) < combat._attack_critical_chance
	var damage := base_damage * combat.sword_damage_multiplier
	if critical:
		damage *= combat.tuning.combo_critical_damage_multiplier
	var impulse := KnifeAttack.impulse(combat.attack_style, combat.attack_aim, combat.tuning)
	if combat.attack_style == StaffAttack.TORNADO:
		var outward := target.global_position - combat.actor.global_position
		impulse = Vector3(outward.x, 0.0, outward.z).normalized() * 5.0
	var kind := Damageable.HitKind.MELEE if combat.equipment.staff_selected else Damageable.HitKind.KNIFE
	if target.damage(damage, impulse, kind, point):
		if point.is_finite(): MeleeContact.flash(combat, point, KnifeAttack.powered(combat.attack_style))
		if combat._hit_targets.is_empty():
			combat.hit_pause = combat.tuning.heavy_hit_pause if KnifeAttack.powered(combat.attack_style) else combat.tuning.light_hit_pause
		combat.vitals.confirmed_hit(not combat.special_attack)
		combat._hit_targets.append(target)
		if combat.combo.confirm_hit():
			combat._emit_combo()
		if target.trains_weapons and not combat._trained:
			combat._trained = true
			combat.weapon_trained.emit("sword")
		var text := "CRIT! %d" % int(damage) if critical else str(int(damage))
		CombatEffects.burst(combat, target.global_position, text, Color("ff8f7f") if critical else Color(1, 0.86, 0.4))
		combat.struck.emit(1.0 if KnifeAttack.powered(combat.attack_style) else combat._strength, 1)

	elif target.hit_absorbed:
		if combat._hit_targets.is_empty(): combat.hit_pause = combat.tuning.heavy_hit_pause
		combat._hit_targets.append(target)

static func critical_roll(combat: PlayerCombat) -> float:
	return float(combat.critical_roll.call()) if combat.critical_roll.is_valid() else randf()

class_name SnailSteering
extends RefCounted
## Chase, attack telegraph and wander intent for the existing snail body.

static func choose_direction(mob: TrainingMob, delta: float) -> Vector3:
	if not is_instance_valid(mob.quarry):
		return Vector3.ZERO
	var home_offset := mob._home - mob.position
	home_offset.y = 0.0
	if mob._protected(mob.global_position) or (not mob.free_roaming and (home_offset.length() > mob.leash_radius or mob._protected(mob.quarry.global_position))):
		mob._returning = true
	if mob._returning:
		mob._windup = 0.0
		mob._warning.visible = false
		if home_offset.length() < 0.4:
			mob._returning = false
			return Vector3.ZERO
		return home_offset.normalized() * 3.5
	var offset := mob.quarry.global_position - mob.global_position
	if offset.length() < 7.0 or mob._windup > 0.0: mob.targeting.emit(mob.quarry)
	if mob._windup > 0.0:
		mob._windup -= delta
		if mob._windup <= 0.0:
			mob._warning.visible = false
			if offset.length() < 2.0 and mob._can_reach_quarry():
				mob.attacked.emit(mob.tuning.rain_damage if mob.raining else mob.tuning.dry_damage, mob.global_position)
			mob._rest = 1.3
		return Vector3.ZERO
	if mob._rest > 0.0:
		return Vector3.ZERO
	if offset.length() < 1.6:
		mob._windup = 0.65
		mob._warning.visible = true
		return Vector3.ZERO
	if offset.length() < 7.0:
		offset.y = 0.0
		return offset.normalized() * 2.5
	return _wander(mob, delta)

static func _wander(mob: TrainingMob, delta: float) -> Vector3:
	mob._timer -= delta
	if mob._timer <= 0.0:
		var wander_origin := mob.position if mob.free_roaming else mob._home
		var wander_range := 18.0 if mob.free_roaming else 2.5
		mob._destination = wander_origin + Vector3(mob._rng.randf_range(-wander_range, wander_range), 0, mob._rng.randf_range(-wander_range, wander_range))
		mob._timer = mob._rng.randf_range(4.0, 7.0) if mob.free_roaming else mob._rng.randf_range(2.0, 4.0)
	var wander := mob._destination - mob.position
	wander.y = 0.0
	return wander.normalized() * 1.2 if wander.length() > 0.3 else Vector3.ZERO

static func can_reach_quarry(mob: TrainingMob) -> bool:
	if mob._protected(mob.global_position) or mob._protected(mob.quarry.global_position):
		return false
	var origin := mob.global_position + Vector3.UP * 0.6
	var destination := mob.quarry.global_position + Vector3.UP * 0.6
	var query := PhysicsRayQueryParameters3D.create(origin, destination, 1)
	return mob.get_world_3d().direct_space_state.intersect_ray(query).is_empty()

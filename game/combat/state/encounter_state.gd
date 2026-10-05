class_name EncounterState
extends RefCounted
## Fixed-value records shared by checkpoints and non-authoritative views.

static func mob(mob: TrainingMob) -> Array:
	var p := mob.position
	var v := mob.velocity
	var row := [p.x, p.y, p.z, v.x, v.y, v.z, mob.target.current, maxf(0, mob._respawn), maxf(0, mob._windup)]
	if mob is ArmoredSnail: row.append_array([mob.shell_health, mob.facing.x, mob.facing.z])
	if mob is WildBee: row.append_array([mob.facing.x, mob.facing.z] + mob.sting.capture())
	return row

static func apply_mob(mob: TrainingMob, data: Array, feedback: bool = false) -> void:
	if feedback and data[6] < mob.target.current:
		CombatEffects.damage_number(mob.get_parent(), mob.target, mob.target.current - data[6])
	if data[6] < mob.target.current: mob.flash_hit()
	mob.position = Vector3(data[0], data[1], data[2])
	if mob is ArmoredSnail:
		mob.set_shell_health(float(data[9]) if data.size() == 12 else ArmoredSnail.SHELL_MAX_HEALTH, feedback)
		if data.size() == 12: mob.facing = Vector3(data[10], 0, data[11])
	if mob is WildBee:
		if data.size() == 18:
			mob.facing = Vector3(data[9], 0, data[10])
			mob.sting.apply(data.slice(11))
		else: mob.sting.clear()
	mob.velocity = Vector3(data[3], data[4], data[5])
	mob.target.current = data[6]
	mob._respawn = data[7]
	mob._windup = data[8]
	mob.visible = mob.available and mob._respawn <= 0
	mob.collision_layer = 2 if mob.visible else 0
	mob._warning.visible = mob.visible and mob._windup > 0
	if mob is WildBee and not mob.visible: mob.sting.clear()

static func prop(prop: HarvestProp) -> Array:
	return [prop.target.current, maxf(0, prop._regrow)]

static func apply_prop(prop: HarvestProp, data: Array, feedback: bool = false) -> void:
	if feedback and data[0] < prop.target.current:
		CombatEffects.damage_number(prop.get_parent(), prop.target, prop.target.current - data[0])
	prop.target.current = data[0]
	prop._regrow = data[1]
	prop.present_growth()

static func dummy(dummy: PracticeDummy) -> Array:
	return [dummy.target.current, dummy.last_damage, dummy.hit_count, maxf(0, dummy._reset_in)]

static func apply_dummy(dummy: PracticeDummy, data: Array, feedback: bool = false) -> void:
	if feedback and data[0] < dummy.target.current:
		CombatEffects.damage_number(dummy.get_parent(), dummy.target, dummy.target.current - data[0])
	if data[0] < dummy.target.current: dummy._figure.rotation.z = -0.22
	dummy.target.current = data[0]
	dummy.last_damage = data[1]
	dummy.hit_count = int(data[2])
	dummy._reset_in = data[3]
	dummy._show_status()

static func pickup(id: int, pickup: SoybeanPickup) -> Array:
	var p := pickup.position
	return [id, p.x, p.y, p.z, pickup._age, pickup._speed, pickup._fall_speed,
		int(pickup._grounded), int(pickup._attracted), int(pickup._collected), pickup.count]

static func apply_pickup(pickup: SoybeanPickup, data: Array) -> void:
	pickup.position = Vector3(data[1], data[2], data[3])
	pickup._age = data[4]
	pickup._speed = data[5]
	pickup._fall_speed = data[6]
	pickup._grounded = data[7] == 1
	pickup._attracted = data[8] == 1
	pickup._collected = data[9] == 1
	pickup.count = clampi(int(data[10]) if data.size() > 10 else 1, 1, 100)

class_name EncounterState
extends RefCounted
## Fixed-value records shared by checkpoints and non-authoritative views.

static func mob(enemy: TrainingMob) -> Array:
	var p := enemy.position
	var v := enemy.velocity
	var row := [p.x, p.y, p.z, v.x, v.y, v.z, enemy.target.current, maxf(0, enemy._respawn), maxf(0, enemy._windup)]
	if enemy is ArmoredSnail: row.append_array([enemy.shell_health, enemy.facing.x, enemy.facing.z])
	if enemy is WildBee: row.append_array([enemy.facing.x, enemy.facing.z] + enemy.sting.capture())
	if enemy is BengalMonster: row.append_array([enemy.facing.x, enemy.facing.z, enemy.claw_time])
	return row

static func apply_mob(enemy: TrainingMob, data: Array, feedback: bool = false) -> void:
	if feedback and data[6] < enemy.target.current:
		CombatEffects.damage_number(enemy.get_parent(), enemy.target, enemy.target.current - data[6])
	if data[6] < enemy.target.current: enemy.flash_hit()
	enemy.position = Vector3(data[0], data[1], data[2])
	if enemy is BengalMonster and data.size() == 12:
		enemy.facing = Vector3(data[9], 0, data[10])
		enemy.claw_time = data[11]
	if enemy is ArmoredSnail:
		enemy.set_shell_health(float(data[9]) if data.size() == 12 else ArmoredSnail.SHELL_MAX_HEALTH, feedback)
		if data.size() == 12: enemy.facing = Vector3(data[10], 0, data[11])
	if enemy is WildBee:
		if data.size() == 18:
			enemy.facing = Vector3(data[9], 0, data[10])
			enemy.sting.apply(data.slice(11))
		else: enemy.sting.clear()
	enemy.velocity = Vector3(data[3], data[4], data[5])
	enemy.target.current = data[6]
	enemy._respawn = data[7]
	enemy._windup = data[8]
	enemy.visible = enemy.available and enemy._respawn <= 0
	enemy.collision_layer = 2 if enemy.visible else 0
	enemy._warning.visible = enemy.visible and enemy._windup > 0
	if enemy is WildBee and not enemy.visible: enemy.sting.clear()

static func prop(harvestable: HarvestProp) -> Array:
	return [harvestable.target.current, maxf(0, harvestable._regrow)]

static func apply_prop(harvestable: HarvestProp, data: Array, feedback: bool = false) -> void:
	if feedback and data[0] < harvestable.target.current:
		CombatEffects.damage_number(harvestable.get_parent(), harvestable.target, harvestable.target.current - data[0])
	harvestable.target.current = data[0]
	harvestable._regrow = data[1]
	harvestable.present_growth()

static func dummy(target_dummy: PracticeDummy) -> Array:
	return [target_dummy.target.current, target_dummy.last_damage, target_dummy.hit_count, maxf(0, target_dummy._reset_in)]

static func apply_dummy(target_dummy: PracticeDummy, data: Array, feedback: bool = false) -> void:
	if feedback and data[0] < target_dummy.target.current:
		CombatEffects.damage_number(target_dummy.get_parent(), target_dummy.target, target_dummy.target.current - data[0])
	if data[0] < target_dummy.target.current: target_dummy._figure.rotation.z = -0.22
	target_dummy.target.current = data[0]
	target_dummy.last_damage = data[1]
	target_dummy.hit_count = int(data[2])
	target_dummy._reset_in = data[3]
	target_dummy._show_status()

static func pickup(id: int, bean_pickup: SoybeanPickup) -> Array:
	var p := bean_pickup.position
	return [id, p.x, p.y, p.z, bean_pickup._age, bean_pickup._speed, bean_pickup._fall_speed,
		int(bean_pickup._grounded), int(bean_pickup._attracted), int(bean_pickup._collected), bean_pickup.count]

static func apply_pickup(bean_pickup: SoybeanPickup, data: Array) -> void:
	bean_pickup.position = Vector3(data[1], data[2], data[3])
	bean_pickup._age = data[4]
	bean_pickup._speed = data[5]
	bean_pickup._fall_speed = data[6]
	bean_pickup._grounded = data[7] == 1
	bean_pickup._attracted = data[8] == 1
	bean_pickup._collected = data[9] == 1
	bean_pickup.count = clampi(int(data[10]) if data.size() > 10 else 1, 1, 100)

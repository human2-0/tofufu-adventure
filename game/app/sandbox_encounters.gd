class_name SandboxEncounters
extends Node3D
## App-owned composition of combat actors, harvestables and healing drops.

signal progress_changed(beans: int, mobs: int, props: int)
signal experience_awarded(amount: int)
signal experience_changed(total: int)
var mob_nodes: Array[TrainingMob] = []
var prop_nodes: Array[HarvestProp] = []
var dummy_nodes: Array[PracticeDummy] = []
var pickups: Dictionary[int, SoybeanPickup] = {}
var next_pickup_id: int = 1
var party_hurt: Callable
var party_collect: Callable
const MOB_EXPERIENCE: int = 25
var experience: int = 0
var mob_centers: Array[Vector2] = []
var dummy_positions: Array[Vector2] = []
var protected_area: Rect2
var player: Player
var combat: PlayerCombat
var health: Damageable
var ground_point: Callable
var beans: int = 0
var mobs: int = 0
var props: int = 0

func populate() -> void:
	for row in 4:
		for column in 4:
			_add_prop(Vector3(-10.0 - column * 1.5, 0, -3.0 - row * 1.7), 0)
	for at in [Vector3(3, 0, 3), Vector3(4.3, 0, 3.3), Vector3(-4, 0, 10), Vector3(-24, 0, -17), Vector3(-25.3, 0, -17)]:
		_add_prop(at, 1)
	for at in [Vector3(-10, 0, 10), Vector3(-29, 0, 8), Vector3(-30, 0, 12)]:
		_add_prop(at, 2)
	for center in mob_centers:
		for offset in [Vector2(-2.8, 0), Vector2(2.8, 0), Vector2(0, -2.8)]:
			_add_mob(center + offset)
	# Reserve slots follow all nine originals, preserving old checkpoint indices.
	for center in mob_centers:
		for offset in [Vector2(-1.8, 2.5), Vector2(1.8, 2.5)]:
			_add_mob(center + offset, true)
	for at in dummy_positions:
		var dummy := PracticeDummy.new()
		dummy.position = ground_point.call(at.x, at.y)
		add_child(dummy)
		dummy.target.trains_weapons = true
		combat.targets.append(dummy.target)
		dummy_nodes.append(dummy)

func _add_mob(at: Vector2, rain_only: bool = false) -> void:
	var mob := TrainingMob.new()
	mob.rain_only = rain_only
	mob.position = ground_point.call(at.x, at.y, 0.1)
	mob.quarry = player
	mob.protected_area = protected_area
	add_child(mob)
	mob.set_rain(false)
	mob.target.trains_weapons = true
	combat.targets.append(mob.target)
	mob_nodes.append(mob)
	mob.attacked.connect(_mob_attacked.bind(mob))
	mob.defeated.connect(_mob_defeated)

func set_rain(wet: bool) -> void:
	for mob in mob_nodes: mob.set_rain(wet)

func _add_prop(at: Vector3, kind: int) -> void:
	var prop := HarvestProp.new()
	prop.position = ground_point.call(at.x, at.z)
	prop.kind = kind
	add_child(prop)
	combat.targets.append(prop.target)
	prop_nodes.append(prop)
	prop.harvested.connect(_harvested)

func _hurt_player(amount: float, source: Vector3) -> void:
	if player.motor.is_dashing:
		return
	if combat.equipment.defend(source):
		return
	amount *= combat.incoming_damage_multiplier
	if health.damage(amount):
		health.invulnerability = maxf(health.invulnerability, 0.8)
		CombatEffects.burst(self, player.global_position, "-" + str(int(amount)), Color("ff9b8c"))

func _harvested(at: Vector3, count: int) -> void:
	props += 1
	_drop(at, count)
	progress_changed.emit(beans, mobs, props)

func _mob_defeated(at: Vector3) -> void:
	mobs += 1
	experience += MOB_EXPERIENCE
	experience_changed.emit(experience)
	experience_awarded.emit(MOB_EXPERIENCE)
	_drop(at, 2)
	CombatEffects.burst(self, at, "+%d EXP" % MOB_EXPERIENCE, Color("b0e6cb"))
	progress_changed.emit(beans, mobs, props)

func _drop(at: Vector3, count: int) -> void:
	for index in count:
		if pickups.size() >= 128: break
		var bean := add_pickup(next_pickup_id, at + Vector3((index - (count - 1) * 0.5) * 0.8, 0, 0))
		bean.collector = player

func add_pickup(id: int, at: Vector3) -> SoybeanPickup:
	var bean := SoybeanPickup.new()
	bean.position = at
	add_child(bean)
	pickups[id] = bean
	next_pickup_id = maxi(next_pickup_id, id + 1)
	bean.tree_exiting.connect(func() -> void: pickups.erase(id))
	bean.collected.connect(_pickup_collected.bind(bean))
	return bean

func _pickup_collected(bean: SoybeanPickup) -> void:
	if party_collect.is_valid(): party_collect.call(bean.collector)
	else: _collect()

func _mob_attacked(amount: float, source: Vector3, mob: TrainingMob) -> void:
	if party_hurt.is_valid(): party_hurt.call(mob.quarry, amount, source)
	else: _hurt_player(amount, source)

func _collect() -> void:
	beans += 1
	var before := health.current
	health.heal(combat.tuning.soybean_healing)
	var healed := int(health.current - before)
	var feedback := "+%d HP" % healed if healed > 0 else "SOY +1"
	CombatEffects.burst(self, player.global_position, feedback, Color("c8efa0"))
	progress_changed.emit(beans, mobs, props)

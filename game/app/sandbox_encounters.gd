class_name SandboxEncounters
extends Node3D
## App-owned composition of combat actors, harvestables and healing drops.

signal progress_changed(beans: int, mobs: int, props: int)
signal experience_awarded(amount: int)
signal experience_changed(total: int)
signal mob_defeated(at: Vector3)
var mob_nodes: Array[TrainingMob] = []
var prop_nodes: Array[HarvestProp] = []
var dummy_nodes: Array[PracticeDummy] = []
var pickups: Dictionary[int, SoybeanPickup] = {}
var next_pickup_id: int = 1
var party_hurt: Callable
var party_collect: Callable
const MOB_EXPERIENCE: int = 25
const ARMORED_SNAIL_EXPERIENCE: int = 50
const SHELL_PIECE_DROP_CHANCE: float = 0.10
var experience: int = 0
var mob_centers: Array[Vector2] = []
var dummy_positions: Array[Vector2] = []
var protected_area: Rect2
var player: Player
var combat: PlayerCombat
var health: Damageable
var inventory: PlayerInventory
var ground_point: Callable
var shell_drop: Callable
var shell_drop_roll: Callable = func() -> float: return randf()
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
			var at: Vector2 = center + offset
			_add_mob(at)
	# Reserve slots follow all nine originals, preserving old checkpoint indices.
	for center in mob_centers:
		for offset in [Vector2(-1.8, 2.5), Vector2(1.8, 2.5)]:
			var at: Vector2 = center + offset
			_add_mob(at, true, FarmCombatGrounds.is_camp_armored_spawn(at))
	# The far meadow sites are single armored spawns and are appended for stable replica ordering.
	for at: Vector2 in FarmCombatGrounds.FOREST_ARMORED_SPAWNS:
		_add_mob(at, false, true, true)
	for at in dummy_positions:
		var dummy := PracticeDummy.new()
		dummy.position = ground_point.call(at.x, at.y)
		add_child(dummy)
		dummy.target.trains_weapons = true
		combat.targets.append(dummy.target)
		dummy_nodes.append(dummy)

func _add_mob(at: Vector2, rain_only: bool = false, armored: bool = false, free_roaming: bool = false) -> void:
	var mob: TrainingMob = ArmoredSnail.new() if armored else TrainingMob.new()
	mob.rain_only = rain_only
	mob.free_roaming = free_roaming
	mob.position = ground_point.call(at.x, at.y, 0.1)
	mob.quarry = player
	mob.protected_area = Rect2() if free_roaming else protected_area
	if free_roaming: mob.leash_radius = INF
	add_child(mob)
	mob.set_rain(false)
	mob.target.trains_weapons = true
	combat.targets.append(mob.target)
	mob_nodes.append(mob)
	mob.attacked.connect(_mob_attacked.bind(mob))
	mob.defeated.connect(_mob_defeated.bind(mob))

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
	if health.damage(amount, Vector3.ZERO, Damageable.HitKind.SLIME):
		health.invulnerability = maxf(health.invulnerability, 0.8)
		CombatEffects.burst(self, player.global_position, "-" + str(int(amount)), Color("ff9b8c"))

func _harvested(at: Vector3, count: int) -> void:
	props += 1
	_drop(at, count)
	progress_changed.emit(beans, mobs, props)

func _mob_defeated(at: Vector3, mob: TrainingMob) -> void:
	mobs += 1
	var reward := ARMORED_SNAIL_EXPERIENCE if mob is ArmoredSnail else MOB_EXPERIENCE
	experience += reward
	experience_changed.emit(experience)
	experience_awarded.emit(reward)
	mob_defeated.emit(at)
	_drop(at, 4 if mob is ArmoredSnail else 2)
	if mob is ArmoredSnail and shell_drop.is_valid() and float(shell_drop_roll.call()) < SHELL_PIECE_DROP_CHANCE:
		shell_drop.call("piece_of_shell", at)
	CombatEffects.burst(self, at, "+%d EXP" % reward, Color("b0e6cb"))
	progress_changed.emit(beans, mobs, props)

func _drop(at: Vector3, count: int) -> void:
	spawn_edamame(at, count, player)

func spawn_edamame(at: Vector3, count: int, actor: Node3D) -> bool:
	if count <= 0 or count > 100 or pickups.size() + count > 128: return false
	for index in count:
		var bean := add_pickup(next_pickup_id, at + Vector3((index - (count - 1) * 0.5) * 0.8, 0, 0))
		bean.collector = actor
	return true

func add_pickup(id: int, at: Vector3) -> SoybeanPickup:
	var bean := SoybeanPickup.new()
	bean.texture = CurrencyVisuals.icon("edamame", 1)
	bean.position = at
	add_child(bean)
	pickups[id] = bean
	next_pickup_id = maxi(next_pickup_id, id + 1)
	bean.tree_exiting.connect(func() -> void: pickups.erase(id))
	bean.collect_attempt = _pickup_collected.bind(bean)
	return bean

func _pickup_collected(bean: SoybeanPickup) -> bool:
	if party_collect.is_valid(): return bool(party_collect.call(bean.collector))
	return _collect()

func _mob_attacked(amount: float, source: Vector3, mob: TrainingMob) -> void:
	if party_hurt.is_valid(): party_hurt.call(mob.quarry, amount, source)
	else: _hurt_player(amount, source)

func _collect() -> bool:
	if inventory == null or inventory.add_item(InventoryItem.create_edamame(), 1) != 0: return false
	beans += 1
	CombatEffects.burst(self, player.global_position, "+1 EDAMAME", Color("c8efa0"))
	progress_changed.emit(beans, mobs, props)
	return true

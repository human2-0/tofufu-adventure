class_name SandboxEncounters
extends Node3D
## App-owned composition of combat actors, harvestables and healing drops.

signal progress_changed(beans: int, mobs: int, props: int)
signal experience_awarded(amount: int)
signal experience_changed(total: int)
signal mob_defeated(at: Vector3)
signal armored_snail_defeated
var mob_nodes: Array[TrainingMob] = []
var prop_nodes: Array[HarvestProp] = []
var dummy_nodes: Array[PracticeDummy] = []
var pickups: Dictionary[int, SoybeanPickup] = {}
var next_pickup_id: int = 1
var party_hurt: Callable
var party_collect: Callable
const MOB_EXPERIENCE: int = 25
const ARMORED_SNAIL_EXPERIENCE: int = 50
const BEE_EXPERIENCE: int = 75
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
var loot_chance: Callable
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
	# Keep every legacy encounter index; southern bees follow the forest roster.
	for at: Vector2 in FarmCombatGrounds.BEE_SPAWNS:
		_add_mob(at, false, false, false, true)
	for at in dummy_positions:
		var dummy := PracticeDummy.new()
		dummy.position = ground_point.call(at.x, at.y)
		add_child(dummy)
		dummy.target.trains_weapons = true
		combat.targets.append(dummy.target)
		dummy_nodes.append(dummy)

func _add_mob(at: Vector2, rain_only: bool = false, armored: bool = false, free_roaming: bool = false, bee: bool = false) -> void:
	var mob: TrainingMob = WildBee.new() if bee else (ArmoredSnail.new() if armored else TrainingMob.new())
	mob.rain_only = rain_only
	mob.free_roaming = free_roaming
	mob.position = ground_point.call(at.x, at.y, 0.1)
	mob.quarry = player
	mob.protected_area = protected_area.grow(FarmCombatGrounds.VILLAGE_SNAIL_MARGIN) if armored else (Rect2() if free_roaming else protected_area)
	if bee: mob.protected_area = protected_area.grow(FarmCombatGrounds.VILLAGE_BEE_MARGIN)
	if free_roaming: mob.leash_radius = INF
	add_child(mob)
	mob.set_rain(false)
	mob.target.trains_weapons = true
	combat.targets.append(mob.target)
	mob_nodes.append(mob)
	mob.targeting.connect(ActorProgression.threaten)
	mob.attacked.connect(_mob_attacked.bind(mob))
	mob.defeated.connect(_mob_defeated.bind(mob))
	if mob is WildBee: mob.stung.connect(_bee_stung.bind(mob))

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

func _hurt_player(amount: float, source: Vector3, kind: Damageable.HitKind = Damageable.HitKind.SLIME) -> void:
	if player.motor.is_dashing:
		return
	if combat.equipment.defend(source, amount):
		return
	amount *= combat.incoming_damage_multiplier
	if health.damage(amount, Vector3.ZERO, kind):
		health.invulnerability = maxf(health.invulnerability, 0.8)
		CombatEffects.burst(self, player.global_position, "-" + str(int(amount)), Color("ff9b8c"))

func _harvested(at: Vector3, count: int) -> void:
	props += 1
	_drop(at, count)
	progress_changed.emit(beans, mobs, props)

func _mob_defeated(at: Vector3, mob: TrainingMob) -> void:
	mobs += 1
	var reward := ARMORED_SNAIL_EXPERIENCE if mob is ArmoredSnail else MOB_EXPERIENCE
	if mob is WildBee: reward = BEE_EXPERIENCE
	experience += reward
	experience_changed.emit(experience)
	experience_awarded.emit(reward)
	mob_defeated.emit(at)
	if mob is ArmoredSnail: armored_snail_defeated.emit()
	_drop(at, 3 if mob is WildBee else (4 if mob is ArmoredSnail else 2))
	var chance := float(loot_chance.call(SHELL_PIECE_DROP_CHANCE, at)) if loot_chance.is_valid() else SHELL_PIECE_DROP_CHANCE
	if mob is ArmoredSnail and shell_drop.is_valid() and float(shell_drop_roll.call()) < chance:
		for index in (2 if mob.shell_health <= 0.0 else 1):
			shell_drop.call("piece_of_shell", at + Vector3.RIGHT * index * 0.35)
	CombatEffects.burst(self, at, "+%d EXP" % reward, Color("b0e6cb"))
	progress_changed.emit(beans, mobs, props)

func _drop(at: Vector3, count: int) -> void:
	spawn_edamame(at, count, player)

func spawn_edamame(at: Vector3, count: int, actor: Node3D) -> bool:
	if count <= 0 or count > 100 or pickups.size() + 1 > 128: return false
	var bean := add_pickup(next_pickup_id, at, count)
	bean.collector = actor
	return true

func add_pickup(id: int, at: Vector3, count: int = 1) -> SoybeanPickup:
	var bean := SoybeanPickup.new()
	bean.texture = CurrencyVisuals.icon("edamame", 1)
	bean.count = clampi(count, 1, 100)
	bean.position = at
	add_child(bean)
	pickups[id] = bean
	next_pickup_id = maxi(next_pickup_id, id + 1)
	bean.tree_exiting.connect(func() -> void: pickups.erase(id))
	bean.collect_attempt = _pickup_collected.bind(bean)
	return bean

func _pickup_collected(bean: SoybeanPickup) -> bool:
	if party_collect.is_valid(): return bool(party_collect.call(bean.collector, bean))
	return _collect(bean)

func _mob_attacked(amount: float, source: Vector3, mob: TrainingMob) -> void:
	if party_hurt.is_valid(): party_hurt.call(mob.quarry, amount, source)
	else: _hurt_player(amount, source)

func _bee_stung(victim: Node3D, amount: float, source: Vector3, bee: WildBee) -> void:
	if bee._protected(victim.global_position): return
	if party_hurt.is_valid(): party_hurt.call(victim, amount, source, Damageable.HitKind.MELEE)
	elif victim == player: _hurt_player(amount, source, Damageable.HitKind.MELEE)

func _collect(bean: SoybeanPickup) -> bool:
	if inventory == null: return false
	var requested := bean.count
	var remaining := inventory.add_item(InventoryItem.create_edamame(), requested)
	if remaining == requested: return false
	var collected := requested - remaining
	bean.count = remaining
	beans += collected
	CombatEffects.collect(self, player.global_position, collected)
	progress_changed.emit(beans, mobs, props)
	return true

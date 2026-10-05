class_name BarnDisplay
extends RefCounted
## Authority places drops on bay tables and releases their protection on departure.

static func spawn(items: WorldItems, combat: PlayerCombat, id: String, count: int, reserve: float, contents: Array = []) -> WorldItemDrop:
	var storage: SeedStorage = items.game.seed_storage
	if storage == null or not MeadowBarn.contains(items.game.world.seed_bank, combat.actor.global_position):
		return items.pool.spawn(id, count, combat.actor.global_position, combat.equipment.facing, reserve, contents)
	var index := storage.bay_for(combat.actor)
	if index < 0 or not storage.barn.permitted(index, combat.actor): return null
	for existing: WorldItemDrop in items.pool.drops.values():
		if existing.display_bay == index: return null
	var at: Vector3 = items.game.world.seed_bank.to_global(MeadowBarn.table_position(index) + Vector3.UP * 0.48)
	var drop := items.pool.spawn_at(id, count, reserve, at, contents)
	if drop == null: return null
	storage.barn.permitted(index, combat.actor, true)
	drop.display_bay = index
	drop.protected_owner = storage.barn.key(combat.actor)
	return drop

static func can_pickup(items: WorldItems, drop: WorldItemDrop, actor: Node3D) -> bool:
	if drop.display_bay < 0: return true
	var barn: Node3D = items.game.world.seed_bank
	var local := barn.to_local(actor.global_position)
	if (local - MeadowBarn.table_position(drop.display_bay)).dot(MeadowBarn.front(drop.display_bay)) < 0.5: return false
	return drop.protected_owner.is_empty() or drop.protected_owner == items.game.seed_storage.barn.key(actor)

static func release_departed(items: WorldItems) -> void:
	if items.game.seed_storage == null: return
	for drop: WorldItemDrop in items.pool.drops.values():
		if drop.display_bay < 0 or drop.protected_owner.is_empty(): continue
		var present := false
		for combat: PlayerCombat in items._inventories:
			if items.game.seed_storage.barn.key(combat.actor) == drop.protected_owner and items.game.seed_storage.bay_for(combat.actor) == drop.display_bay:
				present = true
				break
		if not present: drop.protected_owner = ""

static func adopt_solo(items: WorldItems, identity: String) -> void:
	for drop: WorldItemDrop in items.pool.drops.values():
		if drop.protected_owner == "solo": drop.protected_owner = identity

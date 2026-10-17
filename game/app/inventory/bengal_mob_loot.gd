class_name BengalMobLoot
extends RefCounted
## Exactly one unmodified 1% roll per Bengal defeat, on the authority only.

static func drop(items: WorldItems, at: Vector3) -> bool:
	if items == null or not items.pool.authoritative or not items.bengal_roll.is_valid(): return false
	var roll := float(items.bengal_roll.call())
	if not is_finite(roll) or roll < 0 or roll >= BengalPawsItem.DROP_CHANCE: return false
	return items.spawn_mob_loot(BengalPawsItem.ID, at)

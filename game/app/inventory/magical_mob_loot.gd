class_name MagicalMobLoot
extends RefCounted
## Host-only rare loot roll shared by meadow, factory and castle mobs.

static func drop(items: WorldItems, at: Vector3) -> bool:
	if items == null or not items.pool.authoritative: return false
	if not items.magic_roll.is_valid(): return false
	var roll := float(items.magic_roll.call())
	if not is_finite(roll) or roll < 0.0 or roll >= MagicalTofufu.DROP_CHANCE: return false
	return items.spawn_mob_loot(MagicalTofufu.ID, at)

class_name ActorWeaponEnhancement
extends RefCounted
## Loadout derives authority-owned bonuses; replicas only present snapshots.

static func apply(combat: PlayerCombat, stack: ItemStack) -> void:
	combat.equipment.weapon_enhanced = stack != null and stack.enhanced
	var multiplier := MagicalTofufu.power(stack)
	combat.gun.enhancement_multiplier = multiplier
	combat.sotjet.flow.enhancement_multiplier = multiplier
	combat.sotjet.consumption_multiplier = 1.0 / MagicalTofufu.SOYJET_DURATION_MULTIPLIER if combat.equipment.weapon_enhanced and combat.sotjet.selected else 1.0
	combat.gun.magazine_capacity = SoyGun.MAGAZINE_SIZE + (MagicalTofufu.MAGAZINE_BONUS if combat.equipment.weapon_enhanced and combat.gun.selected else 0)
	combat.gun.magazine = mini(combat.gun.magazine, combat.gun.magazine_capacity)

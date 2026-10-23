class_name BattleWeaponUpgrade
extends RefCounted
## Match-only additions to the shared one-chunk, one-weapon enhancement rules.
const RATE: float = 1.10
const BULLET_SPEED: float = 1.20
const SPREAD: float = 0.75
const REFLECTION_COST: float = 0.65

static func capacity(loadout: ActorLoadout) -> int:
	var active := loadout.equipment.get_slot("combat_%d" % loadout.active_slot)
	var guns: Array[ItemStack] = []
	for name in ["combat_1", "combat_2"]:
		var stack := loadout.equipment.get_slot(name)
		if stack != null and stack.item.id in ["soy_gun", "soy_raygun"]: guns.append(stack)
	if active in guns: return SoyGun.MAGAZINE_SIZE + (5 if active.enhanced else 0)
	for stack in guns:
		if stack.enhanced: return SoyGun.MAGAZINE_SIZE + 5
	return SoyGun.MAGAZINE_SIZE

static func apply(combat: PlayerCombat) -> void:
	if not combat.equipment.weapon_enhanced: return
	combat.attack_speed_multiplier *= RATE
	combat.gun.attack_speed_multiplier *= RATE
	combat.gun.projectile_speed_multiplier *= BULLET_SPEED
	combat.gun.projectile_lifetime /= BULLET_SPEED # Faster travel preserves weapon reach.
	combat.gun.spread_multiplier *= SPREAD
	combat.sotjet.attack_speed_multiplier *= RATE
	combat.sotjet.projectile_speed_multiplier = BULLET_SPEED
	combat.sotjet.flow.attack_cadence_multiplier *= RATE
	combat.bow.attack_speed_multiplier = RATE

static func bonus(id: String) -> String:
	if id in ["soy_gun", "soy_raygun"]:
		return "+20% damage · +5 magazine · +10% fire rate\n+20% bullet speed · 25% tighter spread"
	if id == "sotjet":
		return "+20% damage · +25% firing duration\n+10% fire rate · +20% stream speed"
	if id == "angel_bow": return "+20% damage · +10% reload rate"
	return "+20% damage · +10% attack rate\n35% less SP for bullet reflection when guarding"

class_name BattleBalance
extends Resource
## Match-only tuning; authored adventure resources and saved gear remain untouched.

const ITEMS: Array[String] = ["", "knife", "soy_gun", "edamame_sword", "nori_katana", "sproutwood_staff", "bengal_paws", "sotjet", "angel_bow", "celestial_sword", "celestial_staff", "soy_raygun"]
const MELEE_POWER := {1: 1.0, 3: 1.30, 4: 1.15, 5: 1.40, 6: 1.10, 9: 1.45, 10: 1.65}
const MELEE_RATE := {1: 1.0, 3: 0.92, 4: 1.18, 5: 0.82, 6: 1.16, 9: 1.12, 10: 0.96}

static func item(kind: int) -> InventoryItem:
	var result := InventoryItem.weapon(ITEMS[kind])
	result.required_level = 1
	return result

static func apply(combat: PlayerCombat, kind: int = 0) -> void:
	combat.tuning.bean_speed = 150.0
	combat.gun.projectile_lifetime = 0.6 # Preserve 90 m reach at 2.5 times Adventure speed.
	combat.gun.spread_multiplier = 1.0
	combat.sotjet.projectile_speed_multiplier = 1.0
	combat.bow.attack_speed_multiplier = 1.0
	combat.tuning.bean_damage = 18
	combat.tuning.bean_head_damage = 27
	combat.tuning.gun_cooldown = 0.22
	combat.tuning.punch_click_delay = 0.16
	combat.tuning.nori_speed = 1.0
	combat.tuning.staff_power = combat.tuning.knife_power # Match staves use the same hit baseline.
	combat.tuning.combo_critical_chance_cap = 0.25
	combat.tuning.combo_critical_damage_multiplier = 1.35
	# The shared Pod Sword already adds 20%; normalize it before match bonuses.
	combat.sword_damage_multiplier = float(MELEE_POWER.get(kind, 1.0)) / (1.2 if kind == 3 else 1.0)
	combat.fist_damage_multiplier = float(MELEE_POWER.get(kind, 1.0))
	combat.attack_speed_multiplier = float(MELEE_RATE.get(kind, 1.0))
	combat.gun.damage_multiplier = {8: 1.12, 11: 1.22}.get(kind, 1.0)
	combat.gun.attack_speed_multiplier = 0.94 if kind == 11 else 1.0
	combat.gun.projectile_speed_multiplier = 1.15 if kind == 11 else 1.0
	combat.sotjet.flow.damage_multiplier = 0.8

static func title(kind: int) -> String:
	return TranslationServer.translate("Bare fists") if kind == 0 else BattleRarity.title(kind, item(kind).name)

static func special(combat: PlayerCombat) -> String:
	var source := "RMB: guard · Release LMB: melee combo"
	var cooldown := 0.0
	if combat.gun.selected: source = "RMB: precision aim · Hold LMB: ricochet"
	elif combat.sotjet.selected: source = "RMB: precision aim · LMB: pressure stream"
	elif combat.bow.selected:
		source = "Hold RMB: flame arrow · Special %.1fs"
		cooldown = combat.bow.cooldown
	elif combat.claws.selected:
		source = "Hold RMB: Super Claw · Special %.1fs"
		cooldown = combat.claws.cooldown
	elif combat.equipment.nori_selected:
		source = "RMB: Nori plunge · Special %.1fs"
		cooldown = combat.plunge.cooldown
	elif combat.equipment.pod_selected:
		source = "RMB: Podburst · Special %.1fs"
		cooldown = combat.podburst.cooldown
	elif combat.equipment.staff_selected:
		source = "RMB: tornado · Special %.1fs"
		cooldown = combat.rules.cooldown
	var result := TranslationServer.translate(source)
	return result % cooldown if source.contains("%.1f") else result

class_name CelestialItems
extends RefCounted
## The Cloud Realm's ivory, laurel and starlight equipment definitions.

const IDS: Array[String] = ["celestial_helmet", "celestial_armor", "celestial_legs", "celestial_boots", "celestial_sword", "celestial_staff", "soy_raygun"]
const NAMES := {"celestial_helmet": "Celestial Laurel Helm", "celestial_armor": "Celestial Aegis", "celestial_legs": "Celestial Greaves", "celestial_boots": "Celestial Winged Boots", "celestial_sword": "Celestial Laurel Sword", "celestial_staff": "Olympian Star Staff", "soy_raygun": "Celestial Soy Raygun"}

static func create(id: String) -> InventoryItem:
	if id not in IDS: return null
	var item := InventoryItem.new()
	item.id = id
	item.name = NAMES[id]
	item.max_stack = 1
	item.healing_amount = 0.0
	item.required_level = 5
	if id in IDS.slice(0, 4):
		item.category = id.trim_prefix("celestial_")
		item.damage_reduction = 0.01
		item.description = "Requires level 5. Each piece grants 1% damage reduction. " + ApparelSetBonus.details(ApparelSetBonus.CELESTIAL)
		item.icon = load("res://assets/equipment/celestial/" + item.category + ".png") as Texture2D
	else:
		item.category = "combat"
		item.weapon_level = 3
		item.weapon_power = 5 if id == "celestial_staff" else (20 if id == "soy_raygun" else 10)
		item.description = {
			"celestial_sword": "Requires level 5. An ivory and gold laurel blade from Nimbus's royal armory. Uses the sword's four-move combos, charged cuts and directional guard.",
			"celestial_staff": "Requires level 5. A star-crowned Olympian staff. Charge and release for melee strikes; RMB performs the staff's sweeping spin.",
			"soy_raygun": "Requires level 5. Fires starlight soy rays. Nine shots per magazine, two-second reload; sustain LMB to charge a ricocheting ray. RMB aims precisely.",
		}[id]
		item.icon = load("res://assets/weapons/celestial/" + id + ".png") as Texture2D
	return item

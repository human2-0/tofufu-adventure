class_name CoopDuelAgreement
extends RefCounted
## Both fighters explicitly accept the same ranged mode; melee loans are personal.

const MELEE: Array[String] = ["", "knife", "edamame_sword", "nori_katana", "sproutwood_staff", "celestial_sword", "celestial_staff"]
var choices: Array[Dictionary] = []
var remaining: float = 60.0

func reset() -> void:
	choices = [{"ranged": "soy_gun", "melee": "knife", "ready": false}, {"ranged": "soy_gun", "melee": "knife", "ready": false}]
	remaining = 60.0

func accept(index: int, ranged: String, melee: String) -> bool:
	if index not in [0, 1] or ranged not in ["soy_gun", "sotjet"] or melee not in MELEE: return false
	choices[index] = {"ranged": ranged, "melee": melee, "ready": true}
	return choices[0].ready and choices[1].ready and choices[0].ranged == choices[1].ranged

static func apply(member: CoopActor, choice: Dictionary) -> void:
	var base := CharacterProgress.new()
	member.progression.progress.restore(base.capture())
	for slot in ["helmet", "armor", "legs", "boots", "accessory", "support_1", "support_2", "support_3", "support_4"]:
		member.character_equipment.set_slot(slot, null)
	var melee: ItemStack
	if not str(choice.melee).is_empty():
		var item := InventoryItem.weapon(choice.melee)
		# A match loan has no level gate; the saved world item is never modified.
		item.required_level = 1
		melee = ItemStack.new(item, 1)
	member.character_equipment.set_slot("combat_1", melee)
	member.character_equipment.set_slot("combat_2", ItemStack.new(InventoryItem.weapon(choice.ranged), 1))
	member.loadout.active_slot = 2
	member.loadout.refresh(false)
	member.combat.gun.magazine = SoyGun.MAGAZINE_SIZE
	member.combat.gun.reload_remaining = 0.0
	member.combat.gun.projectile_speed_multiplier = 2.0
	member.combat.sotjet.projectile_speed_multiplier = 2.0
	member.combat.sotjet.milk = 100.0
	member.health.armor_multiplier = 1.0

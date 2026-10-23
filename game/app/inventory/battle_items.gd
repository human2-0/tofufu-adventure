class_name BattleItems
extends RefCounted
## Shared adventure definitions become level-one loans with honest match tooltips.
const DESCRIPTIONS := {
	"knife": "Hold and release LMB for melee combos. RMB guards. Match weapons have no saved level or training bonuses.",
	"soy_gun": "LMB fires soybeans. R reloads the nine-shot magazine; RMB aims precisely. Hold LMB for a charged ricochet.",
	"edamame_sword": "Melee combos with a pushing Podburst on RMB. Podburst has a three-second cooldown.",
	"nori_katana": "Long-reaching melee combos. Hold RMB to rise and steer, then release to plunge: 75 SP, triple damage in a 2.6m radius.",
	"sproutwood_staff": "Hold and release LMB for charged melee strikes. RMB performs a sweeping tornado attack.",
	"bengal_paws": "LMB: unarmed combos. Hold RMB for a Super Claw dash and rift cut: 20 SP, eight-second cooldown. Held Paws improve movement and reduce dash cost.",
	"sotjet": "A pressure stream fuelled by a milk tank. RMB aims precisely; release LMB to let the tank refill.",
	"angel_bow": "LMB fires an arrow, followed by a two-second reload. Hold RMB for a flame arrow: 25 SP, six-second special cooldown.",
}

static func make(kind: int) -> InventoryItem:
	var item := InventoryItem.from_id(BattlePackWire.ITEMS[kind - 1])
	item.required_level = 1
	item.name = "%s · %s" % [BattleRarity.NAMES[BattleRarity.grade(kind)], item.name]
	var base: String = {"celestial_sword": "knife", "celestial_staff": "sproutwood_staff", "soy_raygun": "soy_gun"}.get(item.id, item.id)
	if DESCRIPTIONS.has(base): item.description = DESCRIPTIONS[base]
	if item.id == MagicalTofufu.ID:
		item.description = "Match upgrade material. Basic / rare / legendary chests: 10% / 35% / 70% chance. Apply to a weapon in your bag and confirm. Once per weapon; expires with this match."
	if item.category in CharacterEquipment.APPAREL_SLOTS:
		item.damage_reduction = float(BattleWearStats.BONUSES[BattleWearStats.family(item)][0]) / 4.0
		item.description = "Temporary match armour. Each piece grants one quarter of its set modifiers and has 50 durability. A complete matching set cannot break; protection is capped at 25%."
	return item

static func details(item: InventoryItem) -> String:
	if item.category not in CharacterEquipment.APPAREL_SLOTS:
		var role := BattleWeaponRoles.text(item.id)
		return role + "\n\n" + TranslationServer.translate(ItemTooltipContent.details(item)) if not role.is_empty() else ItemTooltipContent.details(item)
	var per_piece := TranslationServer.translate("Per piece: %.2f%% protection and one quarter of its set modifiers.") % (item.damage_reduction * 100)
	var set_id := item.id.trim_suffix("_" + item.category)
	var bonus := "Full set: 25% protection, damage +20%, attack speed +12%, movement +10%. Divine aura."
	if set_id == "bright_leaf": bonus = "Full set: 12% protection, melee damage +10%, ranged damage -5%, movement -5%."
	if set_id == "dark_leaf": bonus = "Full set: 20% protection, movement and fire rate +10%, melee damage -10%."
	return per_piece + "\n" + TranslationServer.translate(bonus)

static func label(item: InventoryItem) -> String:
	var kind := BattlePackWire.ITEMS.find(item.id) + 1
	var prefix := BattleRarity.NAMES[BattleRarity.grade(kind)] + " · "
	return BattleRarity.title(kind, item.name.trim_prefix(prefix))

static func encode(stack: ItemStack) -> Array:
	if stack == null or stack.item == null or stack.count <= 0: return []
	return [BattlePackWire.ITEMS.find(stack.item.id) + 1, stack.count, BattleCombatWire.precision(stack.reserve)] + ([true] if stack.enhanced else [])

static func decode(value: Array) -> ItemStack:
	if value.is_empty(): return null
	var result := ItemStack.new(make(int(value[0])), int(value[1]))
	result.reserve = float(value[2])
	result.enhanced = value.size() == 4 and value[3] == true
	return result

static func weapon_kind(stack: ItemStack) -> int:
	return BattleBalance.ITEMS.find(stack.item.id) if stack != null else 0

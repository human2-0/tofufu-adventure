class_name MagicalTofufu
extends RefCounted
## Authored enhancement material and per-weapon bonus values.

const ID: String = "magical_tofufu_chunk"
const DAMAGE_MULTIPLIER: float = 1.20
const MAGAZINE_BONUS: int = 5
const SOYJET_DURATION_MULTIPLIER: float = 1.25
const DROP_CHANCE: float = 0.001
const ICON: Texture2D = preload("res://assets/items/magical_tofufu/chunk.png")

static func create() -> InventoryItem:
	var item := InventoryItem.new()
	item.id = ID
	item.name = "Magical Tofufu Chunk"
	item.description = "Rare mob drop (0.1%). Apply onto a weapon in your inventory and confirm: +20% weapon damage, +5 magazine capacity for guns, or +25% continuous firing time for Soyjet. Consumes one chunk. Permanent; once per weapon."
	item.icon = ICON
	item.category = "material"
	item.max_stack = 50
	item.healing_amount = 0.0
	return item

static func power(stack: ItemStack) -> float:
	return DAMAGE_MULTIPLIER if stack != null and stack.enhanced else 1.0

static func bonus_text(id: String) -> String:
	if id in ["soy_gun", "soy_raygun"]: return "+20% weapon damage · +5 magazine capacity"
	if id == "sotjet": return "+20% weapon damage · +25% continuous firing time"
	return "+20% weapon damage"

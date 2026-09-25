class_name WeaponTrade
extends RefCounted

const PURCHASE_PRICE: int = 0
const SALE_PRICE: int = 1
const TENDER_ID := "mature_bean"
const BUYABLE_IDS: Array[String] = [
	"knife", "soy_gun", "sotjet", "sproutwood_staff", "traveler_backpack",
	"bright_leaf_helmet", "bright_leaf_armor", "bright_leaf_legs", "bright_leaf_boots",
	"dark_leaf_helmet", "dark_leaf_armor", "dark_leaf_legs", "dark_leaf_boots"
]

static func purchase(inventory: PlayerInventory, item_id: String) -> String:
	if item_id not in BUYABLE_IDS: return "That item is not for sale."
	var item := InventoryItem.from_id(item_id)
	if item != null and item.category not in ["combat", "backpack", "helmet", "armor", "legs", "boots"]: item = null
	if item == null: return "That item is not for sale."
	if inventory == null: return "Your bag is unavailable."
	if inventory.count_item(TENDER_ID) < PURCHASE_PRICE: return "You need %d Mature Bean%s." % [PURCHASE_PRICE, "" if PURCHASE_PRICE == 1 else "s"]
	if not inventory.has_space_for(item): return "Your bag is full. Make room before buying."
	if PURCHASE_PRICE > 0 and inventory.remove_item(TENDER_ID, PURCHASE_PRICE) != PURCHASE_PRICE: return "Currency changed; try again."
	if inventory.add_item(item, 1) == 0: return "Bought %s for %d Mature Beans. Equip it from your bag." % [item.name, PURCHASE_PRICE]
	if PURCHASE_PRICE > 0: inventory.add_item(InventoryItem.currency(TENDER_ID), PURCHASE_PRICE)
	return "Purchase failed safely; no currency was spent."

static func sell(inventory: PlayerInventory, slot: int, expected_id: String) -> String:
	var stack := inventory.get_slot(slot)
	if stack == null or stack.item == null or stack.item.id != expected_id:
		return "That item is no longer in this bag slot."
	if stack.item.category != "combat": return "Kaji only buys combat equipment."
	var name := stack.item.name
	stack.count -= 1
	if stack.count == 0: inventory.slots[slot] = null
	var overflow := inventory.add_item(InventoryItem.currency(TENDER_ID), SALE_PRICE)
	if overflow > 0:
		stack.count += 1
		if inventory.slots[slot] == null: inventory.slots[slot] = stack
		return "Make room for a Mature Bean before selling."
	return "Sold one %s for 1 Mature Bean." % name

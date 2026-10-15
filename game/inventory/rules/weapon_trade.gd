class_name WeaponTrade
extends RefCounted

const PURCHASE_PRICE: int = 0
const SALE_PRICE: int = 1
const TENDER_ID := "mature_bean"
const BUYABLE_IDS: Array[String] = [
	"knife", "nori_katana", "edamame_sword", "soy_gun", "sotjet", "sproutwood_staff", "traveler_backpack",
	"bright_leaf_helmet", "bright_leaf_armor", "bright_leaf_legs", "bright_leaf_boots",
	"dark_leaf_helmet", "dark_leaf_armor", "dark_leaf_legs", "dark_leaf_boots",
	"celestial_helmet", "celestial_armor", "celestial_legs", "celestial_boots", "celestial_sword", "celestial_staff", "soy_raygun",
	MagicalTofufu.ID
]

static func purchase(inventory: PlayerInventory, item_id: String, equipment: CharacterEquipment = null) -> String:
	if item_id not in BUYABLE_IDS: return "That item is not for sale."
	var item := InventoryItem.from_id(item_id)
	if item != null and item.id != MagicalTofufu.ID and item.category not in ["combat", "backpack", "helmet", "armor", "legs", "boots"]: item = null
	if item == null: return "That item is not for sale."
	if inventory == null: return "Your bag is unavailable."
	if inventory.count_item(TENDER_ID) < PURCHASE_PRICE: return "You need %d Mature Bean%s." % [PURCHASE_PRICE, "" if PURCHASE_PRICE == 1 else "s"]
	var stack := ItemStack.new(item, 1)
	var equip_slot := _empty_slot(equipment, stack)
	if equip_slot.is_empty() and not inventory.has_space_for(item): return "Your bag is full. Make room before buying."
	if PURCHASE_PRICE > 0 and inventory.remove_item(TENDER_ID, PURCHASE_PRICE) != PURCHASE_PRICE: return "Currency changed; try again."
	if not equip_slot.is_empty():
		equipment.set_slot(equip_slot, stack)
		if equip_slot == "backpack": inventory.set_capacity(item.storage_slots)
		return "Bought %s for %d Mature Beans. Equipped immediately." % [item.name, PURCHASE_PRICE]
	if inventory.add_item(item, 1) == 0: return "Bought %s for %d Mature Beans. Equip it from your bag." % [item.name, PURCHASE_PRICE]
	if PURCHASE_PRICE > 0: inventory.add_item(InventoryItem.currency(TENDER_ID), PURCHASE_PRICE)
	return "Purchase failed safely; no currency was spent."

static func _empty_slot(equipment: CharacterEquipment, stack: ItemStack) -> String:
	if equipment == null: return ""
	for slot_name in CharacterEquipment.SLOTS:
		if equipment.get_slot(slot_name) == null and equipment.can_equip(slot_name, stack):
			return slot_name
	return ""

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

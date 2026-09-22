class_name WeaponTrade
extends RefCounted

const PRICE: int = 1

static func purchase(inventory: PlayerInventory, item_id: String) -> String:
	var item := InventoryItem.weapon(item_id)
	if item == null: return "That item is not for sale."
	if inventory.coins < PRICE: return "You need 1 coin."
	for i in PlayerInventory.CAPACITY:
		if inventory.get_slot(i) == null:
			inventory.coins -= PRICE
			inventory.set_slot(i, ItemStack.new(item, 1))
			return "Bought %s. Equip it from your bag." % item.name
	return "Your bag is full. Make room before buying."

static func sell(inventory: PlayerInventory, slot: int, expected_id: String) -> String:
	var stack := inventory.get_slot(slot)
	if stack == null or stack.item == null or stack.item.id != expected_id:
		return "That item is no longer in this bag slot."
	if inventory.coins >= 1000000: return "Your coin purse is full."
	var name := stack.item.name
	stack.count -= 1
	if stack.count == 0: inventory.slots[slot] = null
	inventory.coins += 1
	inventory.changed.emit()
	return "Sold one %s for 1 coin." % name

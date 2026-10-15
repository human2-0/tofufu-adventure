class_name WeaponEnhancement
extends RefCounted
## Atomic chunk consumption; operates on the actual destination weapon instance.

static func apply(bag: PlayerInventory, gear: CharacterEquipment, slot: int, destination: ItemStack) -> bool:
	var chunk := bag.get_slot(slot)
	if chunk == null or chunk.item == null or chunk.item.id != MagicalTofufu.ID: return false
	if destination == null or destination.item == null or destination.item.category != "combat": return false
	if destination.enhanced or destination.count != 1 or chunk.count < 1: return false
	destination.enhanced = true
	chunk.count -= 1
	if chunk.count == 0: bag.slots[slot] = null
	bag.changed.emit()
	gear.changed.emit()
	return true

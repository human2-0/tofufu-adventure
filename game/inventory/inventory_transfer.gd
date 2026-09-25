class_name InventoryTransfer
extends RefCounted
## Validated inventory mutations shared by solo play and the co-op authority.

static func valid_slot(source: Variant, id: Variant) -> bool:
	if not source is String: return false
	if source == "inventory":
		return (id is int or id is float) and is_finite(float(id)) and float(id) == floor(float(id)) and id >= 0 and id < PlayerInventory.MAX_CAPACITY
	return source == "equipment" and id is String and id in CharacterEquipment.SLOTS

static func apply(inventory: PlayerInventory, equipment: CharacterEquipment, src: String, src_id: Variant, dst: String, dst_id: Variant) -> bool:
	if inventory == null or equipment == null: return false
	if not valid_slot(src, src_id) or not valid_slot(dst, dst_id): return false
	if (src == "inventory" and int(src_id) >= inventory.capacity) or (dst == "inventory" and int(dst_id) >= inventory.capacity): return false
	if src == dst and src_id == dst_id: return false
	var stack := inventory.get_slot(int(src_id)) if src == "inventory" else equipment.get_slot(str(src_id))
	if stack == null: return false
	var other := inventory.get_slot(int(dst_id)) if dst == "inventory" else equipment.get_slot(str(dst_id))
	if dst == "equipment" and not equipment.can_equip(str(dst_id), stack): return false
	var replaces_backpack: bool = (src == "equipment" and src_id == "backpack") or (dst == "equipment" and dst_id == "backpack")
	var equipped_after: ItemStack = equipment.get_slot("backpack")
	if dst == "equipment" and dst_id == "backpack": equipped_after = stack
	elif src == "equipment" and src_id == "backpack": equipped_after = other
	if replaces_backpack:
		if equipped_after == null or equipped_after.item == null or equipped_after.item.category != "backpack": return false
		if inventory.has_overflow_for(equipped_after.item.storage_slots): return false
	if other != null and stack.item.id == other.item.id and other.item.max_stack > 1:
		var moved := mini(stack.count, other.item.max_stack - other.count)
		if moved <= 0: return false
		other.count += moved
		stack.count -= moved
		if stack.count == 0:
			if src == "inventory": inventory.slots[int(src_id)] = null
			else: equipment.slots[str(src_id)] = null
		if src == "inventory" or dst == "inventory": inventory.changed.emit()
		if src == "equipment" or dst == "equipment": equipment.changed.emit()
		return true
	if src == "equipment" and not equipment.can_equip(str(src_id), other): return false
	if src == "inventory" and dst == "inventory":
		inventory.swap_slots(int(src_id), int(dst_id))
		return true
	# Change both slots before emitting, so listeners never observe duplicated items.
	if src == "inventory": inventory.slots[int(src_id)] = other
	else: equipment.slots[str(src_id)] = other
	if dst == "inventory": inventory.slots[int(dst_id)] = stack
	else: equipment.slots[str(dst_id)] = stack
	if src == "inventory" or dst == "inventory": inventory.changed.emit()
	equipment.changed.emit()
	if replaces_backpack: inventory.set_capacity(equipped_after.item.storage_slots)
	return true

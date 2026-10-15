class_name InventoryProtocol
extends RefCounted
## Bounded optional item records, including legacy unenhanced stacks.

static func valid(data: Dictionary) -> bool:
	for field in ["inventory", "seed_storage", "pending_items"]:
		if not data.has(field): continue
		var limit := 32 if field == "pending_items" else (24 if field == "seed_storage" else 20)
		if not data[field] is Array or data[field].size() > limit: return false
		for row: Variant in data[field]:
			if not row is Dictionary or (not row.is_empty() and not WorldProtocol._stack(row)): return false
	if data.has("equipment"):
		if not data.equipment is Dictionary or data.equipment.size() > 12: return false
		for key: Variant in data.equipment:
			if key not in ["helmet", "armor", "legs", "boots", "backpack", "accessory", "combat_1", "combat_2", "support_1", "support_2", "support_3", "support_4", "healing_1", "healing_2", "healing_3", "healing_4"]: return false
			var row: Variant = data.equipment[key]
			if not row is Dictionary or (not row.is_empty() and not WorldProtocol._stack(row)): return false
	return true

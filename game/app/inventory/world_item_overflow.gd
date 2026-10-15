class_name WorldItemOverflow
extends RefCounted
## Releases saved pending weapon instances through the bounded drop pool.

static func release(items: WorldItems) -> void:
	# Legacy saves with full bags recover overflow without destroying weapons.
	if items.pool.authoritative:
		for combat: PlayerCombat in items._inventories:
			var inv: PlayerInventory = items._inventories[combat]
			if not inv.pending_items.is_empty():
				var stack: ItemStack = inv.pending_items[0]
				var drop := items.pool.spawn(stack.item.id, stack.count, combat.actor.global_position, combat.equipment.facing, stack.reserve)
				if drop != null:
					drop.enhanced = stack.enhanced
					inv.pending_items.pop_front()

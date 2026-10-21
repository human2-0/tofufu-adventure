class_name BattlePackActions
extends RefCounted
## Atomic, authority-only transfers. Source slot revisions prevent stale UI swaps.
var pack: BattlePack

func take(slot: int, id: int) -> bool:
	var fighter := pack.game.combat.fighters[slot]
	for drop: Array in pack.game.match_state.drops:
		if int(drop[0]) != id or drop[5] <= 0: continue
		if not pack.reachable(slot, Vector3(drop[1], drop[2], drop[3])): return false
		var stack := BattleItems.decode([drop[4], drop[5], drop[6]])
		if not fighter.loadout.inventory.has_space_for(stack.item, stack.count): return false
		if fighter.loadout.inventory.add_stack(stack) != 0: return false
		drop[5] = 0
		pack.refresh(slot)
		return true
	return false

func transfer(slot: int, source: int, src: int, target: int, dst: int) -> bool:
	var loadout := pack.game.combat.fighters[slot].loadout
	var a := "inventory" if source == 0 else "equipment"
	var b := "inventory" if target == 0 else "equipment"
	if (source == 1 and src >= CharacterEquipment.SLOTS.size()) or (target == 1 and dst >= CharacterEquipment.SLOTS.size()): return false
	var src_id: Variant = src if source == 0 else CharacterEquipment.SLOTS[src]
	var dst_id: Variant = dst if target == 0 else CharacterEquipment.SLOTS[dst]
	if not InventoryTransfer.apply(loadout.inventory, loadout.equipment, a, src_id, b, dst_id): return false
	pack.refresh(slot)
	return true

func consume(slot: int, source: int, index: int) -> bool:
	var fighter := pack.game.combat.fighters[slot]
	var heal := pack.healing[slot]
	var stack := fighter.loadout.inventory.get_slot(index) if source == 0 else fighter.loadout.equipment.get_slot(CharacterEquipment.SLOTS[index])
	if stack == null or heal.cooldown_remaining > 0: return false
	if stack.item.id != "apple" and heal.active_heal_remaining > 0: return false
	fighter.health.current = pack.game.match_state.rows[slot][8]
	var consumed := heal.consume_from_bag(fighter.loadout.inventory, index) if source == 0 else heal.use_slot(CharacterEquipment.SLOTS[index])
	if not consumed: return false
	pack.game.match_state.stats[slot][BattleRoundStats.FOOD] += 1
	heal.cooldown_remaining = stack.item.cooldown
	heal.cooldown_total = stack.item.cooldown
	pack.refresh(slot)
	return true

func drop(slot: int, source: int, index: int) -> bool:
	var fighter := pack.game.combat.fighters[slot]
	var loadout := fighter.loadout
	if source == 1 and (index >= CharacterEquipment.SLOTS.size() or index == 4): return false
	loadout.persist_reserve()
	var stack := loadout.inventory.get_slot(index) if source == 0 else loadout.equipment.get_slot(CharacterEquipment.SLOTS[index])
	if stack == null: return false
	var at := fighter.actor.position
	if not pack.spawn(stack, at): return false
	if source == 0: loadout.inventory.set_slot(index, null)
	else: loadout.equipment.set_slot(CharacterEquipment.SLOTS[index], null)
	pack.refresh(slot)
	return true

func drop_all(slot: int) -> void:
	var fighter := pack.game.combat.fighters[slot]
	var loadout := fighter.loadout
	loadout.persist_reserve()
	var stacks: Array[ItemStack] = loadout.inventory.slots.duplicate()
	for name in CharacterEquipment.SLOTS: stacks.append(loadout.equipment.get_slot(name))
	var counter := 0
	for stack in stacks:
		if stack == null: continue
		var angle := counter * 2.39996
		var offset := Vector3(cos(angle), 0, sin(angle)) * (0.4 + 0.18 * sqrt(counter))
		pack.spawn(stack, pack.drop_point(slot, offset))
		counter += 1
	loadout._restoring = true
	loadout.inventory.clear()
	for name in CharacterEquipment.SLOTS:
		if name != "backpack": loadout.equipment.set_slot(name, null)
	# The empty starter backpack remains as a harmless container on eliminated actors.
	loadout.equipment.set_slot("backpack", ItemStack.new(InventoryItem.backpack("factory_backpack"), 1))
	loadout._restoring = false
	pack.refresh(slot)
	pack.healing[slot].active_heal_remaining = 0
	pack.healing[slot].apple_duration_remaining = 0

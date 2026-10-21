class_name BattlePackSnapshot
extends RefCounted
## Bounded compact gear plus ongoing healing; unchanged bags retain their Resources.

static func capture(pack: BattlePack, force: bool = false) -> Array:
	var result: Array = []
	for slot in pack.game.bodies.size():
		var fighter := pack.game.combat.fighters[slot]
		var cached: Array = pack.snapshots[slot]
		var bag: Array = cached[1] if not cached.is_empty() else []
		var worn: Array = cached[2] if not cached.is_empty() else []
		if force or cached.is_empty() or int(cached[0]) != pack.revisions[slot]:
			fighter.loadout.persist_reserve()
			bag = []
			worn = []
			for stack in fighter.loadout.inventory.slots: bag.append(BattleItems.encode(stack))
			for name in CharacterEquipment.SLOTS: worn.append(BattleItems.encode(fighter.loadout.equipment.get_slot(name)))
		var heal := pack.healing[slot]
		var row: Array = [pack.revisions[slot], bag, worn, BattleCombatWire.precision([heal.cooldown_remaining, heal.cooldown_total, heal.active_heal_remaining, heal.active_heal_rate, heal.apple_duration_remaining])]
		pack.snapshots[slot] = row
		result.append(row)
	return result

static func apply(pack: BattlePack, values: Array, force: bool = false) -> void:
	for slot in pack.game.bodies.size():
		var row: Array = values[slot]
		var fighter := pack.game.combat.fighters[slot]
		if force or int(row[0]) != pack.revisions[slot]:
			var loadout := fighter.loadout
			loadout._restoring = true
			for i in CharacterEquipment.SLOTS.size(): loadout.equipment.set_slot(CharacterEquipment.SLOTS[i], BattleItems.decode(row[2][i]))
			loadout.inventory.set_capacity(row[1].size())
			for i in row[1].size(): loadout.inventory.slots[i] = BattleItems.decode(row[1][i])
			loadout._restoring = false
			fighter._gear.clear()
			fighter.equip(pack.game.match_state.rows[slot])
			loadout.inventory.changed.emit()
			pack.revisions[slot] = int(row[0])
			pack.snapshots[slot] = []
		var heal := pack.healing[slot]
		heal.cooldown_remaining = float(row[3][0])
		heal.cooldown_total = float(row[3][1])
		heal.active_heal_remaining = float(row[3][2])
		heal.active_heal_rate = float(row[3][3])
		heal.apple_duration_remaining = float(row[3][4])

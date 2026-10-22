class_name BattlePackBots
extends RefCounted
## CPUs use the same finite bags, equipment transfers and consumables as humans.

static func equip(pack: BattlePack, slot: int) -> void:
	var loadout := pack.game.combat.fighters[slot].loadout
	for i in loadout.inventory.capacity:
		var stack := loadout.inventory.get_slot(i)
		if stack == null: continue
		var destination := ""
		var category := stack.item.category
		if category in CharacterEquipment.APPAREL_SLOTS or category == "backpack": destination = category
		elif category == "combat": destination = "combat_1" if BattleItems.weapon_kind(stack) in BattleGear.MELEE else "combat_2"
		elif category == "support":
			for name in ["support_1", "support_2", "support_3", "support_4"]:
				if loadout.equipment.get_slot(name) == null: destination = name; break
		if destination.is_empty(): continue
		var existing := loadout.equipment.get_slot(destination)
		if existing != null:
			if existing.item.id == stack.item.id and (category not in CharacterEquipment.APPAREL_SLOTS or existing.reserve >= stack.reserve - 10): continue
			if category == "backpack" and existing.item.storage_slots >= stack.item.storage_slots: continue
			if category in CharacterEquipment.APPAREL_SLOTS:
				var worn := CharacterEquipment.SLOTS.find(destination)
				if not wants(_values(loadout), BattlePackWire.ITEMS.find(stack.item.id) + 1, worn, stack.reserve): continue
			if category == "combat" and not wants(_values(loadout), BattlePackWire.ITEMS.find(stack.item.id) + 1): continue
		pack.transactions.transfer(slot, 0, i, 1, CharacterEquipment.SLOTS.find(destination))

static func wants(values: Array, kind: int, worn: int = -1, reserve: float = 100.0) -> bool:
	var category: String = BattlePackWire.CATEGORIES[kind - 1]
	if category == "support": return true
	if worn < 0:
		worn = 6 if kind in BattleGear.MELEE else 7
		if category != "combat": worn = BattlePackWire.SLOTS.find(category)
	var existing: Array = values[2][worn]
	if existing.is_empty(): return true
	if existing[0] == kind:
		return category in CharacterEquipment.APPAREL_SLOTS and reserve > float(existing[2]) + 10 and not _complete(values[2])
	if category == "backpack": return kind > int(existing[0])
	if category == "combat": return BattleRarity.grade(kind) > BattleRarity.grade(int(existing[0]))
	if BattleRarity.grade(kind) != BattleRarity.grade(int(existing[0])):
		return BattleRarity.grade(kind) > BattleRarity.grade(int(existing[0]))
	var family := floori(float(kind - 12) / 4)
	var old_family := floori(float(int(existing[0]) - 12) / 4)
	var score := 0
	var previous := 0
	for i in 4:
		var piece: Array = values[2][i]
		if piece.is_empty(): continue
		if floori(float(int(piece[0]) - 12) / 4) == family: score += 2
		if floori(float(int(piece[0]) - 12) / 4) == old_family: previous += 2
	for piece: Array in values[1]:
		if piece.is_empty() or int(piece[0]) < 12 or int(piece[0]) > 23: continue
		if floori(float(int(piece[0]) - 12) / 4) == family: score += 1
		if floori(float(int(piece[0]) - 12) / 4) == old_family: previous += 1
	return score + 1 > previous

static func _values(loadout: ActorLoadout) -> Array:
	var bag: Array = []
	var worn: Array = []
	for stack in loadout.inventory.slots: bag.append(BattleItems.encode(stack))
	for name in CharacterEquipment.SLOTS: worn.append(BattleItems.encode(loadout.equipment.get_slot(name)))
	return [0, bag, worn]

static func heal(pack: BattlePack, slot: int) -> void:
	if pack.game.match_state.rows[slot][8] >= 65: return
	for i in range(8, 12):
		if pack.transactions.consume(slot, 1, i): return
	var inventory := pack.game.combat.fighters[slot].loadout.inventory
	for i in inventory.capacity:
		if pack.transactions.consume(slot, 0, i): return

static func _complete(worn: Array) -> bool:
	if worn[0].is_empty(): return false
	var first := int(worn[0][0])
	if first not in [12, 16, 20]: return false
	for i in 4:
		if worn[i].is_empty() or int(worn[i][0]) != first + i: return false
	return true

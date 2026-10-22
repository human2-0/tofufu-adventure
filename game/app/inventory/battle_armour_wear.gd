class_name BattleArmourWear
extends RefCounted
## Match-only integrity uses the stack's replicated 0..100 resource reserve.
const MAXIMUM: float = 50.0

static func remaining(stack: ItemStack) -> float:
	return stack.reserve * MAXIMUM / 100.0 if stack != null else 0.0

static func damage(pack: BattlePack, slot: int, amount: float) -> void:
	if amount <= 0: return
	var loadout := pack.game.combat.fighters[slot].loadout
	if not loadout.equipment.complete_set().is_empty(): return
	var names: Array[String] = []
	for name in CharacterEquipment.APPAREL_SLOTS:
		if loadout.equipment.get_slot(name) != null: names.append(name)
	if names.is_empty(): return
	var share := amount / names.size()
	var broken := false
	loadout._restoring = true
	for name in names:
		var stack := loadout.equipment.get_slot(name)
		stack.reserve = maxf(0, stack.reserve - share * 100.0 / MAXIMUM)
		if stack.reserve <= 0:
			loadout.equipment.set_slot(name, null)
			broken = true
	loadout._restoring = false
	if broken: pack.refresh(slot)
	else: pack.revisions[slot] += 1
	loadout._restoring = true
	loadout.equipment.changed.emit()
	loadout._restoring = false

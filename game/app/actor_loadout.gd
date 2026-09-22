class_name ActorLoadout
extends Node
## Item equipment is authoritative; combat flags only present the active item.

var combat: PlayerCombat
var inventory: PlayerInventory
var equipment: CharacterEquipment
var active_slot: int = 1
var replica: bool = false
var _active: ItemStack
var _restoring: bool = false

func _ready() -> void:
	combat.equipment.select_item = select
	equipment.changed.connect(refresh)
	refresh()

func seed() -> void:
	equipment.set_slot("combat_1", ItemStack.new(InventoryItem.weapon("knife"), 1))
	equipment.set_slot("combat_2", ItemStack.new(InventoryItem.weapon("soy_gun"), 1))

func select(slot: int) -> void:
	if slot not in [1, 2] or combat.active or slot == active_slot: return
	persist_reserve()
	active_slot = slot
	refresh()

func persist_reserve() -> void:
	if not replica and _active != null and _active.item.id == "sotjet": _active.reserve = combat.sotjet.milk

func refresh() -> void:
	if _restoring or replica: return
	persist_reserve()
	_active = equipment.get_slot("combat_%d" % active_slot)
	combat.reset()
	var id := _active.item.id if _active != null else ""
	combat.equipment.knife_owned = has_equipped("knife")
	combat.equipment.gun_owned = has_equipped("soy_gun")
	combat.equipment.sotjet_owned = has_equipped("sotjet")
	combat.equipment.knife_selected = id == "knife"
	combat.gun.selected = id == "soy_gun"
	combat.sotjet.selected = id == "sotjet"
	combat.sword.visible = id == "knife"
	if id == "sotjet": combat.sotjet.milk = _active.reserve

func has_equipped(id: String) -> bool:
	for slot in ["combat_1", "combat_2"]:
		var stack := equipment.get_slot(slot)
		if stack != null and stack.item.id == id: return true
	return false

func receive(stack: ItemStack) -> bool:
	for slot in ["combat_1", "combat_2"]:
		if equipment.get_slot(slot) == null:
			equipment.set_slot(slot, stack)
			select(int(slot.right(1)))
			return true
	for i in PlayerInventory.CAPACITY:
		if inventory.get_slot(i) == null:
			inventory.set_slot(i, stack)
			return true
	return false

func restore(data: Dictionary, selected: int, legacy: Dictionary = {}) -> void:
	_restoring = true
	_active = null
	equipment.restore(data)
	active_slot = clampi(selected, 1, 2)
	if not data.has("combat_1"):
		var ids: Array[String] = []
		if legacy.get("owned", true): ids.append("knife")
		if legacy.get("gun_owned", true): ids.append("soy_gun")
		if legacy.get("sotjet_owned", true): ids.append("sotjet")
		var current := "sotjet" if legacy.get("jet", false) else ("soy_gun" if legacy.get("gun", false) else "knife")
		if current in ids: ids.erase(current); ids.push_front(current)
		for id in ids:
			var stack := ItemStack.new(InventoryItem.weapon(id), 1)
			if id == "sotjet": stack.reserve = legacy.get("milk", 100.0)
			if not receive(stack): inventory.pending_items.append(stack)
		active_slot = 1
	_restoring = false
	refresh()

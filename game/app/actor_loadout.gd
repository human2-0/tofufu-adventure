class_name ActorLoadout
extends Node
## Item equipment is authoritative; combat flags only present the active item.

var combat: PlayerCombat
var inventory: PlayerInventory
var equipment: CharacterEquipment
var hud: HUD
var active_slot: int = 1
var replica: bool = false
var _active: ItemStack
var _restoring: bool = false

func _ready() -> void:
	combat.equipment.select_item = select
	equipment.changed.connect(refresh)
	refresh()

func seed() -> void:
	if equipment.get_slot("backpack") == null:
		equipment.set_slot("backpack", ItemStack.new(InventoryItem.backpack("factory_backpack"), 1))
	if equipment.get_slot("combat_1") == null:
		equipment.set_slot("combat_1", ItemStack.new(InventoryItem.weapon("knife"), 1))
	if equipment.get_slot("combat_2") == null:
		equipment.set_slot("combat_2", ItemStack.new(InventoryItem.weapon("soy_gun"), 1))

func select(slot: int) -> void:
	if slot not in [1, 2] or combat.active or slot == active_slot: return
	persist_reserve()
	active_slot = slot
	refresh()

func persist_reserve() -> void:
	if not replica and _active != null and _active.item.id == "sotjet": _active.reserve = combat.sotjet.milk

func refresh(show_feedback: bool = true) -> void:
	if _restoring: return
	var actor := combat.actor as Player if combat != null else null
	var full_set := equipment.complete_set()
	if actor != null:
		var completed := not full_set.is_empty() and actor.visuals.worn_set != full_set
		actor.visuals.set_worn_set(full_set, show_feedback)
		if completed and show_feedback and hud != null:
			var accent := Color("a6ec72") if full_set == ApparelSetBonus.SOYPOD else Color("8bd6c2")
			OutfitCelebration.spawn(hud, ApparelSetBonus.name_for(full_set), ApparelSetBonus.celebration_text(full_set), accent)
	if combat != null and combat.owner_health != null:
		combat.owner_health.armor_multiplier = equipment.damage_multiplier()
	var backpack := equipment.get_slot("backpack")
	inventory.set_capacity(backpack.item.storage_slots if backpack != null and backpack.item != null else 0)
	if replica: return
	persist_reserve()
	_active = equipment.get_slot("combat_%d" % active_slot)
	combat.reset()
	var id := _active.item.id if _active != null else ""
	combat.equipment.knife_owned = has_equipped("knife")
	combat.equipment.gun_owned = has_equipped("soy_gun")
	combat.equipment.sotjet_owned = has_equipped("sotjet")
	combat.equipment.staff_owned = has_equipped("sproutwood_staff")
	combat.equipment.knife_selected = id == "knife"
	combat.equipment.staff_selected = id == "sproutwood_staff"
	combat.gun.selected = id == "soy_gun"
	combat.sotjet.selected = id == "sotjet"
	combat.sword.visible = id == "knife"
	combat.staff.visible = id == "sproutwood_staff"
	if id == "sotjet": combat.sotjet.milk = _active.reserve

func stow_ineligible_apparel() -> void:
	for slot_name in CharacterEquipment.APPAREL_SLOTS:
		var stack := equipment.get_slot(slot_name)
		if stack == null or equipment.can_equip(slot_name, stack): continue
		if not inventory.has_space_for(stack.item, stack.count) and inventory.pending_items.size() >= 32: continue
		equipment.set_slot(slot_name, null)
		if inventory.add_item(stack.item, stack.count) > 0: inventory.pending_items.append(stack)

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
	for i in inventory.capacity:
		if inventory.get_slot(i) == null:
			inventory.set_slot(i, stack)
			return true
	return false

func restore(data: Dictionary, selected: int, legacy: Dictionary = {}) -> void:
	_restoring = true
	_active = null
	equipment.restore(data)
	if not data.has("backpack"):
		equipment.set_slot("backpack", ItemStack.new(InventoryItem.backpack("factory_backpack"), 1))
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
	refresh(false)

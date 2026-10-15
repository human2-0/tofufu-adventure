extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	var inventory := PlayerInventory.new()
	var equipment := CharacterEquipment.new()
	equipment.set_slot("backpack", ItemStack.new(InventoryItem.backpack("factory_backpack"), 1))
	inventory.set_capacity(equipment.get_slot("backpack").item.storage_slots)
	check(inventory.capacity == PlayerInventory.CAPACITY, "factory backpack keeps the original ten slots")
	inventory.set_slot(0, ItemStack.new(InventoryItem.backpack("traveler_backpack"), 1))
	check(InventoryTransfer.apply(inventory, equipment, "inventory", 0, "equipment", "backpack"), "traveler backpack equips from the bag")
	check(inventory.capacity == PlayerInventory.MAX_CAPACITY, "traveler backpack expands to twenty slots")
	inventory.set_slot(15, ItemStack.new(InventoryItem.currency("mature_bean"), 1))
	check(not InventoryTransfer.apply(inventory, equipment, "inventory", 0, "equipment", "backpack"), "cannot shrink a backpack while overflow slots hold items")
	inventory.set_slot(15, null)
	check(InventoryTransfer.apply(inventory, equipment, "inventory", 0, "equipment", "backpack"), "factory backpack can be restored after clearing overflow")
	check(inventory.capacity == PlayerInventory.CAPACITY, "factory backpack returns capacity to ten slots")
	var contents := inventory.capture()
	contents[1] = ItemStack.new(InventoryItem.currency("mature_bean"), 3).capture()
	var dropped_bag := [[1, "factory_backpack", 1, 100.0, 0.0, 0.0, 0.0, contents]]
	check(WorldProtocol.world_items(dropped_bag), "backpack contents use the bounded world-drop schema")
	var save := {"version": 1, "name": "Bag", "saved_at": "now", "opening_complete": true,
		"position": [0.0, 0.0, 0.0], "dropped_position": [0.0, 0.0, 0.0], "health": 100.0,
		"phase": 0.0, "seconds": 0.0, "beans": 0, "mobs": 0, "props": 0, "experience": 0,
		"discoveries": [], "knife_owned": true, "knife_selected": true, "world_items": dropped_bag}
	check(SaveStore.valid(save), "backpack contents persist in a valid adventure record")
	var empty_bag := PlayerInventory.new()
	var bare_equipment := CharacterEquipment.new()
	empty_bag.set_capacity(0)
	check("Equipped immediately" in WeaponTrade.purchase(empty_bag, "traveler_backpack", bare_equipment), "replacement backpack purchase bypasses zero bag capacity")
	check(bare_equipment.get_slot("backpack").item.id == "traveler_backpack" and empty_bag.capacity == 20, "replacement backpack restores usable storage immediately")
	bare_equipment.wearer_level = 5
	for slot_name in CharacterEquipment.APPAREL_SLOTS:
		for index in empty_bag.capacity: empty_bag.set_slot(index, ItemStack.new(InventoryItem.create_edamame(), 100))
		var id := "bright_leaf_%s" % slot_name
		check("Equipped immediately" in WeaponTrade.purchase(empty_bag, id, bare_equipment), "empty %s equips even with a full bag" % slot_name)
		check(bare_equipment.get_slot(slot_name).item.id == id, "purchase fills the matching apparel slot")
	check("bag is full" in WeaponTrade.purchase(empty_bag, "dark_leaf_armor", bare_equipment), "occupied equipment and full bag reject purchase")
	check(bare_equipment.get_slot("armor").item.id == "bright_leaf_armor", "purchase never replaces worn armor")
	empty_bag.set_slot(0, null)
	WeaponTrade.purchase(empty_bag, "traveler_backpack", bare_equipment)
	check(empty_bag.get_slot(0).item.id == "traveler_backpack", "second backpack goes to storage when one is worn")
	bare_equipment.set_slot("armor", null)
	bare_equipment.wearer_level = 1
	empty_bag.set_slot(0, null)
	WeaponTrade.purchase(empty_bag, "bright_leaf_armor", bare_equipment)
	check(bare_equipment.get_slot("armor") == null and empty_bag.get_slot(0).item.id == "bright_leaf_armor", "auto equip preserves armor level requirements")
	print("Backpack: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

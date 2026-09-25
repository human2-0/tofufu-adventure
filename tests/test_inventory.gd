extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	_test_inventory_stacking()
	_test_inventory_capacity()
	_test_equipment_slots()
	_test_drag_drop_transfer()
	_test_malformed_restore()
	print("Inventory & Equipment tests: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _test_inventory_stacking() -> void:
	var inv := PlayerInventory.new()
	var bean := InventoryItem.create_edamame()
	check(inv.slots.size() == 10, "inventory initializes with 10 slots")
	check(inv.count_item("edamame") == 0, "empty inventory has 0 count")
	
	# Add 60 beans
	var rem := inv.add_item(bean, 60)
	check(rem == 0, "added 60 beans with 0 remaining")
	check(inv.count_item("edamame") == 60, "inventory count is 60")
	check(inv.get_slot(0).count == 60, "first slot has 60 beans")
	check(inv.get_slot(1) == null, "second slot is still empty")

	# A full 100-bean stack rolls into the next backpack tile.
	rem = inv.add_item(bean, 50)
	check(rem == 0, "added 50 beans with 0 remaining")
	check(inv.count_item("edamame") == 110, "total count is 110")
	check(inv.get_slot(0).count == 100, "slot 0 is full at 100 beans")
	check(inv.get_slot(1).count == 10, "slot 1 has remaining 10 beans")

func _test_inventory_capacity() -> void:
	var inv := PlayerInventory.new()
	var bean := InventoryItem.create_edamame()
	
	# Fill all ten backpack slots with 100 beans each.
	for i in 10:
		inv.set_slot(i, ItemStack.new(bean, 100))
	check(inv.count_item("edamame") == 1000, "inventory has 1000 edamame across 10 slots")
	check(not inv.has_space_for(bean, 1), "no space for more beans when full")
	var rem := inv.add_item(bean, 5)
	check(rem == 5, "adding beans to full inventory leaves 5 remaining")

func _test_equipment_slots() -> void:
	var eq := CharacterEquipment.new()
	var bean := InventoryItem.create_edamame()
	var bean_stack := ItemStack.new(bean, 20)

	var helmet_item := InventoryItem.new()
	helmet_item.id = "straw_hat"
	helmet_item.category = "helmet"
	var helmet_stack := ItemStack.new(helmet_item, 1)

	# Type restrictions
	check(not eq.can_equip("helmet", bean_stack), "cannot put currency into helmet slot")
	check(not eq.can_equip("armor", bean_stack), "cannot put currency into armor slot")
	check(not eq.can_equip("support_1", bean_stack), "currency cannot occupy a support slot")
	check(not eq.can_equip("support_2", bean_stack), "currency cannot occupy a support slot")
	check(eq.can_equip("helmet", helmet_stack), "can put helmet into helmet slot")

	# Equip
	eq.set_slot("helmet", helmet_stack)
	check(eq.get_slot("helmet").item.id == "straw_hat", "helmet equipped")
	var leaf_helmet := ItemStack.new(InventoryItem.apparel("bright_leaf_helmet"), 1)
	check(leaf_helmet.item.required_level == 5 and is_equal_approx(leaf_helmet.item.damage_reduction, 0.01), "leaf armor defines its level gate and one-percent protection")
	check(not eq.can_equip("helmet", leaf_helmet), "leaf armor cannot be equipped below level five")
	eq.wearer_level = 5
	check(eq.can_equip("helmet", leaf_helmet), "leaf armor can be equipped at level five")
	eq.set_slot("helmet", leaf_helmet)
	check(is_equal_approx(eq.damage_multiplier(), 0.99), "one equipped piece reduces damage by one percent")
	for slot_name in ["armor", "legs", "boots"]:
		eq.set_slot(slot_name, ItemStack.new(InventoryItem.apparel("bright_leaf_%s" % slot_name), 1))
	check(eq.complete_set() == "bright_leaf" and is_equal_approx(eq.damage_multiplier(), 0.90), "four matching pieces give ten percent total protection")
	eq.set_slot("helmet", ItemStack.new(InventoryItem.apparel("dark_leaf_helmet"), 1))
	check(eq.complete_set().is_empty() and is_equal_approx(eq.damage_multiplier(), 0.96), "mixed pieces retain their individual protection without the set bonus")
	for slot_name in ["armor", "legs", "boots"]:
		eq.set_slot(slot_name, ItemStack.new(InventoryItem.apparel("dark_leaf_%s" % slot_name), 1))
	check(eq.complete_set() == "dark_leaf" and is_equal_approx(eq.damage_multiplier(), 0.90), "Dark Leaf receives the same complete-set protection")
	eq.wearer_level = 4
	check(eq.complete_set().is_empty() and is_equal_approx(eq.damage_multiplier(), 1.0), "outleveled armor grants no look or protection")

func _test_drag_drop_transfer() -> void:
	var window := InventoryWindow.new()
	var inv := PlayerInventory.new()
	var eq := CharacterEquipment.new()
	window.inventory = inv
	window.equipment = eq

	var bean := InventoryItem.create_edamame()
	inv.set_slot(0, ItemStack.new(bean, 15))

	window.execute_transfer("inventory", 0, "inventory", 3)
	check(inv.get_slot(0) == null and inv.get_slot(3).count == 15, "currency moves between bag slots")
	window.execute_transfer("inventory", 3, "equipment", "support_1")
	check(inv.get_slot(3).count == 15, "currency transfer to support is rejected")
	window.execute_transfer("inventory", 3, "inventory", -1)
	check(inv.get_slot(3).count == 15, "invalid destinations preserve currency")
	window.free()

func _test_malformed_restore() -> void:
	var inv := PlayerInventory.new()
	inv.restore([null, 12, {"id": "edamame", "count": -1}, {"id": "edamame", "count": 1000}, {"id": "minted_currency", "count": 2}])
	check(inv.count_item("edamame") == 0, "malformed and unknown saved stacks are discarded safely")
	check(not InventoryTransfer.valid_slot("inventory", 0.5), "fractional slot IDs are rejected")
	check(not InventoryTransfer.valid_slot([], 0), "malformed slot sources are rejected")

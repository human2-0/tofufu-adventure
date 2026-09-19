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
	_test_gradual_healing()
	_test_drag_drop_transfer()
	print("Inventory & Equipment tests: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _test_inventory_stacking() -> void:
	var inv := PlayerInventory.new()
	var bean := InventoryItem.create_soybean()
	check(inv.slots.size() == 10, "inventory initializes with 10 slots")
	check(inv.count_item("soybean") == 0, "empty inventory has 0 count")
	
	# Add 60 beans
	var rem := inv.add_item(bean, 60)
	check(rem == 0, "added 60 beans with 0 remaining")
	check(inv.count_item("soybean") == 60, "inventory count is 60")
	check(inv.get_slot(0).count == 60, "first slot has 60 beans")
	check(inv.get_slot(1) == null, "second slot is still empty")

	# Add 50 more beans -> 100 in slot 0, 10 in slot 1
	rem = inv.add_item(bean, 50)
	check(rem == 0, "added 50 beans with 0 remaining")
	check(inv.count_item("soybean") == 110, "total count is 110")
	check(inv.get_slot(0).count == 100, "slot 0 is full at 100 beans")
	check(inv.get_slot(1).count == 10, "slot 1 has remaining 10 beans")

func _test_inventory_capacity() -> void:
	var inv := PlayerInventory.new()
	var bean := InventoryItem.create_soybean()
	
	# Fill all 10 slots with 100 beans each (1000 beans total)
	for i in 10:
		inv.set_slot(i, ItemStack.new(bean, 100))
	check(inv.count_item("soybean") == 1000, "inventory has 1000 beans across 10 slots")
	check(not inv.has_space_for(bean, 1), "no space for more beans when full")
	var rem := inv.add_item(bean, 5)
	check(rem == 5, "adding beans to full inventory leaves 5 remaining")

func _test_equipment_slots() -> void:
	var eq := CharacterEquipment.new()
	var bean := InventoryItem.create_soybean()
	var bean_stack := ItemStack.new(bean, 20)

	var helmet_item := InventoryItem.new()
	helmet_item.id = "straw_hat"
	helmet_item.category = "helmet"
	var helmet_stack := ItemStack.new(helmet_item, 1)

	# Type restrictions
	check(not eq.can_equip("helmet", bean_stack), "cannot put soybean into helmet slot")
	check(not eq.can_equip("armor", bean_stack), "cannot put soybean into armor slot")
	check(eq.can_equip("healing_1", bean_stack), "can put soybean into healing_1 slot")
	check(eq.can_equip("healing_2", bean_stack), "can put soybean into healing_2 slot")
	check(eq.can_equip("helmet", helmet_stack), "can put helmet into helmet slot")

	# Equip
	eq.set_slot("healing_1", bean_stack)
	check(eq.get_slot("healing_1").count == 20, "healing_1 slot has 20 beans")
	eq.set_slot("helmet", helmet_stack)
	check(eq.get_slot("helmet").item.id == "straw_hat", "helmet equipped")

func _test_gradual_healing() -> void:
	var eq := CharacterEquipment.new()
	var bean := InventoryItem.create_soybean()
	eq.set_slot("healing_1", ItemStack.new(bean, 5))

	var health := Damageable.new()
	health.maximum = 100.0
	health.current = 50.0

	var healing := PlayerHealing.new()
	healing.equipment = eq
	healing.health = health

	check(healing.can_use_slot("healing_1"), "can use healing slot when damaged")
	var used := healing.use_slot("healing_1")
	check(used, "using healing slot consumes item")
	check(eq.get_slot("healing_1").count == 4, "healing slot count reduced to 4")
	check(healing.cooldown_remaining == 2.0, "cooldown set to 2.0s")
	check(not healing.can_use_slot("healing_1"), "cannot use healing slot during cooldown")

	# Step 0.5s -> heals 10.0 HP/s * 0.5s = 5.0 HP
	healing.step(0.5)
	check(absf(health.current - 55.0) < 0.1, "health increased gradually to ~55.0")
	check(absf(healing.cooldown_remaining - 1.5) < 0.05, "cooldown decreased to 1.5s")

	# Step another 2.0s -> cooldown expires (1.5 - 2.0 <= 0), heals 20.0 HP (total +25 -> 75.0)
	healing.step(2.0)
	check(absf(health.current - 75.0) < 0.1, "health reached +25 HP total (75.0)")
	check(healing.cooldown_remaining <= 0.0, "cooldown fully expired after 2.5s")
	check(healing.can_use_slot("healing_1"), "can use healing slot again after cooldown")
	health.free()

func _test_drag_drop_transfer() -> void:
	var window := InventoryWindow.new()
	var inv := PlayerInventory.new()
	var eq := CharacterEquipment.new()
	window.inventory = inv
	window.equipment = eq

	var bean := InventoryItem.create_soybean()
	inv.set_slot(0, ItemStack.new(bean, 15))

	# Transfer inv[0] to eq["healing_1"]
	window.execute_transfer("inventory", 0, "equipment", "healing_1")
	check(inv.get_slot(0) == null, "inventory slot 0 cleared after transfer")
	check(eq.get_slot("healing_1").count == 15, "healing_1 slot has 15 beans")

	# Transfer back to inv[3]
	window.execute_transfer("equipment", "healing_1", "inventory", 3)
	check(eq.get_slot("healing_1") == null, "healing_1 slot cleared after transfer back")
	check(inv.get_slot(3).count == 15, "inventory slot 3 has 15 beans")
	window.free()

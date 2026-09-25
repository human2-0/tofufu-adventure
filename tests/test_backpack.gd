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
	print("Backpack: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

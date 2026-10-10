class_name ShopStock
extends RefCounted
## Rebuild only when the reachable merchant's authored stock changes.

static func fill(window: WeaponShopWindow, ids: Array[String]) -> void:
	for child in window._stock_grid.get_children():
		window._stock_grid.remove_child(child)
		child.queue_free()
	window._first_button = null
	for id in ids:
		var item := InventoryItem.from_id(id)
		if item == null: continue
		var button := ShopItemTile.new()
		button.setup(item, "0 MATURE BEANS", window._tile_size())
		button.pressed.connect(func() -> void: window.purchase_requested.emit(item.id))
		window._watch_description(button)
		window._stock_grid.add_child(button)
		if window._first_button == null: window._first_button = button

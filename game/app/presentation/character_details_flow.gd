class_name CharacterDetailsFlow
extends Node
## Character tab shares the inventory's existing modal and co-op allocation path.

var controls: InventoryControls
var game: AdventureGame
var sheet := CharacterSheet.new()
var _refresh_time: float = 0.0

func _ready() -> void:
	game.inventory_window.add_child(sheet)
	sheet.bag_requested.connect(_show_bag)
	sheet.close_requested.connect(game.inventory_window.close)
	sheet.stat_point_allocated.connect(game.hud.stat_point_allocated.emit)
	game.inventory_window.opened.connect(_show_bag)
	controls.page_requested.connect(_page_requested)
	game.inventory_window.closed.connect(_closed)
	game.inventory_window.character_requested.connect(_show_character)

func _process(delta: float) -> void:
	if not game.inventory_window.visible or not sheet.visible: return
	_refresh_time -= delta
	if _refresh_time <= 0:
		_refresh_time = 0.2
		sheet.present(CharacterDetailsData.build(game))

func _page_requested(character: bool) -> void:
	if character: _show_character()
	else: _show_bag()

func _show_character() -> void:
	controls.character_open = true
	game.inventory_window._tooltip.clear()
	game.inventory_window._equipment_dock.hide()
	game.inventory_window._backpack_dock.hide()
	sheet.present(CharacterDetailsData.build(game))
	sheet.show()
	sheet.bag_button.call_deferred("grab_focus")

func _show_bag() -> void:
	controls.character_open = false
	sheet.hide()
	game.inventory_window._equipment_dock.show()
	game.inventory_window._backpack_dock.show()
	if not game.inventory_window._inv_buttons.is_empty(): game.inventory_window._inv_buttons[0].grab_focus()

func _closed() -> void:
	_show_bag()

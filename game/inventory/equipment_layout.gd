class_name EquipmentLayout
extends Control
## Anatomical placement; the window supplies the interactive slot buttons.

const POSITIONS := {
	"helmet": Vector2(96, 0), "armor": Vector2(96, 80),
	"legs": Vector2(96, 160), "boots": Vector2(96, 240),
	"accessory": Vector2(0, 0), "backpack": Vector2(192, 0),
	"combat_1": Vector2(0, 112), "combat_2": Vector2(192, 112),
	"support_1": Vector2(0, 328), "support_2": Vector2(66, 328),
	"support_3": Vector2(132, 328), "support_4": Vector2(198, 328)
}
const ICONS := {
	"helmet": preload("res://game/inventory/icons/helmet.svg"),
	"armor": preload("res://game/inventory/icons/armor.svg"),
	"legs": preload("res://game/inventory/icons/legs.svg"),
	"boots": preload("res://game/inventory/icons/boots.svg"),
	"accessory": preload("res://game/inventory/icons/accessory.svg"),
	"backpack": preload("res://game/inventory/icons/backpack.svg"),
	"combat_1": preload("res://game/inventory/icons/combat.svg"),
	"combat_2": preload("res://game/inventory/icons/combat.svg"),
	"support_1": preload("res://game/inventory/icons/healing.svg"),
	"support_2": preload("res://game/inventory/icons/healing.svg"),
	"support_3": preload("res://game/inventory/icons/healing.svg"),
	"support_4": preload("res://game/inventory/icons/healing.svg")
}

func _ready() -> void:
	custom_minimum_size = Vector2(264, 390)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var line := Color(0.55, 0.7, 0.65, 0.15)
	draw_line(Vector2(132, 36), Vector2(132, 276), line, 2, true)
	draw_line(Vector2(36, 36), Vector2(228, 36), line, 2, true)
	draw_polyline(PackedVector2Array([Vector2(36,148), Vector2(68,148), Vector2(96,116)]), line, 2, true)
	draw_polyline(PackedVector2Array([Vector2(228,148), Vector2(196,148), Vector2(168,116)]), line, 2, true)

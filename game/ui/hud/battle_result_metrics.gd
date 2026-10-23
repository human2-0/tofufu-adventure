class_name BattleResultMetrics
extends Control
## Icon-led stat tiles and completed-goal medallions, supplied as display values.
const ICONS: Array[Texture2D] = [BattleHUDIcons.KO, BattleHUDIcons.ENERGY, BattleHUDIcons.CHEST, BattleHUDIcons.CLOCK, BattleHUDIcons.ALIVE, BattleHUDIcons.SAFE]
var values: Array[String] = []
var captions: Array[String] = []
var goals: int = 0

func _ready() -> void:
	custom_minimum_size.y = 162
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func display(numbers: Array[String], labels: Array[String], completed: int) -> void:
	values = numbers
	captions = labels
	goals = completed
	queue_redraw()

func _draw() -> void:
	var cell := Vector2((size.x - 16) / 3, 65)
	for i in mini(values.size(), 6):
		var at := Vector2((i % 3) * (cell.x + 8), (i / 3) * (cell.y + 6))
		BattleHUDIcons.panel(self, Rect2(at, cell))
		BattleHUDIcons.icon(self, ICONS[i], at + Vector2(10, 10), 21, MenuStyle.SOY_GOLD)
		BattleHUDIcons.number(self, at + Vector2(39, 29), values[i], 24)
		BattleHUDIcons.number(self, at + Vector2(10, 52), captions[i], 13, MenuStyle.MUTED)
	for i in 3:
		var at := Vector2(size.x * 0.5 - 30 + i * 30, 151)
		draw_circle(at, 8, MenuStyle.SOY_GOLD if i < goals else Color("31534b"))
		if i < goals:
			draw_line(at + Vector2(-4, 0), at + Vector2(-1, 3), MenuStyle.INK, 2, true)
			draw_line(at + Vector2(-1, 3), at + Vector2(4, -3), MenuStyle.INK, 2, true)

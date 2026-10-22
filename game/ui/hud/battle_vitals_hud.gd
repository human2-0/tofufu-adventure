class_name BattleVitalsHUD
extends Control
## Readable resource bars with distinct symbols; no text paragraphs during play.
var hp: float = 100
var armour: float = 50
var stamina: float = 100
var partner_hp: float = -1
var partner_name: String = ""
var armour_icons: Array = []
var integrity: Array = []
var complete_set: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func display(data: Dictionary) -> void:
	hp = data.hp
	armour = data.armour
	stamina = data.get("sp", 100)
	partner_hp = data.get("partner_hp", -1)
	partner_name = data.get("partner_name", "")
	armour_icons = data.get("armour_icons", [])
	integrity = data.get("integrity", [])
	complete_set = data.get("complete_set", false)
	queue_redraw()

func _draw() -> void:
	BattleHUDIcons.panel(self, Rect2(Vector2.ZERO, size))
	var compact := size.x < 180
	var row_height := 18.0 if compact else 22.0
	for i in 3:
		var value: float = [hp, armour, stamina][i]
		var maximum := 50.0 if i == 1 else 100.0
		var y := 7 + i * row_height
		BattleHUDIcons.icon(self, [BattleHUDIcons.HEART, BattleHUDIcons.ARMOR, BattleHUDIcons.ENERGY][i], Vector2(7, y), 15 if compact else 18)
		var rect := Rect2(30, y + 4, size.x - 70, 8 if compact else 10)
		BattleHUDIcons.bar(self, rect, Color("081f1c"))
		var fill := rect
		fill.size.x *= clampf(value / maximum, 0, 1)
		if fill.size.x > 0: BattleHUDIcons.bar(self, fill, [Color("83e5aa"), Color("79c9ed"), Color("f4ca67")][i])
		BattleHUDIcons.number(self, Vector2(size.x - 34, y + 13), str(ceili(value)), 12 if compact else 14)
	_worn()
	if partner_hp >= 0:
		var at := Vector2(0, -60)
		BattleHUDIcons.panel(self, Rect2(at, Vector2(size.x, 21)))
		BattleHUDIcons.icon(self, BattleHUDIcons.ALIVE, at + Vector2(5, 2), 16, Color("78e5ef"))
		BattleHUDIcons.number(self, at + Vector2(25, 15), partner_name.left(13), 11)
		draw_rect(Rect2(size.x - 40, -52, 32 * clampf(partner_hp / 100, 0, 1), 5), Color("78e5ef"))

func _worn() -> void:
	for i in mini(4, armour_icons.size()):
		if armour_icons[i] == null: continue
		var at := Vector2(i * 35, -35)
		BattleHUDIcons.panel(self, Rect2(at, Vector2(31, 30)))
		draw_texture_rect(armour_icons[i], Rect2(at + Vector2(4, 2), Vector2(23, 23)), false)
		var ratio: float = 1.0 if complete_set else integrity[i]
		var color := Color("8eebc2") if complete_set or ratio > 0.5 else Color("ff897f")
		draw_rect(Rect2(at + Vector2(3, 25), Vector2(25 * ratio, 3)), color)
		if complete_set: BattleHUDIcons.icon(self, BattleHUDIcons.SAFE, at + Vector2(20, 0), 11)

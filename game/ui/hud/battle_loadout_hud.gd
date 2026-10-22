class_name BattleLoadoutHUD
extends Control
## Real item art, selected rarity edge, magazine pips and finite support stacks.
var values: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func display(data: Dictionary) -> void:
	values = data
	queue_redraw()

func _draw() -> void:
	if values.is_empty(): return
	BattleHUDIcons.panel(self, Rect2(Vector2.ZERO, size))
	var cell := 42.0 if size.x < 300 else 52.0
	var y := (size.y - cell) * 0.5
	var textures: Array = values.get("weapon_icons", [])
	var colors: Array = values.get("weapon_colors", [])
	for i in mini(2, textures.size()):
		var rect := Rect2(6 + i * (cell + 5), y, cell, cell)
		var selected: bool = values.get("reserve", 1) == i + 1
		draw_rect(rect, Color("28564c") if selected else Color("102d28"))
		var color: Color = colors[i] if i < colors.size() else Color.WHITE
		draw_rect(rect, color if selected else Color(color, 0.4), false, 2 if selected else 1)
		if textures[i] != null: _item(textures[i], rect.grow(-5), Color.WHITE if selected else Color(0.65, 0.75, 0.7))
		BattleHUDIcons.number(self, rect.position + Vector2(3, 12), str(i + 1), 11)
	var ammo_x := 2 * (cell + 5) + 12
	var reloading: bool = values.get("reload", 0.0) > 0
	var ammo: int = int(values.get("ammo", 0))
	var ranged: bool = values.get("ranged", true)
	var label := str(ammo) if ranged else "—"
	if values.get("tank", -1) >= 0: label = str(int(values.tank)) + "%"
	BattleHUDIcons.number(self, Vector2(ammo_x, y + 27), label, 23, Color("f4ca67") if reloading else BattleHUDIcons.WHITE)
	if ranged and values.get("tank", -1) < 0:
		for i in mini(12, int(values.get("magazine_capacity", 9))): draw_rect(Rect2(ammo_x + i * 4, y + 34, 3, 6), Color("f4ca67") if i < ammo else Color("466159"))
	if reloading:
		draw_arc(Vector2(ammo_x + 18, y + 23), 19, -PI / 2, -PI / 2 + TAU * values.get("reload_progress", 0.0), 32, Color("f4ca67"), 2, true)
	elif values.get("special_remaining", 0.0) > 0:
		BattleHUDIcons.number(self, Vector2(ammo_x, y + 50), "%.1f" % values.special_remaining, 11, Color("f4ca67"))
	var food: Array = values.get("support_icons", [])
	var counts: Array = values.get("support_counts", [])
	var food_size := 26.0 if size.x < 300 else 32.0
	var start := size.x - food_size * 2 - 13
	for i in mini(4, food.size()):
		var at := Vector2(start + (i % 2) * (food_size + 3), 4 + floori(i / 2.0) * (food_size + 2))
		draw_rect(Rect2(at, Vector2.ONE * food_size), Color("081f1c99"))
		if food[i] != null: _item(food[i], Rect2(at + Vector2.ONE * 3, Vector2.ONE * (food_size - 6)))
		BattleHUDIcons.number(self, at + Vector2(1, 10), str(i + 3), 9)
		if i < counts.size() and counts[i] > 0: BattleHUDIcons.number(self, at + Vector2(food_size - 10, food_size - 1), str(counts[i]), 10)

func _item(texture: Texture2D, rect: Rect2, tint: Color = Color.WHITE) -> void:
	var extent := texture.get_size()
	var scale_factor := minf(rect.size.x / extent.x, rect.size.y / extent.y)
	var shown := extent * scale_factor
	draw_texture_rect(texture, Rect2(rect.get_center() - shown * 0.5, shown), false, tint)

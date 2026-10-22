class_name BattleZoneHUD
extends Control
## One glance: safe/closing/danger, phase countdown and camera-relative escape arrow.
var values: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func display(data: Dictionary) -> void:
	values = data
	queue_redraw()

func _draw() -> void:
	if values.is_empty(): return
	BattleHUDIcons.panel(self, Rect2(Vector2.ZERO, size))
	var unsafe: bool = values.get("unsafe", false)
	var closing: bool = values.get("closing", false)
	var color := Color("ff897f") if unsafe else (Color("d3b1ff") if closing else Color("8eebc2"))
	BattleHUDIcons.icon(self, BattleHUDIcons.STORM if closing or unsafe else BattleHUDIcons.SAFE, Vector2(8, 8), 26)
	var title := tr("STORM") if unsafe else (tr("CLOSING") if closing else tr("SAFE ZONE"))
	var font_size := 12 if ThemeDB.fallback_font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x <= size.x - 105 else 9
	BattleHUDIcons.number(self, Vector2(42, 19), title, font_size, color)
	var seconds := maxi(0, int(values.get("phase_seconds", 0)))
	BattleHUDIcons.number(self, Vector2(42, 36), "%d:%02d" % [seconds / 60, seconds % 60], 17)
	var distance := int(values.get("zone_distance", 0))
	var at := Vector2(size.x - 43, 22)
	if distance > 0:
		var heading: float = values.get("zone_heading", 0.0)
		var direction := Vector2(sin(heading), -cos(heading))
		var side := direction.orthogonal()
		draw_colored_polygon(PackedVector2Array([at + direction * 12, at - direction * 6 + side * 6, at - direction * 3, at - direction * 6 - side * 6]), color)
		BattleHUDIcons.number(self, Vector2(size.x - 65, 43), "%dm" % distance, 12, color)
	else:
		BattleHUDIcons.icon(self, BattleHUDIcons.SAFE, at - Vector2.ONE * 11, 22)
	var stage: int = int(values.get("stage", 1))
	for i in 7: draw_rect(Rect2(8 + i * (size.x - 16) / 7, size.y - 6, (size.x - 30) / 7, 3), color if i < stage else Color("3d5750"))

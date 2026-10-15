class_name ArenaScorecard
extends Control
## Drawn fighter portraits and ten score pips; receives display values only.

const ACCENTS: Array[Color] = [Color("81dec9"), Color("ffbf78")]
var names: Array[String] = ["Fufu", "Fufu"]
var scores: Array[int] = [0, 0]
var phase_text: String = "FIRST TO 10"
var winner_index: int = -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(520, 108)

func present(fighter_names: Array[String], points: Array[int], status: String, winner: int) -> void:
	if names == fighter_names and scores == points and phase_text == status and winner_index == winner: return
	names = fighter_names
	scores = points
	phase_text = status
	winner_index = winner
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var background := StyleBoxFlat.new()
	background.bg_color = Color("112c30f5")
	background.set_corner_radius_all(18)
	background.border_color = Color("fff4d9")
	background.set_border_width_all(2)
	draw_style_box(background, Rect2(Vector2.ZERO, size))
	var half := size.x * 0.5
	for index in 2:
		var left: float = 14.0 if index == 0 else half + 34.0
		var color := ACCENTS[index]
		var face := Vector2(left + 21, 31)
		draw_circle(face, 23, color)
		draw_style_box(_face_style(), Rect2(face - Vector2(15, 13), Vector2(30, 26)))
		draw_circle(face + Vector2(-5, -2), 2.2, Color("17383b"))
		draw_circle(face + Vector2(5, -2), 2.2, Color("17383b"))
		draw_arc(face + Vector2(0, 1), 5, 0.2, PI - 0.2, 12, Color("17383b"), 1.5, true)
		draw_string(font, Vector2(left + 53, 22), names[index], HORIZONTAL_ALIGNMENT_LEFT, half - 110, 14, color)
		draw_string(font, Vector2(left + 53, 54), str(scores[index]), HORIZONTAL_ALIGNMENT_LEFT, 58, 34, Color("fff9e9"))
		for pip in 10:
			var at := Vector2(left + 5 + pip * 18, 72)
			draw_circle(at, 5.5, color if pip < scores[index] else Color("3c5356"))
		if winner_index == index:
			draw_string(font, Vector2(left + 94, 47), tr("WINNER"), HORIZONTAL_ALIGNMENT_LEFT, 100, 12, color)
	draw_string(font, Vector2(half - 18, 40), "VS", HORIZONTAL_ALIGNMENT_CENTER, 36, 19, Color("fff0bd"))
	draw_string(font, Vector2(12, 98), tr(phase_text), HORIZONTAL_ALIGNMENT_CENTER, size.x - 24, 13, Color("dcebe5"))

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED: queue_redraw()

func _face_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fff4d9")
	style.set_corner_radius_all(7)
	return style

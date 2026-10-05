class_name DungeonIngredientSilhouette
extends Control
## Formula-only sealed prop outline; never marks a world container as the answer.

func _ready() -> void:
	custom_minimum_size = Vector2(64, 86)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var profile := PackedVector2Array([Vector2(23, 9), Vector2(41, 9), Vector2(41, 28), Vector2(50, 39), Vector2(50, 76), Vector2(14, 76), Vector2(14, 39), Vector2(23, 28)])
	draw_colored_polygon(profile, Color("cbd7b9"))
	profile.append(profile[0])
	draw_polyline(profile, Color("233e37"), 2.0, true)
	draw_rect(Rect2(22, 5, 20, 7), Color("233e37"))
	draw_rect(Rect2(20, 46, 24, 18), Color("fff0cf"))

class_name CharacterStats
extends VBoxContainer
## Compact kawaii progression display with loading bars for each skill.

signal stat_point_allocated(skill_name: String)

var _level := Label.new()
var _level_bar := ProgressBar.new()
var _next := Label.new()
var _stat_points_lbl := Label.new()
var _defence := Label.new()
var _skill_rows: Dictionary = {}

const SKILL_CONFIG: Array = [
	["fist", "Fist", "f6a282"],
	["sword", "Sword", "f0c868"],
	["shooting", "Shooting", "acd78a"],
	["defence", "Defence", "86d2b4"],
	["magic", "Magic", "c3a6ec"],
	["attack_speed", "Atk Speed", "79caec"]
]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 3)
	_setup_level_header()
	_setup_skill_bars()
	_defence.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_defence.add_theme_font_size_override("font_size", 11)
	_defence.add_theme_color_override("font_color", Color("baccc0"))
	add_child(_defence)

func _setup_level_header() -> void:
	_level.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_level.add_theme_font_size_override("font_size", 12)
	_level.add_theme_color_override("font_color", Color("f5dfac"))
	add_child(_level)

	_level_bar.custom_minimum_size = Vector2(0, 5)
	_level_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_level_bar.show_percentage = false
	_level_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("f5dfac")
	fill.set_corner_radius_all(2)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.18, 0.25, 0.28, 0.6)
	bg.set_corner_radius_all(2)
	_level_bar.add_theme_stylebox_override("fill", fill)
	_level_bar.add_theme_stylebox_override("background", bg)
	add_child(_level_bar)

	_next.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_next.add_theme_font_size_override("font_size", 10)
	_next.add_theme_color_override("font_color", Color("baccc0"))
	add_child(_next)

	_stat_points_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stat_points_lbl.add_theme_font_size_override("font_size", 10)
	_stat_points_lbl.add_theme_color_override("font_color", Color("7a948a"))
	_stat_points_lbl.text = "0 Stat Points"
	add_child(_stat_points_lbl)

	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.custom_minimum_size = Vector2(0, 2)
	add_child(spacer)

func _setup_skill_bars() -> void:
	for cfg in SKILL_CONFIG:
		var key: String = cfg[0]
		var label_text: String = cfg[1]
		var color := Color(cfg[2])

		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 4)
		add_child(row)

		var name_lbl := Label.new()
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_lbl.custom_minimum_size = Vector2(56, 0)
		name_lbl.add_theme_font_size_override("font_size", 10)
		name_lbl.add_theme_color_override("font_color", Color("dce5db"))
		name_lbl.text = "%s 1" % label_text
		row.add_child(name_lbl)

		var bar := ProgressBar.new()
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.custom_minimum_size = Vector2(46, 5)
		bar.show_percentage = false
		var fill := StyleBoxFlat.new()
		fill.bg_color = color
		fill.set_corner_radius_all(2)
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color(0.18, 0.25, 0.28, 0.6)
		bg.set_corner_radius_all(2)
		bar.add_theme_stylebox_override("fill", fill)
		bar.add_theme_stylebox_override("background", bg)
		row.add_child(bar)

		var pct_lbl := Label.new()
		pct_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pct_lbl.custom_minimum_size = Vector2(24, 0)
		pct_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		pct_lbl.add_theme_font_size_override("font_size", 9)
		pct_lbl.add_theme_color_override("font_color", Color("b4cac0"))
		pct_lbl.text = "0%"
		row.add_child(pct_lbl)

		var add_btn := Button.new()
		add_btn.text = "+"
		add_btn.mouse_filter = Control.MOUSE_FILTER_STOP
		add_btn.focus_mode = Control.FOCUS_NONE
		add_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		add_btn.custom_minimum_size = Vector2(16, 15)
		add_btn.add_theme_font_size_override("font_size", 10)
		for state in ["normal", "hover", "pressed"]:
			var btn_style := StyleBoxFlat.new()
			btn_style.bg_color = Color("2c463f") if state == "normal" else (Color("426b60") if state == "hover" else Color("5ea28f"))
			btn_style.border_color = Color("8ed8b8") if state == "normal" else Color("c8ffeb")
			btn_style.set_border_width_all(1)
			btn_style.set_corner_radius_all(3)
			add_btn.add_theme_stylebox_override(state, btn_style)
		add_btn.visible = false
		add_btn.pressed.connect(func() -> void: stat_point_allocated.emit(key))
		row.add_child(add_btn)

		_skill_rows[key] = {
			"label": name_lbl,
			"bar": bar,
			"percent": pct_lbl,
			"add_btn": add_btn,
			"name": label_text
		}

func present(data: Dictionary) -> void:
	_level.text = "LV. %d  ·  %d EXP" % [data.level, data.experience]
	_level_bar.value = float(data.get("level_percent", 0))
	_next.text = "Max Level" if data.level == 99 else "%d EXP to next level" % data.remaining

	var stat_points: int = int(data.get("stat_points", 0))
	if stat_points > 0:
		_stat_points_lbl.text = "★ %d STAT POINT%s" % [stat_points, "S" if stat_points > 1 else ""]
		_stat_points_lbl.add_theme_color_override("font_color", Color("ffd666"))
	else:
		_stat_points_lbl.text = "0 Stat Points"
		_stat_points_lbl.add_theme_color_override("font_color", Color("7a948a"))

	for cfg in SKILL_CONFIG:
		var key: String = cfg[0]
		if not data.skills.has(key) or not _skill_rows.has(key):
			continue
		var skill_info: Dictionary = data.skills[key]
		var row: Dictionary = _skill_rows[key]
		var lvl: int = skill_info.level
		var pct: int = skill_info.percent
		row.label.text = "%s %d" % [row.name, lvl]
		row.bar.value = pct
		row.percent.text = "MAX" if lvl >= 99 else "%d%%" % pct
		row.add_btn.visible = stat_points > 0 and lvl < 99

	var fist_dmg: int = int(data.get("fist_damage", 12))
	_defence.text = "Defence %d · Fist: %d DMG" % [data.defence, fist_dmg]

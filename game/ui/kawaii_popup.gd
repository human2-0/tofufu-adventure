class_name KawaiiPopup
extends Control
## Celebratory chibi-kawaii anime toast for character level-up and skill milestones.

var _panel: PanelContainer
var _tag_label: Label
var _title_label: Label
var _sub_label: Label
var _queue: Array[Dictionary] = []
var _showing: bool = false
var _display_time: float = 0.0

const SKILL_NAMES: Dictionary = {
	"fist": "Fist",
	"sword": "Sword",
	"defence": "Defence",
	"magic": "Magic",
	"attack_speed": "Attack Speed"
}

func _init() -> void:
	custom_minimum_size = Vector2(300, 70)
	mouse_filter = MOUSE_FILTER_IGNORE
	modulate.a = 0.0
	visible = false

func _ready() -> void:
	pivot_offset = Vector2(150, 35)
	_panel = PanelContainer.new()
	_panel.mouse_filter = MOUSE_FILTER_IGNORE
	_panel.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.16, 0.22, 0.75)
	style.set_corner_radius_all(16)
	style.set_content_margin_all(10)
	style.border_color = Color("ffe082")
	style.set_border_width_all(2)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.25)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var box := VBoxContainer.new()
	box.mouse_filter = MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 2)
	_panel.add_child(box)

	_tag_label = Label.new()
	_tag_label.mouse_filter = MOUSE_FILTER_IGNORE
	_tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tag_label.add_theme_font_size_override("font_size", 11)
	_tag_label.add_theme_color_override("font_color", Color("ffe58f"))
	box.add_child(_tag_label)

	_title_label = Label.new()
	_title_label.mouse_filter = MOUSE_FILTER_IGNORE
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 16)
	_title_label.add_theme_color_override("font_color", Color("ffffff"))
	box.add_child(_title_label)

	_sub_label = Label.new()
	_sub_label.mouse_filter = MOUSE_FILTER_IGNORE
	_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_label.add_theme_font_size_override("font_size", 11)
	_sub_label.add_theme_color_override("font_color", Color("d0e8dd"))
	box.add_child(_sub_label)

func celebrate_level(level: int) -> void:
	_queue.append({
		"tag": "★ LEVEL UP! ★",
		"title": "Fufu reached Level %d!" % level,
		"sub": "Stronger hits, tougher defence & quicker steps!",
		"border": Color("ffd166"),
		"tag_color": Color("ffe48a")
	})
	_check_queue()

func celebrate_skill(skill: String, level: int) -> void:
	var display_name: String = SKILL_NAMES.get(skill, skill.capitalize())
	var note := "+Power and precision!"
	if skill == "defence": note = "+Extra protection from hits!"
	elif skill == "sword": note = "+Sharper swings & heavier slashes!"
	elif skill == "fist": note = "+Heavy knuckle impact!"
	elif skill == "attack_speed": note = "+Faster blade recovery!"
	elif skill == "magic": note = "+Deepened mystical energy!"
	_queue.append({
		"tag": "✨ SKILL UP! ✨",
		"title": "%s reached Lv. %d!" % [display_name, level],
		"sub": note,
		"border": Color("93e5d0"),
		"tag_color": Color("baf3e4")
	})
	_check_queue()

func _check_queue() -> void:
	if _showing or _queue.is_empty():
		return
	var item: Dictionary = _queue.pop_front()
	_showing = true
	_present(item)

func _present(item: Dictionary) -> void:
	_tag_label.text = item.tag
	_tag_label.add_theme_color_override("font_color", item.tag_color)
	_title_label.text = item.title
	_sub_label.text = item.sub
	var style: StyleBoxFlat = _panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style != null:
		style.border_color = item.border
	visible = true
	scale = Vector2(0.65, 0.65)
	modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	_display_time = 2.4

func _process(delta: float) -> void:
	if not _showing:
		return
	_display_time -= delta
	if _display_time <= 0.0:
		_showing = false
		var tween := create_tween().set_parallel(true)
		tween.tween_property(self, "scale", Vector2(0.85, 0.85), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(self, "modulate:a", 0.0, 0.22)
		tween.chain().tween_callback(func() -> void:
			visible = false
			_check_queue()
		)

class_name QuestWindow
extends CanvasLayer
## Frosted kawaii dialog for Mayor Mame's quest briefing, progress and rewards.

signal quest_accepted
signal reward_claimed
signal closed

var _dialogue_label: Label
var _objective_title: Label
var _progress_label: Label
var _progress_bar: ProgressBar
var _rewards_label: Label
var _action_button: Button

func _ready() -> void:
	layer = 16
	visible = false
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.theme = MenuStyle.make_theme()
	add_child(center)

	var panel := PanelContainer.new()
	center.add_child(panel)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("173632f7")
	style.border_color = Color("9bd58c")
	style.set_border_width_all(3)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(22)
	style.shadow_color = Color("071715aa")
	style.shadow_size = 16
	style.shadow_offset = Vector2(0, 7)
	panel.add_theme_stylebox_override("panel", style)

	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(420, 0)
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)

	var header := HBoxContainer.new()
	column.add_child(header)
	var title := Label.new()
	title.text = "MAYOR MAME · QUESTS"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color("f5dfac"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_btn := MangaButton.new()
	close_btn.text = "✕"
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.pressed.connect(close)
	header.add_child(close_btn)

	_dialogue_label = Label.new()
	_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_label.add_theme_font_size_override("font_size", 12)
	_dialogue_label.add_theme_color_override("font_color", Color("dbe8d9"))
	column.add_child(_dialogue_label)

	var quest_box := PanelContainer.new()
	var box_style := StyleBoxFlat.new()
	box_style.bg_color = Color("245149")
	box_style.border_color = Color("8cd49a")
	box_style.set_border_width_all(2)
	box_style.set_corner_radius_all(12)
	box_style.set_content_margin_all(14)
	quest_box.add_theme_stylebox_override("panel", box_style)
	column.add_child(quest_box)

	var box_col := VBoxContainer.new()
	box_col.add_theme_constant_override("separation", 8)
	quest_box.add_child(box_col)

	_objective_title = Label.new()
	_objective_title.text = "Quest: Cull the Slimes"
	_objective_title.add_theme_font_size_override("font_size", 12)
	_objective_title.add_theme_color_override("font_color", Color("ffd666"))
	box_col.add_child(_objective_title)

	var prog_row := HBoxContainer.new()
	box_col.add_child(prog_row)
	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(0, 8)
	_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_progress_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_progress_bar.show_percentage = false
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color("8cd6ad")
	bar_fill.set_corner_radius_all(3)
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.18, 0.25, 0.28, 0.8)
	bar_bg.set_corner_radius_all(3)
	_progress_bar.add_theme_stylebox_override("fill", bar_fill)
	_progress_bar.add_theme_stylebox_override("background", bar_bg)
	prog_row.add_child(_progress_bar)

	_progress_label = Label.new()
	_progress_label.add_theme_font_size_override("font_size", 11)
	_progress_label.add_theme_color_override("font_color", Color("b4cac0"))
	prog_row.add_child(_progress_label)

	_rewards_label = Label.new()
	_rewards_label.text = "Reward: 100 Edamame"
	_rewards_label.add_theme_font_size_override("font_size", 11)
	_rewards_label.add_theme_color_override("font_color", Color("eacb83"))
	box_col.add_child(_rewards_label)

	_action_button = MangaButton.new()
	_action_button.custom_minimum_size = Vector2(0, 36)
	_action_button.focus_mode = Control.FOCUS_NONE
	_action_button.pressed.connect(_on_action_pressed)
	column.add_child(_action_button)

var _current_status: int = 0

func present(data: Dictionary) -> void:
	_current_status = int(data.get("status", 0))
	var count: int = int(data.get("current_count", 0))
	var target: int = int(data.get("target_count", 50))
	_progress_bar.max_value = target
	_progress_bar.value = count
	_progress_label.text = " %d / %d Slimes" % [count, target]

	match _current_status:
		0: # NOT_STARTED
			_dialogue_label.text = "Greetings, Fufu! The slimes roaming outside our village have grown too bold and are threatening our soybean fields.\n\nCould you help protect Fufufarm by defeating 50 slimes?"
			_action_button.text = "Accept Quest"
			_action_button.disabled = false
		1: # IN_PROGRESS
			_dialogue_label.text = "How goes the slime hunt, Fufu? Stay alert and mind their charges. The village is counting on you!"
			_action_button.text = "In Progress (%d / %d)" % [count, target]
			_action_button.disabled = true
		2: # COMPLETED
			_dialogue_label.text = "Incredible bravery, Fufu! The fields are peaceful once more thanks to your courage.\n\nPlease accept your reward with our deepest gratitude!"
			_action_button.text = "Claim Reward (100 Edamame)"
			_action_button.disabled = false
		3: # REWARDED
			_dialogue_label.text = "Thank you again for protecting Fufufarm, Fufu! The entire village is safe because of your valiant efforts."
			_action_button.text = "✓ Quest Completed"
			_action_button.disabled = true

func _on_action_pressed() -> void:
	if _current_status == 0:
		quest_accepted.emit()
	elif _current_status == 2:
		reward_claimed.emit()

func open() -> void:
	visible = true
	MenuStyle.focus_later(_action_button)

func close() -> void:
	if not visible: return
	visible = false
	closed.emit()

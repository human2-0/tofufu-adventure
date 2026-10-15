class_name GodHuntWindow
extends CanvasLayer

signal action_requested(action: String)
signal closed
var text := Label.new()
var action := Button.new()
var status: int = 0

func _ready() -> void:
	layer = 16
	visible = false
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.theme = MenuStyle.make_theme()
	add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(520, 300)
	column.add_theme_constant_override("separation", 20)
	panel.add_child(column)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(text)
	column.add_child(action)
	action.pressed.connect(func() -> void: action_requested.emit("accept" if status == 0 else "claim"))
	var close_button := Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(close)
	column.add_child(close_button)

func present(value: int, count: int) -> void:
	status = value
	text.text = "GODFUFU · FIRST QUEST\nThe Fallen Groatguard\n\nMy fallen angels have claimed the Groatfields beyond Jadewild's southern path. Their bows fire Tofufu groats. Defeat 200 and return to me.\n\nRecommended: level 20 and the complete celestial set.\n\nTofufu angels: %d / 200\nReward: 50,000 EXP + 10 Golden Tofufu Chunks" % count
	action.text = ["Accept Quest", "Hunt in progress", "Claim 50,000 EXP + 10 Golden Chunks", "Reward claimed"][value]
	action.disabled = value in [1, 3]

func close() -> void:
	if not visible: return
	visible = false
	closed.emit()

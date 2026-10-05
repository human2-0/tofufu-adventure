class_name DungeonRecipeJournal
extends CanvasLayer
## Reopenable factory recipe, discovered clue and cosmetic unlock preview.

signal return_requested
signal opened
signal closed

var hint_text: String = "Inspect the equipment and follow its visible output."
var _hint: Label
var binding_text: String = "inventory"
var _close: Button
var _body: Label
var _preview: Label
var _replay: Button
var _animation: Tween

func _ready() -> void:
	layer = 24
	visible = false
	var shade := ColorRect.new()
	shade.color = Color("071715b8")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.theme = MenuStyle.make_theme()
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(640, 0)
	center.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	MenuStyle.label(column, "FACTORY RECIPE JOURNAL", 22)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(620, 280)
	column.add_child(scroll)
	_body = MenuStyle.paragraph(scroll, "")
	_body.custom_minimum_size.x = 600
	_hint = MenuStyle.paragraph(column, "")
	MenuStyle.button(column, "? Optional hint", func() -> void: _hint.text = hint_text)
	_preview = MenuStyle.paragraph(column, "")
	MenuStyle.button(column, "Return carried sack / bottle at its dock", return_requested.emit)
	_replay = MenuStyle.button(column, "Replay refinery tutorial", play_unlock)
	_close = MenuStyle.button(column, "Close / Skip", close)

func open(text: String, unlocked: bool) -> void:
	if not visible: opened.emit()
	_hint.text = ""
	_preview.text = ""
	_body.text = text
	_replay.visible = unlocked
	visible = true
	MenuStyle.focus_later(_close)

func close() -> void:
	if not visible: return
	visible = false
	closed.emit()
	if _animation != null: _animation.kill()

func toggle(text: String, unlocked: bool) -> void:
	if visible: close()
	else: open(text, unlocked)

func play_unlock() -> void:
	if not visible: opened.emit()
	visible = true
	MenuStyle.focus_later(_close)
	if _animation != null: _animation.kill()
	_preview.modulate.a = 1.0
	_preview.text = "Refinery skill unlocked — bean currency can now be refined.\n100 Edamame → 1 Mature Bean → 1 White Tofu block\nOpen inventory (%s), then right-click currency or confirm its focused slot on controller. Preview only." % binding_text
	_animation = create_tween()
	_animation.tween_property(_preview, "modulate:a", 0.35, 1.0)
	_animation.tween_property(_preview, "modulate:a", 1.0, 1.0)
	_animation.tween_property(_preview, "modulate:a", 0.35, 1.0)
	_animation.tween_property(_preview, "modulate:a", 1.0, 1.0)
	_animation.tween_property(_preview, "modulate:a", 0.35, 1.0)
	_animation.tween_property(_preview, "modulate:a", 1.0, 1.0)
	_animation.tween_property(_preview, "modulate:a", 0.35, 1.0)

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

class_name LoadingView
extends Control
## Honest resource progress; world construction and save restoration are named stages.

signal back_requested
var status: Label
var progress: ProgressBar
var _chapter: Label
var _tip: Label
var _back: Button
var _card: PanelContainer
var _margin: MarginContainer
var _brand: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = MenuStyle.make_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	var backdrop := MenuBackdrop.new()
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	_margin = margin
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	var column := VBoxContainer.new()
	margin.add_child(column)
	var brand := MenuStyle.label(self, "T O F U F U   /   A D V E N T U R E", 14, MenuStyle.MINT)
	_brand = brand
	brand.position = Vector2(28, 28)
	var space := Control.new()
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(space)
	_card = PanelContainer.new()
	column.add_child(_card)
	var body := VBoxContainer.new()
	_card.add_child(body)
	MenuStyle.label(body, "THE WORLD IS CALLING", 13, MenuStyle.SOY_GOLD)
	_chapter = MenuStyle.paragraph(body, "")
	_chapter.add_theme_font_size_override("font_size", 28)
	status = MenuStyle.paragraph(body, "Preparing your adventure…")
	progress = ProgressBar.new()
	progress.custom_minimum_size.y = 12
	progress.show_percentage = false
	body.add_child(progress)
	_tip = MenuStyle.paragraph(body, "TIP   /   Explore at your own pace. Your progress autosaves every minute.")
	_back = MenuStyle.button(body, "Back to title", back_requested.emit)
	_back.hide()
	resized.connect(_responsive)
	_responsive()
	hide()

func begin(adventure: String, online: bool) -> void:
	_chapter.text = adventure
	_tip.text = "TIP   /   The host saves your shared world. Stay together and explore." if online else "TIP   /   Explore at your own pace. Your progress autosaves every minute."
	progress.value = 0
	progress.show()
	_back.text = "Cancel & return to title"
	_back.show()
	show()
	stage("Gathering the world…", 0)
	_responsive()

func stage(message: String, amount: float) -> void:
	status.text = message
	progress.value = clampf(amount, 0, 100)

func fail(message: String) -> void:
	status.text = message
	_back.text = "Back to title"
	progress.hide()
	_back.show()
	MenuStyle.focus_later(_back)

func _responsive() -> void:
	var compact := size.y < 460
	_brand.visible = not compact
	_chapter.add_theme_font_size_override("font_size", 22 if compact else 28)
	_tip.add_theme_font_size_override("font_size", 12 if compact else 16)
	for side in ["left", "right", "top", "bottom"]:
		_margin.add_theme_constant_override("margin_" + side, 16 if compact else 28)

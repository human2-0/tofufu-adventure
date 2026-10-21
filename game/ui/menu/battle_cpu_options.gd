class_name BattleCPUOptions
extends VBoxContainer
## Display values and user intents only; app supplies the effective seat count.

signal selected(count: int, difficulty: int)
signal mode_selected(duos: bool)
var mode: OptionButton
var count: SpinBox
var difficulty: OptionButton
var summary: Label
var ownership: Label
var _summary_values := Vector2i.ZERO

func _ready() -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	add_child(grid)
	MenuStyle.label(grid, "Team mode", 16)
	mode = OptionButton.new()
	mode.add_item("Solo")
	mode.add_item("Duos")
	grid.add_child(mode)
	mode.item_selected.connect(func(index: int) -> void: mode_selected.emit(index == 1))
	MenuStyle.label(grid, "CPU opponents", 16)
	count = SpinBox.new()
	count.min_value = 0
	count.max_value = 50
	count.step = 1
	count.value = 7
	count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(count)
	MenuStyle.label(grid, "CPU difficulty", 16)
	difficulty = OptionButton.new()
	for title in ["Easy", "Normal", "Hard"]: difficulty.add_item(title)
	difficulty.select(1)
	difficulty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(difficulty)
	count.value_changed.connect(func(value: float) -> void: selected.emit(int(value), difficulty.selected))
	difficulty.item_selected.connect(func(index: int) -> void: selected.emit(int(count.value), index))
	summary = MenuStyle.paragraph(self, "")
	summary.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	ownership = MenuStyle.paragraph(self, "The host chooses CPU settings.")
	MenuStyle.paragraph(self, "Duos pair players in lobby order. CPUs complete pairs; the CPU total adjusts to keep teams even. At least two teams are needed.")
	MenuStyle.paragraph(self, "Up to 50 CPUs and 20 players. Fewer CPUs reduce simulation work. Difficulty changes reactions and aim; health and damage stay equal.")

func display(requested: int, skill: int, effective: int, total: int, editable: bool, duos: bool = false) -> void:
	mode.select(1 if duos else 0)
	mode.disabled = not editable
	count.set_value_no_signal(requested)
	difficulty.select(skill)
	count.editable = editable
	difficulty.disabled = not editable
	ownership.visible = not editable
	_summary_values = Vector2i(effective, total)
	_translate_summary()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_instance_valid(summary): _translate_summary()

func _translate_summary() -> void:
	summary.text = tr("CPUs this match: %d · Total survivors: %d") % [_summary_values.x, _summary_values.y]

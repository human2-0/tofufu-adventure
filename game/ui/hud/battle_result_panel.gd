class_name BattleResultPanel
extends PanelContainer
## Graphical round recap; values and rematch readiness come from the app.
signal replay_requested
signal leave_requested
var heading: Label
var status: Label
var replay: Button
var rank_badge: Label
var xp: BattleXPProgress
var metrics: BattleResultMetrics
var rewards: HBoxContainer
var _reward_labels: Array[Label] = []
var _stack: VBoxContainer
var _stamp: String = ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	add_theme_stylebox_override("panel", MenuStyle.panel(MenuStyle.INK))
	_stack = VBoxContainer.new()
	_stack.add_theme_constant_override("separation", 8)
	add_child(_stack)
	var ribbon := HBoxContainer.new()
	ribbon.add_theme_constant_override("separation", 14)
	_stack.add_child(ribbon)
	rank_badge = MenuStyle.label(ribbon, "", 34, MenuStyle.SOY_GOLD)
	rank_badge.custom_minimum_size.x = 68
	rank_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading = MenuStyle.label(ribbon, "", 24, MenuStyle.SOY_GOLD)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_stack.add_child(scroll)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	xp = BattleXPProgress.new()
	body.add_child(xp)
	rewards = HBoxContainer.new()
	body.add_child(rewards)
	for i in 4:
		var label := MenuStyle.label(rewards, "", 12, MenuStyle.MUTED)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_reward_labels.append(label)
	metrics = BattleResultMetrics.new()
	body.add_child(metrics)
	status = MenuStyle.paragraph(body, "")
	for label in [heading, rank_badge, status] + _reward_labels:
		label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	replay = MenuStyle.button(_stack, "Ready for rematch", replay_requested.emit)
	var actions := HBoxContainer.new()
	_stack.add_child(actions)
	MenuStyle.button(actions, "Spectate", hide).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	MenuStyle.button(actions, "Leave Battle Royale", leave_requested.emit).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	get_viewport().size_changed.connect(_responsive)
	_responsive()
	hide()

func display(summary: Dictionary, before: int, hunts: int) -> void:
	var stamp := JSON.stringify([TranslationServer.get_locale(), summary, before, hunts])
	if stamp == _stamp: return
	_stamp = stamp
	heading.text = tr("TOFUFU ROYALE! Victory") if summary.won else tr("ROUND COMPLETE")
	rank_badge.text = "#%d" % summary.rank
	var numbers: Array[String] = [str(summary.kills), str(summary.damage), str(summary.chests), "%d:%02d" % [int(summary.seconds) / 60, int(summary.seconds) % 60], str(hunts), "%d/3" % summary.goals]
	var labels: Array[String] = [tr("Eliminations"), tr("Damage dealt"), tr("Chests opened"), tr("Survival"), tr("Hunts"), tr("Goals completed")]
	metrics.display(numbers, labels, int(summary.goals))
	xp.display(before, int(summary.xp))
	var titles: Array[String] = [tr("Survival"), tr("Eliminations"), tr("Goals"), tr("Placement")]
	for i in 4: _reward_labels[i].text = "%s\n+%d XP" % [titles[i], summary.rewards[i]]

func _responsive() -> void:
	if not is_inside_tree(): return
	var area := get_viewport_rect().size
	var dimensions := Vector2(minf(700, area.x - 32), minf(580, area.y - 32))
	offset_left = -dimensions.x * 0.5
	offset_right = dimensions.x * 0.5
	offset_top = -dimensions.y * 0.5
	offset_bottom = dimensions.y * 0.5
	(get_theme_stylebox("panel") as StyleBoxFlat).set_content_margin_all(10 if area.y < 500 else 20)
	heading.add_theme_font_size_override("font_size", 18 if area.y < 500 else 24)
	rank_badge.add_theme_font_size_override("font_size", 28 if area.y < 500 else 34)
	_stack.add_theme_constant_override("separation", 6 if area.y < 500 else 8)
	for node in _stack.get_children():
		if node is Button: node.custom_minimum_size.y = 36 if area.y < 500 else 44
		if node is HBoxContainer:
			for child in node.get_children():
				if child is Button: child.custom_minimum_size.y = 36 if area.y < 500 else 44

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide()
		get_viewport().set_input_as_handled()

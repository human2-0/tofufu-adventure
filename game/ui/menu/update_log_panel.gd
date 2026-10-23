class_name UpdateLogPanel
extends VBoxContainer
## Bilingual release headlines with one expandable card; acknowledgement stays explicit.

signal closed
var close_button: Button
var cards: Array[UpdateLogCard] = []
var _scroll: ScrollContainer

func build(entries: Array[Dictionary]) -> void:
	add_theme_constant_override("separation", 10)
	var toolbar := HBoxContainer.new()
	add_child(toolbar)
	close_button = MenuStyle.button(toolbar, "Back to menu", closed.emit, MenuIcons.ARROW)
	MenuStyle.fit_button(close_button, true)
	var count := MenuStyle.label(toolbar, tr("%d updates") % entries.size(), 13, MenuStyle.MUTED)
	count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	add_child(_scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	_scroll.add_child(list)
	for index in range(entries.size() - 1, -1, -1):
		var card := UpdateLogCard.new()
		list.add_child(card)
		card.build(entries[index])
		card.expanded_requested.connect(_expand.bind(card))
		cards.append(card)
	get_viewport().size_changed.connect(_responsive)
	_responsive()
	MenuStyle.focus_later(close_button)

func _expand(selected: UpdateLogCard) -> void:
	if not is_inside_tree(): return
	var show_details := not selected.details.visible
	for card in cards: card.set_expanded(card == selected and show_details)
	if show_details and get_viewport_rect().size.y < 460: _reveal_first_bullet.call_deferred(selected)

func _reveal_first_bullet(selected: UpdateLogCard) -> void:
	if not is_inside_tree() or not is_instance_valid(selected) or not selected.details.visible: return
	await get_tree().process_frame
	if not is_inside_tree(): return
	await get_tree().process_frame
	if not is_inside_tree() or not is_instance_valid(selected) or not selected.details.visible: return
	var column := selected.details.get_child(0)
	if column.get_child_count() > 1: _scroll.ensure_control_visible(column.get_child(1) as Control)

func _responsive() -> void:
	if not is_inside_tree(): return
	var dimensions := get_viewport_rect().size
	_scroll.custom_minimum_size.y = clampf(dimensions.y - (240 if dimensions.y < 460 else 320), 90, 470)
	for card in cards: card.fit(dimensions.x < 850)

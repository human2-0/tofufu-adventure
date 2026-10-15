class_name SaveFlow
extends Node

signal start_requested(slot: int, data: Dictionary)
signal coop_requested(slot: int)
var store: SaveStore
var coop_store: SaveStore
var _shared: bool = false
var menu: LaunchMenu
var go_back: Callable

func show_saves(shared: bool = false) -> void:
	_shared = shared
	var content := menu.clear_page("Co-op adventures" if shared else "Solo adventures", "Solo and co-op progress have separate save slots.")
	var modes := HBoxContainer.new()
	content.add_child(modes)
	MenuStyle.button(modes, "Solo adventures", func() -> void: show_saves(false)).disabled = not shared
	MenuStyle.button(modes, "Co-op adventures", func() -> void: show_saves(true)).disabled = shared
	var target := coop_store if shared else store
	var saves := target.list_saves()
	if saves.is_empty():
		MenuStyle.label(content, "No footprints yet.", 24)
		MenuStyle.paragraph(content, "Host a new world from Co-op to begin." if shared else "Start a solo game and your adventure will appear here.")
	for entry in saves:
		if entry.valid: entry.valid = DungeonSnapshotValidation.adventure(entry.data)
		var row := HBoxContainer.new()
		content.add_child(row)
		var text := "Unreadable save · Slot %d" % (entry.slot + 1)
		if entry.valid:
			var data: Dictionary = entry.data
			text = "%s\n%s  ·  %d min  ·  %d EXP" % [data.name, data.saved_at.replace("T", "  "), int(data.seconds / 60), int(data.experience)]
		var button := MenuStyle.button(row, text, func() -> void: _continue(entry.slot, entry.data, shared))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.clip_text = true
		button.tooltip_text = text
		button.disabled = not entry.valid
		MenuStyle.button(row, "Delete", func() -> void: _delete(entry.slot))
	MenuStyle.paragraph(content, "The host saves the shared world, every character and unfinished pod progress." if shared else "Saves keep your progress, equipment and location. Creatures and harvestables regrow when you continue. An unfinished pod escape restarts from the pod.")
	MenuStyle.focus_later(MenuStyle.button(content, "Back", go_back))

func show_new() -> void:
	var content := menu.clear_page("Plant a new beginning", "Every adventure starts with one curious little bean.")
	if store.free_slot() < 0:
		MenuStyle.paragraph(content, "All 12 adventure slots are full. Delete a save in Continue to make room.")
	else:
		MenuStyle.label(content, "Adventure name", 18)
		var input := LineEdit.new()
		input.max_length = 48
		input.text = tr("A bean begins · %d") % (store.free_slot() + 1)
		content.add_child(input)
		MenuStyle.paragraph(content, "Your existing adventures stay safe. Autosaves keep this adventure up to date.")
		var begin := func() -> void:
			var title := input.text.strip_edges()
			if title.is_empty(): title = tr("A bean begins")
			start_requested.emit(store.free_slot(), {"name": title})
		MenuStyle.button(content, "Begin adventure     →", begin)
		input.text_submitted.connect(func(_text: String) -> void: begin.call())
		MenuStyle.focus_later(input)
	MenuStyle.button(content, "Back", go_back)

func _continue(slot: int, data: Dictionary, shared: bool) -> void:
	if shared: coop_requested.emit(slot)
	else: start_requested.emit(slot, data)

func _delete(slot: int) -> void:
	var target := coop_store if _shared else store
	var shared := _shared
	var dialog := ConfirmationDialog.new()
	dialog.title = "Delete this adventure?"
	dialog.dialog_text = "This permanently removes the selected save."
	dialog.ok_button_text = "Delete adventure"
	add_child(dialog)
	dialog.confirmed.connect(func() -> void:
		if not target.remove_slot(slot): menu.note.text = "Could not delete the save."
		dialog.queue_free()
		show_saves(shared))
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()

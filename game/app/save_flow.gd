class_name SaveFlow
extends Node

signal start_requested(slot: int, data: Dictionary)
var store: SaveStore
var menu: LaunchMenu
var go_back: Callable

func show_saves() -> void:
	var content := menu.clear_page("Your adventures", "Choose a saved adventure to return to Fufufarm.")
	var saves := store.list_saves()
	if saves.is_empty():
		MenuStyle.label(content, "No footprints yet.", 24)
		MenuStyle.paragraph(content, "Start a new game and your adventure will appear here.")
	for entry in saves:
		var row := HBoxContainer.new()
		content.add_child(row)
		var text := "Unreadable save · Slot %d" % (entry.slot + 1)
		if entry.valid:
			var data: Dictionary = entry.data
			text = "%s\n%s  ·  %d min  ·  %d EXP" % [data.name, data.saved_at.replace("T", "  "), int(data.seconds / 60), int(data.experience)]
		var button := MenuStyle.button(row, text, func() -> void: start_requested.emit(entry.slot, entry.data))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = not entry.valid
		MenuStyle.button(row, "Delete", func() -> void: _delete(entry.slot))
	MenuStyle.paragraph(content, "Saves keep your progress, equipment and location. Creatures and harvestables regrow when you continue. An unfinished pod escape restarts from the pod.")
	MenuStyle.focus_later(MenuStyle.button(content, "Back", go_back))

func show_new() -> void:
	var content := menu.clear_page("Plant a new beginning", "Every adventure starts with one curious little bean.")
	if store.free_slot() < 0:
		MenuStyle.paragraph(content, "All 12 adventure slots are full. Delete a save in Continue to make room.")
	else:
		MenuStyle.label(content, "Adventure name", 18)
		var input := LineEdit.new()
		input.max_length = 48
		input.text = "A bean begins · %d" % (store.free_slot() + 1)
		content.add_child(input)
		MenuStyle.paragraph(content, "Your existing adventures stay safe. Autosaves keep this adventure up to date.")
		var begin := func() -> void:
			var title := input.text.strip_edges()
			if title.is_empty(): title = "A bean begins"
			start_requested.emit(store.free_slot(), {"name": title})
		MenuStyle.button(content, "Begin adventure     →", begin)
		input.text_submitted.connect(func(_text: String) -> void: begin.call())
		MenuStyle.focus_later(input)
	MenuStyle.button(content, "Back", go_back)

func _delete(slot: int) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Delete this adventure?"
	dialog.dialog_text = "This permanently removes the selected save."
	dialog.ok_button_text = "Delete adventure"
	add_child(dialog)
	dialog.confirmed.connect(func() -> void:
		if not store.remove_slot(slot): menu.note.text = "Could not delete the save."
		dialog.queue_free()
		show_saves())
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()

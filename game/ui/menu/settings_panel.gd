class_name SettingsPanel
extends VBoxContainer

signal display_requested(index: int, fullscreen: bool)
signal deadzone_changed(value: float)
signal binding_requested(action: String, device: String)
signal reset_requested
signal back
var bindings: Dictionary[String, Button] = {}
var message: Label
var device: String = "keyboard"
var _rows: VBoxContainer

func build(resolutions: Array[Vector2i], selected: int, fullscreen: bool, deadzone: float, actions: Array[String]) -> void:
	MenuStyle.label(self, "Display", 22)
	var display_row := HBoxContainer.new()
	add_child(display_row)
	var sizes := OptionButton.new()
	for dimensions in resolutions:
		sizes.add_item("%d × %d" % [dimensions.x, dimensions.y])
	sizes.select(selected)
	display_row.add_child(sizes)
	var full := CheckButton.new()
	full.text = "Fullscreen"
	full.button_pressed = fullscreen
	display_row.add_child(full)
	MenuStyle.button(display_row, "Apply", func() -> void: display_requested.emit(sizes.selected, full.button_pressed))
	MenuStyle.paragraph(self, "Window size applies in windowed mode. Fullscreen uses your display’s native resolution.")
	MenuStyle.label(self, "Controls", 22)
	var devices := OptionButton.new()
	devices.add_item("Mouse & keyboard")
	devices.add_item("Controller")
	add_child(devices)
	devices.item_selected.connect(func(index: int) -> void:
		device = "keyboard" if index == 0 else "controller"
		binding_requested.emit("", device))
	MenuStyle.paragraph(self, "Mouse aims automatically. Controller: left stick moves, right stick aims. Select an action to rebind it. Esc cancels; Start opens the pause menu.")
	var dead_row := HBoxContainer.new()
	add_child(dead_row)
	var value_label := MenuStyle.label(dead_row, "Stick deadzone  %d%%" % int(deadzone * 100), 16)
	var slider := HSlider.new()
	slider.min_value = 0.1
	slider.max_value = 0.5
	slider.step = 0.05
	slider.value = deadzone
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dead_row.add_child(slider)
	slider.value_changed.connect(func(value: float) -> void:
		value_label.text = "Stick deadzone  %d%%" % int(value * 100)
		deadzone_changed.emit(value))
	message = MenuStyle.paragraph(self, "Preferences are saved on this device.")
	_rows = VBoxContainer.new()
	add_child(_rows)
	for action in actions:
		var row := HBoxContainer.new()
		_rows.add_child(row)
		var label := MenuStyle.label(row, action.capitalize(), 16)
		label.custom_minimum_size.x = 165
		var button := MenuStyle.button(row, "", func() -> void: binding_requested.emit(action, device))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.clip_text = true
		bindings[action] = button
	var footer := HBoxContainer.new()
	add_child(footer)
	MenuStyle.button(footer, "Reset controls", reset_requested.emit)
	MenuStyle.button(footer, "Back", back.emit)
	MenuStyle.focus_later(sizes)

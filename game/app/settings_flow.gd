class_name SettingsFlow
extends Node

var preferences: GamePreferences
var menu: LaunchMenu
var go_back: Callable
var panel: SettingsPanel
var _binding: String = ""
var _device: String = "keyboard"
var _confirm: ConfirmationDialog
var _remaining: float = 0.0
var _old_resolution: int
var _old_fullscreen: bool

func show_settings() -> void:
	var content := menu.clear_page("Make yourself at home", "A comfortable view. Controls that feel like you.")
	panel = SettingsPanel.new()
	content.add_child(panel)
	panel.build(GamePreferences.RESOLUTIONS, preferences.resolution, preferences.fullscreen, preferences.deadzone, GamePreferences.ACTIONS)
	panel.display_requested.connect(_preview_display)
	panel.deadzone_changed.connect(func(value: float) -> void:
		preferences.apply_deadzone(value)
		if preferences.save() != OK: panel.message.text = "Could not save preferences.")
	panel.binding_requested.connect(_bind)
	panel.reset_requested.connect(func() -> void:
		var error := preferences.reset_controls()
		_refresh_bindings()
		panel.message.text = "Controls reset." if error == OK else "Could not save preferences.")
	panel.back.connect(func() -> void:
		_binding = ""
		go_back.call())
	_refresh_bindings()

func _bind(action: String, device: String) -> void:
	_binding = action
	_device = device
	_refresh_bindings()
	if not action.is_empty():
		panel.message.text = "Press a %s input for %s. Esc cancels." % [device, action.capitalize()]

func _refresh_bindings() -> void:
	for action: String in panel.bindings:
		panel.bindings[action].text = GamePreferences.binding_text(action, panel.device)

func _input(event: InputEvent) -> void:
	if _binding.is_empty() or not is_instance_valid(panel):
		return
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		_binding = ""
		panel.message.text = "Rebinding cancelled."
		get_viewport().set_input_as_handled()
	elif GamePreferences.accepts(event, _device):
		var error := preferences.bind_action(_binding, event, _device)
		panel.message.text = "Binding saved." if error.is_empty() else error
		if error.is_empty(): _binding = ""
		_refresh_bindings()
		get_viewport().set_input_as_handled()

func _preview_display(index: int, fullscreen: bool) -> void:
	_old_resolution = preferences.resolution
	_old_fullscreen = preferences.fullscreen
	preferences.apply_display(index, fullscreen)
	_confirm = ConfirmationDialog.new()
	_confirm.title = "Keep this display setting?"
	_confirm.ok_button_text = "Keep"
	_confirm.cancel_button_text = "Revert"
	_confirm.dialog_hide_on_ok = false
	add_child(_confirm)
	_remaining = 15.0
	_confirm.confirmed.connect(func() -> void:
		_remaining = 0
		if preferences.save() != OK: panel.message.text = "Display applied, but could not save preferences."
		_confirm.queue_free())
	_confirm.canceled.connect(_revert_display)
	_confirm.popup_centered(Vector2i(430, 150))

func _process(delta: float) -> void:
	if _remaining <= 0:
		return
	_remaining -= delta
	_confirm.dialog_text = "Reverting automatically in %d seconds." % ceili(_remaining)
	if _remaining <= 0: _revert_display()

func _revert_display() -> void:
	_remaining = 0
	preferences.apply_display(_old_resolution, _old_fullscreen)
	if is_instance_valid(_confirm): _confirm.queue_free()
	show_settings()

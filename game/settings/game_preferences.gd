class_name GamePreferences
extends RefCounted
## Local settings only. ConfigFile stores primitives, never peer-supplied objects.

const ACTIONS: Array[String] = ["move_left", "move_right", "move_up", "move_down", "jump", "dash", "attack", "guard", "punch", "drop_weapon", "pickup_weapon", "knife_slot", "fist_slot", "gun_slot", "sotjet_slot", "camera_mode", "toggle_help", "return_to_camp", "skip_time"]
const RESOLUTIONS: Array[Vector2i] = [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440)]
var path: String = "user://preferences.cfg"
var config := ConfigFile.new()
var deadzone: float = 0.25
var resolution: int = 1
var fullscreen: bool = false

func load_preferences() -> void:
	config.load(path)
	deadzone = clampf(float(config.get_value("controls", "deadzone", 0.25)), 0.1, 0.5)
	resolution = clampi(int(config.get_value("display", "resolution", 1)), 0, RESOLUTIONS.size() - 1)
	fullscreen = bool(config.get_value("display", "fullscreen", false))
	for action in ACTIONS:
		for device in ["keyboard", "controller"]:
			var binding: Variant = config.get_value(device, action, {})
			if binding is Dictionary:
				var event := decode(binding)
				if event != null:
					_replace(action, event, device)
	apply_deadzone(deadzone)
	apply_display(resolution, fullscreen)

func save() -> Error:
	config.set_value("display", "resolution", resolution)
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("controls", "deadzone", deadzone)
	return config.save(path)

func apply_display(index: int, full: bool) -> void:
	resolution = clampi(index, 0, RESOLUTIONS.size() - 1)
	fullscreen = full
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if full else DisplayServer.WINDOW_MODE_WINDOWED)
	if not full:
		DisplayServer.window_set_size(RESOLUTIONS[resolution])
		var screen := DisplayServer.window_get_current_screen()
		DisplayServer.window_set_position(DisplayServer.screen_get_position(screen) + (DisplayServer.screen_get_size(screen) - RESOLUTIONS[resolution]) / 2)

func apply_deadzone(value: float) -> void:
	deadzone = clampf(value, 0.1, 0.5)
	for action in ["move_left", "move_right", "move_up", "move_down", "aim_left", "aim_right", "aim_up", "aim_down"]:
		InputMap.action_set_deadzone(action, deadzone)

func bind_action(action: String, event: InputEvent, device: String) -> String:
	if action not in ACTIONS or not accepts(event, device):
		return "Choose a key, mouse button, controller button or trigger."
	if event is InputEventKey and event.physical_keycode in [KEY_ESCAPE, KEY_ENTER]:
		return "Escape and Enter are reserved for menu navigation."
	if event is InputEventJoypadButton and event.button_index == JOY_BUTTON_START:
		return "Start is reserved for the pause menu."
	for other in ACTIONS:
		if other == action:
			continue
		for existing in InputMap.action_get_events(other):
			if same_device(existing, device) and existing.is_match(event):
				return "Already used by %s. Rebind that action first." % other.capitalize()
	_replace(action, event, device)
	config.set_value(device, action, encode(event))
	return "" if save() == OK else "Binding applied, but preferences could not be saved."

func reset_controls() -> Error:
	InputMap.load_from_project_settings()
	if config.has_section("keyboard"): config.erase_section("keyboard")
	if config.has_section("controller"): config.erase_section("controller")
	apply_deadzone(0.25)
	return save()

static func same_device(event: InputEvent, device: String) -> bool:
	return (event is InputEventKey or event is InputEventMouseButton) if device == "keyboard" else (event is InputEventJoypadButton or event is InputEventJoypadMotion)

static func accepts(event: InputEvent, device: String) -> bool:
	if not same_device(event, device):
		return false
	if event is InputEventJoypadMotion:
		return event.axis in [JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT] and event.axis_value > 0.7
	return event.is_pressed() and not event.is_echo()

static func binding_text(action: String, device: String) -> String:
	var names: PackedStringArray = []
	for event in InputMap.action_get_events(action):
		if same_device(event, device):
			names.append(event.as_text().replace(" (Physical)", "").replace("Joypad", "Pad"))
	return " / ".join(names) if not names.is_empty() else "Unassigned"

func _replace(action: String, event: InputEvent, device: String) -> void:
	for previous in InputMap.action_get_events(action):
		if same_device(previous, device):
			if action.begins_with("move_") and previous is InputEventJoypadMotion: continue
			InputMap.action_erase_event(action, previous)
	event.device = -1
	InputMap.action_add_event(action, event)

static func encode(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {"kind": "key", "code": event.physical_keycode}
	if event is InputEventMouseButton:
		return {"kind": "mouse", "code": event.button_index}
	if event is InputEventJoypadButton:
		return {"kind": "button", "code": event.button_index}
	return {"kind": "trigger", "code": (event as InputEventJoypadMotion).axis}

static func decode(data: Dictionary) -> InputEvent:
	var code := int(data.get("code", -1))
	if code < 0 or code > 10000000:
		return null
	match data.get("kind"):
		"key":
			var event := InputEventKey.new()
			event.physical_keycode = code as Key
			return event
		"mouse":
			var event := InputEventMouseButton.new()
			event.button_index = code as MouseButton
			return event
		"button":
			var event := InputEventJoypadButton.new()
			event.button_index = code as JoyButton
			return event
		"trigger":
			var event := InputEventJoypadMotion.new()
			event.axis = code as JoyAxis
			event.axis_value = 1.0
			return event
	return null

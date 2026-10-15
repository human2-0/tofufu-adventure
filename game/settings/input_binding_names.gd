class_name InputBindingNames
extends RefCounted
## Device glyphs remain recognizable; descriptive binding names use the local language.

static func describe(event: InputEvent) -> String:
	if event is InputEventKey:
		var arrows := {KEY_LEFT: "←", KEY_RIGHT: "→", KEY_UP: "↑", KEY_DOWN: "↓"}
		var names := _modifiers(event, event.physical_keycode)
		names.append(TranslationServer.translate(arrows.get(event.physical_keycode, OS.get_keycode_string(event.physical_keycode))))
		return "+".join(names)
	if event is InputEventMouseButton:
		var names := {MOUSE_BUTTON_LEFT: "Left mouse button", MOUSE_BUTTON_RIGHT: "Right mouse button", MOUSE_BUTTON_MIDDLE: "Middle mouse button", MOUSE_BUTTON_WHEEL_UP: "Wheel up", MOUSE_BUTTON_WHEEL_DOWN: "Wheel down"}
		var parts := _modifiers(event)
		parts.append(TranslationServer.translate(names.get(event.button_index, "Mouse button %d" % event.button_index)))
		return "+".join(parts)
	if event is InputEventJoypadButton:
		var names := ["A / ✕", "B / ○", "X / □", "Y / △", "Select / Share", "PS / Xbox / Home", "Start / Options", "L3", "R3", "L1 / LB", "R1 / RB", "D-pad ↑", "D-pad ↓", "D-pad ←", "D-pad →"]
		return TranslationServer.translate(names[event.button_index] if event.button_index < names.size() else "Controller button %d" % event.button_index)
	if event is InputEventJoypadMotion:
		if event.axis == JOY_AXIS_TRIGGER_LEFT: return "L2 / LT"
		if event.axis == JOY_AXIS_TRIGGER_RIGHT: return "R2 / RT"
		var name := "Left stick" if event.axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y] else "Right stick"
		var direction := ("←" if event.axis_value < 0 else "→") if event.axis in [JOY_AXIS_LEFT_X, JOY_AXIS_RIGHT_X] else ("↑" if event.axis_value < 0 else "↓")
		return TranslationServer.translate(name) + " " + direction
	return event.as_text()

static func _modifiers(event: InputEventWithModifiers, key: int = 0) -> PackedStringArray:
	var names: PackedStringArray = []
	if event.ctrl_pressed and key != KEY_CTRL: names.append("Ctrl")
	if event.alt_pressed and key != KEY_ALT: names.append("Alt")
	if event.shift_pressed and key != KEY_SHIFT: names.append("Shift")
	if event.meta_pressed and key != KEY_META: names.append("⌘")
	return names

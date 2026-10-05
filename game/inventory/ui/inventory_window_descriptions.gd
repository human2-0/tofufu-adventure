class_name InventoryWindowDescriptions
extends RefCounted
## Shares focused item description behavior between inventory and depot slots.

static func watch(window: Variant, button: InventorySlotButton) -> void:
	button.mouse_entered.connect(show_for_slot.bind(window, button))
	button.focus_entered.connect(show_for_slot.bind(window, button))
	button.mouse_exited.connect(hide_for_slot.bind(window, button))
	button.focus_exited.connect(hide_for_slot.bind(window, button))

static func show_for_slot(window: Variant, button: InventorySlotButton) -> void:
	window._inspected_button = button
	if window._description == null: return
	var stack := button.current_stack
	window._description.text = "%s ×%d · %s" % [stack.item.name, stack.count, stack.item.description] if stack != null and stack.item != null else "Hover or focus an item to see its description."

static func hide_for_slot(window: Variant, button: InventorySlotButton) -> void:
	if window._inspected_button != button or button.has_focus() or button.get_global_rect().has_point(button.get_global_mouse_position()): return
	var focused := window.get_viewport().gui_get_focus_owner() as InventorySlotButton
	if focused != null and focused.window_ref == window:
		show_for_slot(window, focused)
		return
	window._inspected_button = null
	if window._description != null: window._description.text = "Hover or focus an item to see its description."

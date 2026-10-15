class_name InventoryWindowDescriptions
extends RefCounted
## Connects occupied bag, equipment and depot slots to their floating inspector.

static func watch(window: Variant, button: InventorySlotButton) -> void:
	window._tooltip.watch(button, func() -> ItemStack: return button.current_stack)

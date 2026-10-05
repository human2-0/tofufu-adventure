class_name InventoryPreferences
extends RefCounted
## Connects user-level inventory choices to the current adventure window.

static func configure(window: InventoryWindow, preferences: GamePreferences) -> void:
	window.drop_confirmation.skip_future = preferences.skip_item_drop_warning
	var callback := Callable(preferences, "remember_item_drop_warning_skip")
	if not window.drop_warning_skipped.is_connected(callback): window.drop_warning_skipped.connect(callback)

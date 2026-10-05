class_name LaunchInput
extends RefCounted
## Applies the correct local controls and menus for online or offline play.

func set_enabled(game: Node3D, preferences: GamePreferences, online: bool, coop: CoopSession, enabled: bool) -> void:
	if enabled: InventoryPreferences.configure(game.inventory_window, preferences)
	if not enabled:
		game.map.close()
		game.inventory_window.close()
		game.seed_storage.window.close()
		game.merchant.window.close()
		if game.quest_giver != null: game.quest_giver.window.close()
	game.chat.set_menu_open(not enabled)
	if online: coop.local_input_enabled(enabled)
	else: (game.player.command_source as LocalPlayerInput).enabled = enabled

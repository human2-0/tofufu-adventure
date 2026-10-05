class_name CoopLocalMenus
extends RefCounted
## Local factory views are opened by the owning guest before bounded intent is sent.

static func sample(session: CoopSession, command: PlayerCommand) -> void:
	var dungeon: TofuDungeon = session.game.factory_dungeon
	if command.pickup_pressed and dungeon.puzzle_enabled and dungeon.actor_in_run(session.game.player):
		dungeon.interact(session.game.player)
		command.pickup_pressed = false

static func handle(session: CoopSession, event: InputEvent) -> void:
	var game: Node3D = session.game
	if game.inventory_window.visible or game.map.expanded: return
	if event.is_action_pressed("return_to_camp") and game.factory_dungeon.puzzle_enabled and game.factory_dungeon.actor_in_run(game.player):
		DungeonRunActions.open_menu(game.factory_dungeon)
		game.get_viewport().set_input_as_handled()
	if event.is_action_pressed("toggle_help") and not event.is_echo():
		if game.factory_dungeon.puzzle_enabled and game.factory_dungeon.actor_in_run(game.player): DungeonRunActions.toggle_journal(game.factory_dungeon)
		else: game.hud.toggle_help()

class_name LaunchFlows
extends RefCounted
## Explicitly wires launch flows; lifecycle and mutable state stay on the launch node.

static func connect_flows(app: Node) -> void:
	app.battle.app = app
	app.battle.transport = app.battle_transport
	app.add_child(app.battle)
	app.store.mode = "solo"
	app.coop_store.mode = "coop"
	app.coop_store.directory = app.store.directory
	app.coop_store.size_limit = 4194304
	app.coop_store.extra_validator = CoopCheckpoint.valid
	app.saves.store = app.store
	app.saves.coop_store = app.coop_store
	app.saves.menu = app.menu
	app.saves.go_back = app._home
	app.saves.start_requested.connect(app._start)
	app.add_child(app.saves)
	app.settings.preferences = app.preferences
	app.settings.menu = app.menu
	app.settings.go_back = app._home
	app.add_child(app.settings)
	app.room.started.connect(app._start_coop)
	app.room.ended.connect(app._coop_ended)
	app.add_child(app.room)
	app.readiness.room = app.room
	app.readiness.loader = app.loader
	app.add_child(app.readiness)
	app.connection.room = app.room
	app.connection.transport = app.transport
	app.add_child(app.connection)
	app.lobby.store = app.coop_store
	app.saves.coop_requested.connect(func(slot: int) -> void:
		app.public_play.active = false
		app.lobby.open_saved(slot))
	app.lobby.preferences = app.preferences
	app.lobby.menu = app.menu
	app.lobby.room = app.room
	app.lobby.connection = app.connection
	app.lobby.peer_transport = app.transport if app.transport.can_host() else null
	app.lobby.server_transport = app.server_transport if app.server_transport != null else app.transport as OracleTransport
	app.lobby.go_back = app._home
	app.add_child(app.lobby)
	app.public_play.menu = app.menu
	app.public_play.room = app.room
	app.public_play.connection = app.connection
	app.public_play.transport = app.lobby.server_transport
	app.public_play.go_back = app._home
	app.add_child(app.public_play)

static func coop_ended(app: Node, reason: String) -> void:
	if not app._online or app._quitting: return
	if is_instance_valid(app._coop) and app._coop.authority: app._coop.duel.session_ended()
	if is_instance_valid(app._coop) and app._coop.authority and not app._save(): return
	app._online = false
	app._clear_game()
	if app.public_play.active: app.public_play.show_ended(reason)
	else: app.lobby.show_lobby()
	app.menu.note.text = reason

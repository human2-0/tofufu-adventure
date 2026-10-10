class_name LaunchFlows
extends RefCounted
## Explicitly wires launch flows; lifecycle and mutable state stay on the launch node.

static func connect_flows(app: Node) -> void:
	app.saves.store = app.store
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
	app.lobby.store = app.store
	app.lobby.preferences = app.preferences
	app.lobby.menu = app.menu
	app.lobby.room = app.room
	app.lobby.connection = app.connection
	app.lobby.peer_transport = app.transport if app.transport.can_host() else null
	app.lobby.server_transport = app.server_transport if app.server_transport != null else app.transport as OracleTransport
	app.lobby.go_back = app._home
	app.add_child(app.lobby)

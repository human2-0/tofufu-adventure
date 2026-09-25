class_name CoopSession
extends Node
## Coordinates full host simulation, bounded input, world snapshots and party lifecycle.

var game: Node3D
var room: PlaytestRoom
var authority: bool = false
var farming: CoopFarming
var roster := CoopRoster.new()
var opening := CoopOpening.new()
var checkpoint: Dictionary = {}
var _window := InputWindow.new()
var _sequence: int = 0
var _snapshot_sequence: int = -1
var _snapshot_clock: float = 0
var _silence: float = 0
var _world_clock: float = 0
var _ready_peers: Dictionary = {}
var _pending: Dictionary = {}
var _synchronized: bool = false
var _ping_clock: float = 0
var latency_ms: int = 0

func _ready() -> void:
	process_physics_priority = 10
	authority = room.hosting
	game.set_physics_process(false)
	roster.game = game
	roster.room = room
	roster.authority = authority
	if not checkpoint.is_empty():
		roster.saved_states = checkpoint.party.duplicate(true)
		game.encounters.experience = int(checkpoint.world.experience)
	add_child(roster)
	game.factory_dungeon.configure_party(roster.party, authority)
	roster.changed.connect(game.factory_dungeon._sync_unlock)
	game.map.roster = roster
	opening.game = game
	opening.roster = roster
	opening.authority = authority
	add_child(opening)
	if authority:
		var encounters := CoopEncounters.new()
		encounters.game = game
		encounters.party = roster.party
		add_child(encounters)
		if not checkpoint.is_empty():
			CoopWorld.apply(game, checkpoint.world, false)
			if not checkpoint.world.has("world_items"): _migrate_legacy_drops()
			opening.apply(checkpoint.opening)
	else:
		CoopWorld.disable_simulation(game)
		game.hud.announce("Joining your friends / Synchronizing the adventure…")
	game.inventory_window.drop_requested.disconnect(game.world_items._queue_bag_drop)
	var inventory_sync := CoopInventory.new()
	inventory_sync.session = self
	add_child(inventory_sync)
	farming = CoopFarming.new()
	farming.session = self
	add_child(farming)
	game.chat.connect_session(room, roster)
	room.gameplay_packet.connect(_packet)
	room.admission = func(key: String) -> bool: return key in roster.saved_states or roster.capture_party().size() < 32
	roster.changed.connect(_roster_changed)
	if not authority: room.send_game(room.host_key, {"type": "ready"})

func _physics_process(delta: float) -> void:
	if not room.playing: return
	_sequence += 1
	if _sequence >= 2147483600:
		room.leave()
		return
	if authority:
		for member: CoopActor in roster.party.values():
			if not opening.active() and member.actor.position.y < -5: member.die()
			member.actor.surface_speed = 0.55 if game.world.is_water(member.actor.position) else 1.0
		_snapshot_clock += delta
		_world_clock += delta
		if _snapshot_clock >= 0.05:
			_snapshot_clock = fmod(_snapshot_clock, 0.05)
			_publish()
	else:
		_silence += delta
		if _silence > 10:
			room.leave("The host stopped sending the adventure. Please rejoin their meadow.")
			return
		if not _pending.is_empty():
			_apply(_pending)
			_pending = {}
		if _synchronized:
			var command := roster.local_input.sample(game.player.position)
			room.send_game(room.host_key, CoopValues.input(command, _sequence, _snapshot_sequence))
			if not opening.active():
				game.player.surface_speed = 0.55 if game.world.is_water(game.player.position) else 1.0
				roster.party[room.local_key].prediction.step(command, _sequence, delta)
		_ping_clock += delta
		if _ping_clock >= 1:
			_ping_clock = 0
			room.send_game(room.host_key, {"type": "ping", "stamp": Time.get_ticks_msec()})

func _packet(key: String, data: Dictionary) -> void:
	if authority:
		if data.get("type") == "ready" and not _ready_peers.has(key):
			_ready_peers[key] = true
			_window.forget(key)
			_world_clock = 1
		elif data.get("type") == "input" and _ready_peers.has(key) and roster.party.has(key):
			if _window.accept(key, data, _sequence):
				(roster.actors[key].command_source as RemotePlayerInput).accept(CoopValues.command(data), int(data.sequence))
		elif data.get("type") == "ping" and ExplorationProtocol.sequence(data.get("stamp")):
			room.send_game(key, {"type": "pong", "stamp": data.stamp})
	elif key == room.host_key:
		if data.get("type") == "snapshot":
			if not ExplorationProtocol.valid_snapshot(data, room.members) or int(data.sequence) <= _snapshot_sequence: return
			_snapshot_sequence = int(data.sequence)
			_silence = 0
			if not data.has("world") and _pending.has("world"): data.world = _pending.world
			_pending = data
		elif data.get("type") == "pong" and ExplorationProtocol.sequence(data.get("stamp")):
			latency_ms = maxi(0, Time.get_ticks_msec() - int(data.stamp))

func _publish() -> void:
	var states := {}
	for key: String in roster.party: states[key] = roster.party[key].capture()
	var snapshot := {"type": "snapshot", "sequence": _sequence, "actors": states, "opening": opening.capture()}
	if _world_clock >= 0.1:
		snapshot.world = CoopWorld.capture(game)
		_world_clock = 0
	for key: String in room.members:
		if key != room.local_key and _ready_peers.has(key): room.send_game(key, snapshot.duplicate(true))

func _apply(data: Dictionary) -> void:
	if data.has("world"):
		CoopWorld.apply(game, data.world, true)
		if not _synchronized: game.hud.announce("Connected / The host saves our shared adventure.")
		_synchronized = true
	opening.apply(data.opening)
	if not data.opening.active:
		for key: String in data.actors:
			if roster.party.has(key): roster.party[key].accept_view(data.actors[key])

func _roster_changed() -> void:
	for key: String in _ready_peers.keys():
		if key not in room.members:
			_ready_peers.erase(key)
			_window.forget(key)
	_world_clock = 1

func _unhandled_input(event: InputEvent) -> void:
	if game.inventory_window.visible or game.map.expanded: return
	if event.is_action_pressed("toggle_help") and not event.is_echo(): game.hud.toggle_help()

func local_input_enabled(enabled: bool) -> void:
	(roster.local_input as LocalPlayerInput).enabled = enabled

func _process(delta: float) -> void:
	if authority and room.dedicated: return
	var label := "Co-op · %d/4 beans · %s" % [room.members.size(), "Host saves" if authority else "%d ms RTT" % latency_ms]
	game.hud.show_session(label)
	if authority: return
	for dummy: PracticeDummy in game.encounters.dummy_nodes:
		dummy._figure.rotation.z = lerpf(dummy._figure.rotation.z, 0, minf(1, delta * 9))

func _migrate_legacy_drops() -> void:
	var rows: Array = []
	for state: Dictionary in checkpoint.party.values():
		if not state.combat.owned:
			var at: Array = state.combat.drop
			rows.append([rows.size() + 1, "knife", 1, 100, at[0], at[1] + 0.4, at[2]])
	game.world_items.pool.restore(rows)

class_name CoopSession
extends Node
## Coordinates full host simulation, bounded input, world snapshots and party lifecycle.

var game: Node3D
var room: PlaytestRoom
var authority: bool = false
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
	authority = room.hosting
	game.set_physics_process(false)
	roster.game = game
	roster.room = room
	roster.authority = authority
	if not checkpoint.is_empty():
		roster.saved_states = checkpoint.party.duplicate(true)
		game.encounters.experience = int(checkpoint.world.experience)
	add_child(roster)
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
			opening.apply(checkpoint.opening)
	else:
		CoopWorld.disable_simulation(game)
		game.hud.announce("Joining your friends / Synchronizing the adventure…")
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
			if not opening.active() and member.actor.position.y < -5: member.respawn()
			member.actor.surface_speed = 0.55 if game.world.is_water(member.actor.position) else 1.0
		_snapshot_clock += delta
		_world_clock += delta
		if _snapshot_clock >= 0.05:
			_snapshot_clock = 0
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
			room.send_game(room.host_key, CoopValues.input(roster.local_input.sample(game.player.position), _sequence, _snapshot_sequence))
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
				(roster.actors[key].command_source as RemotePlayerInput).accept(CoopValues.command(data))
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
	if event.is_action_pressed("toggle_help") and not event.is_echo(): game.hud.toggle_help()

func local_input_enabled(enabled: bool) -> void:
	(roster.local_input as LocalPlayerInput).enabled = enabled

func _process(delta: float) -> void:
	var label := "Co-op · %d/4 beans · %s" % [room.members.size(), "Host saves" if authority else "%d ms" % latency_ms]
	game.hud.show_session(label)
	if authority: return
	for mob: TrainingMob in game.encounters.mob_nodes:
		mob._sprite.modulate = mob._sprite.modulate.lerp(Color.WHITE, minf(1, delta * 5))
	for dummy: PracticeDummy in game.encounters.dummy_nodes:
		dummy._figure.rotation.z = lerpf(dummy._figure.rotation.z, 0, minf(1, delta * 9))

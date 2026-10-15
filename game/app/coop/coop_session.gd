class_name CoopSession
extends Node
## Coordinates full host simulation, bounded input, world snapshots and party lifecycle.

var game: Node3D
var room: PlaytestRoom
var authority: bool = false
var farming: CoopFarming
var duel: CoopDuel
var inventory_sync: CoopInventory
var roster := CoopRoster.new()
var opening := CoopOpening.new()
var checkpoint: Dictionary = {}
var _window := InputWindow.new()
var _sequence: int = 0
var _snapshot_sequence: int = -1
var _snapshot_clock: float = 0
var _silence: float = 0
var _world_clock: float = 0
var _pending_puzzle: Dictionary = {}
var _ready_peers: Dictionary = {}
var _pending: Dictionary = {}
var _synchronized: bool = false
var _ping_clock: float = 0
var latency_ms: int = 0
var public_mode: bool = false
var personal_maps: CoopPersonalMaps
var connection_health: CoopConnectionHealth
var _world_changes := ReplicaWorldChanges.new()
var _snapshots := CoopSnapshotFlow.new()
var _encounter_motion: CoopEncounterMotion

func _ready() -> void:
	authority = room.hosting
	process_physics_priority = 10 if authority else -20
	game.set_physics_process(false)
	if game.solo_arena != null: game.solo_arena.enabled = false
	roster.game = game
	roster.room = room
	roster.authority = authority
	if not checkpoint.is_empty():
		roster.saved_states = checkpoint.party.duplicate(true)
		game.encounters.experience = int(checkpoint.world.experience)
	add_child(roster)
	duel = CoopDuel.new()
	duel.session = self
	add_child(duel)
	game.castle_adventure.configure_party(roster.party, authority)
	roster.changed.connect(game.castle_adventure.sync_party)
	game.factory_dungeon.configure_party(roster.party, authority)
	game.factory_dungeon.puzzle_command_requested.connect(_send_puzzle_command)
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
		encounters.duel = duel
		add_child(encounters)
		if not checkpoint.is_empty():
			CoopWorld.apply(game, checkpoint.world, false)
			game.seed_storage.barn.adopt_solo(room.local_key)
			BarnDisplay.adopt_solo(game.world_items, room.local_key)
			if not checkpoint.world.has("world_items"): _migrate_legacy_drops()
			opening.apply(checkpoint.opening)
	else:
		CoopWorld.disable_simulation(game)
		_encounter_motion = CoopEncounterMotion.new()
		_encounter_motion.game = game
		add_child(_encounter_motion)
		game.hud.announce("Joining your friends / Synchronizing the adventure…")
	CoopInteractions.build(self)
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
			if not opening.active() and TerrainLocomotion.fallen(member.actor.position, game.world): member.die()
			TerrainLocomotion.apply(member.actor, game.world)
		duel.step(delta)
		_snapshot_clock += delta
		_world_clock += delta
		if _snapshot_clock >= 1.0 / 60.0:
			_snapshot_clock = fmod(_snapshot_clock, 1.0 / 60.0)
			_publish()
	else:
		_silence += delta
		if _silence > (10.0 if _synchronized else 60.0):
			room.leave("The host stopped sending the adventure. Please rejoin their meadow.")
			return
		if not _pending.is_empty():
			_apply(_pending)
			_pending = {}
		if _synchronized:
			var command := roster.local_input.sample(game.player.position)
			CoopLocalMenus.sample(self, command)
			room.send_game(room.host_key, CoopValues.input(command, _sequence, _snapshot_sequence))
			if not opening.active():
				TerrainLocomotion.apply(game.player, game.world)
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
		elif data.get("type") == "tofu_puzzle" and _ready_peers.has(key) and roster.party.has(key):
			var payload: Variant = data.get("command")
			if TofuPuzzleProtocol.valid(payload):
				var intent: TofuPuzzleCommand = CoopPuzzleBridge.decode(payload)
				var result: Dictionary = game.factory_dungeon.submit_puzzle(intent, roster.party[key].actor)
				room.send_game(key, {"type": "tofu_puzzle_result", "sequence": intent.sequence, "accepted": bool(result.get("accepted", false))})
	elif key == room.host_key:
		if data.get("type") in ["snapshot", "snapshot_delta"]:
			_snapshots.receive(self, data)
		elif data.get("type") == "pong" and ExplorationProtocol.sequence(data.get("stamp")):
			latency_ms = maxi(0, Time.get_ticks_msec() - int(data.stamp))
		elif data.get("type") == "tofu_puzzle_result" and ExplorationProtocol.sequence(data.get("sequence")) and data.get("accepted") is bool:
			CoopPuzzleFeedback.receive(self, data)

func _send_puzzle_command(command: TofuPuzzleCommand) -> void:
	if authority or not _synchronized: return
	var payload: Dictionary = CoopPuzzleBridge.encode(command)
	if payload.is_empty() or _pending_puzzle.size() >= 32: return
	_pending_puzzle[command.sequence] = command
	room.send_game(room.host_key, {"type": "tofu_puzzle", "command": payload})

func _publish() -> void:
	_snapshots.publish(self)

func _apply(data: Dictionary) -> void:
	if data.has("world"):
		_encounter_motion.before_snapshot()
		CoopWorld.apply(game, data.world, true, _world_changes)
		_encounter_motion.accept()
		if not _synchronized: game.hud.announce("Connected / The host saves our shared adventure.")
		_synchronized = true
	opening.apply(data.opening)
	duel.present(data.get("duel", {}))
	if not data.opening.active:
		for key: String in data.actors:
			if roster.party.has(key): roster.party[key].accept_view(data.actors[key])

func _roster_changed() -> void:
	duel.members_changed()
	for key: String in _ready_peers.keys():
		if key not in room.members:
			_ready_peers.erase(key)
			_window.forget(key)
			_snapshots.channel.forget(key)
	_world_clock = 1

func _unhandled_input(event: InputEvent) -> void:
	CoopLocalMenus.handle(self, event)

func local_input_enabled(enabled: bool) -> void:
	(roster.local_input as LocalPlayerInput).enabled = enabled

func _process(delta: float) -> void:
	CoopSessionView.process(self, delta)

func _migrate_legacy_drops() -> void:
	var rows: Array = []
	for state: Dictionary in checkpoint.party.values():
		if not state.combat.owned:
			var at: Array = state.combat.drop
			rows.append([rows.size() + 1, "knife", 1, 100, at[0], at[1] + 0.4, at[2]])
	game.world_items.pool.restore(rows)

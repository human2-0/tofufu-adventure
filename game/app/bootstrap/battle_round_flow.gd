class_name BattleRoundFlow
extends RefCounted
## Keep connected friends together for an opt-in next round; never restart live humans.

var flow: BattleRoyaleFlow
var career := BattleCareer.new()
var epoch: String = ""
var votes: Dictionary = {}
var _term: int = 0
var _clock: float = 0
var _last_vote: Dictionary = {}

func begin(value: String) -> void:
	epoch = value
	votes.clear()
	_last_vote.clear()
	_term = flow.room.term

func settle() -> void:
	if not is_instance_valid(flow.game) or not flow.game.composed: return
	var game := flow.game
	if game.room.phase == "recovering": return
	career.award(epoch, BattleRoundStats.summary(game.match_state, game.local_slot), game.room.offline)

func request() -> void:
	var game := flow.game
	if not is_instance_valid(game) or flow.room.phase != "playing": return
	if flow.room.offline:
		if game.match_state.rows[game.local_slot][13] > 0: _launch()
		return
	if game.match_state.winner == -2: return
	var packet := {"kind": "br_rematch", "epoch": epoch, "term": flow.room.term, "ready": not votes.has(flow.room.local_key)}
	if flow.room.authority(): receive(flow.room.local_key, packet)
	else: flow.room.send(flow.room.host_key, packet)

func receive(key: String, packet: Dictionary) -> void:
	var room := flow.room
	if not is_instance_valid(flow.game) or room.phase != "playing" or packet.get("epoch") != epoch or packet.get("term") != room.term: return
	match packet.get("kind"):
		"br_rematch":
			if not room.authority() or flow.game.match_state.winner == -2 or not _member(key) or not room.connected.has(key) or not packet.get("ready") is bool: return
			if votes.has(key) == packet.ready or room.clock - float(_last_vote.get(key, -1)) < 0.25: return
			_last_vote[key] = room.clock
			if packet.ready: votes[key] = true
			else: votes.erase(key)
			_publish()
		"br_rematch_status":
			if key != room.host_key or not packet.get("ready") is Array or packet.ready.size() > 20: return
			var accepted: Dictionary = {}
			for id: Variant in packet.ready:
				if not id is String or not _member(id) or accepted.has(id): return
				accepted[id] = true
			votes = accepted
		"br_round":
			if key != room.host_key or not BattleProtocol.token(packet.get("next")) or packet.next == epoch: return
			if not BattleProtocol.roster(packet.get("members")): return
			for row: Dictionary in packet.members:
				if not _member(row.key): return
			var found := false
			var host := false
			for row: Dictionary in packet.members:
				if row.key == room.local_key: found = true
				if row.key == room.host_key: host = true
			if found and host and BattleOptions.playable(room.options, packet.members.size()): _accept(packet)

func update(delta: float) -> void:
	_clock += delta
	if _clock < 0.25 or not is_instance_valid(flow.game) or not flow.game.composed: return
	_clock = 0
	var room := flow.room
	var view := flow.game.match_view
	if room.phase == "recovering" or room.term != _term:
		votes.clear()
		_term = room.term
	if room.phase != "playing" or flow.game.match_state.winner == -2 or room.offline: return
	var total := 0
	var ready := 0
	for row: Dictionary in room.members:
		if not room.connected.has(row.key): continue
		total += 1
		if votes.has(row.key): ready += 1
	view.ready = votes.has(room.local_key)
	view.rematch_status = flow.tr("Rematch ready: %d / %d · Waiting for everyone") % [ready, total]
	if room.authority() and ready == total and total > 0: _launch()

func _member(key: String) -> bool:
	for row: Dictionary in flow.room.members:
		if row.key == key: return true
	return false

func _publish() -> void:
	var ready: Array = votes.keys()
	ready.sort()
	flow.room.broadcast({"kind": "br_rematch_status", "epoch": epoch, "term": flow.room.term, "ready": ready})

func _launch() -> void:
	var room := flow.room
	var members: Array = []
	for row: Dictionary in room.members:
		if room.connected.has(row.key): members.append(row.duplicate())
	if not BattleOptions.playable(room.options, members.size()):
		flow.game.match_view.rematch_status = flow.tr(BattleOptions.minimum_message(room.options))
		return
	var packet := {"kind": "br_round", "epoch": epoch, "term": room.term, "next": Crypto.new().generate_random_bytes(12).hex_encode(), "members": members}
	_accept(packet)
	room.broadcast(packet)

func _accept(packet: Dictionary) -> void:
	settle()
	var room := flow.room
	room.epoch = packet.next
	room.members = packet.members.duplicate(true)
	room.term = 0
	room.ready_members.clear()
	room._rates.clear()
	room.migration = BattleMigration.new()
	room.migration.room = room
	room.phase = "loading"
	room.deadline = room.clock + 120
	room.started.emit()

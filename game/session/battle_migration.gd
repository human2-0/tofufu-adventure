class_name BattleMigration
extends RefCounted
## Paused, majority-backed replacement over existing authenticated direct links.

signal paused
signal restoring(state: Dictionary)
signal resumed

var room: BattleRoom
var checkpoint: String = ""
var checkpoint_seq: int = 0
var voters: Array = []
var leases: Dictionary = {}
var failed_host: String = ""
var base_term: int = 0
var candidates: Array = []
var attempt: int = 0
var since: float = 0
var pulse: float = 0
var offers: Dictionary = {}
var election := BattleElection.new()
var vote_lock: String = ""
var heard: float = 0
var suspicions: Dictionary = {}

func quorum() -> int:
	return floori(candidates.size() / 2.0) + 1

func candidate() -> String:
	return str(candidates[attempt % candidates.size()]) if not candidates.is_empty() else ""

func publish(blob: String) -> void:
	if not room.authority() or room.phase != "playing": return
	if checkpoint.is_empty(): since = room.clock
	if not remember(blob): return
	room.broadcast({"kind": "br_checkpoint", "epoch": room.epoch, "term": room.term, "blob": blob})

func remember(blob: Variant) -> bool:
	var state := BattleCheckpoint.decode(blob, room.members)
	if state.is_empty() or state.options != room.options or int(state.seq) <= checkpoint_seq or not state.voters.has(room.host_key): return false
	# Transport loss may change CPU steering, never shrink the voting electorate.
	# Only a completed majority handoff establishes a new electorate.
	if not voters.is_empty() and state.voters != voters: return false
	checkpoint = blob
	checkpoint_seq = int(state.seq)
	voters = state.voters.duplicate()
	heard = room.clock
	return true

func start() -> void:
	if room.phase != "playing" or room.offline: return
	if checkpoint.is_empty():
		room.finish("The host left before a recovery checkpoint was shared. Please start a new match.")
		return
	failed_host = room.host_key
	base_term = room.term
	candidates = voters.duplicate()
	candidates.erase(failed_host)
	candidates.sort()
	if candidates.is_empty():
		room.finish("Not enough connected players could agree on a new host. Please start a new match.")
		return
	room.phase = "recovering"
	room.status = "Match paused · Finding a new host"
	vote_lock = ""
	paused.emit()
	advance(0)

func advance(value: int) -> void:
	attempt = value
	since = room.clock
	pulse = 1
	offers.clear()
	election.clear()
	room.status = "Match paused · Finding a new host"
	room.changed.emit()

func departed(key: String) -> void:
	if key == candidate() and election.committed:
		room.finish("The replacement host disconnected during recovery. Please start a new match.")

func cast(kind: String, fields: Dictionary = {}) -> void:
	var packet := fields.duplicate()
	packet.merge({"kind": kind, "epoch": room.epoch, "term": base_term, "attempt": attempt})
	receive(room.local_key, packet)
	room.broadcast(packet)

func receive(key: String, packet: Dictionary) -> void:
	if packet.get("epoch") != room.epoch: return
	var kind: String = packet.get("kind", "")
	if kind == "br_checkpoint":
		if room.phase == "playing" and key == room.host_key and packet.get("term") == room.term and remember(packet.get("blob")):
			room.send(key, {"kind": "br_lease", "epoch": room.epoch, "term": room.term, "seq": checkpoint_seq})
		return
	if kind == "br_lease":
		if room.authority() and room.phase == "playing" and packet.get("term") == room.term and voters.has(key) and BattleProtocol.integer(packet.get("seq"), maxi(1, checkpoint_seq - 100), checkpoint_seq):
			leases[key] = room.clock
		return
	if room.phase == "playing" and kind == "br_migrate" and packet.get("term") == room.term and voters.has(key):
		if not BattleProtocol.integer(packet.get("attempt"), 0, maxi(0, voters.size() - 2)): return
		suspicions[key] = room.clock
		var count := 0
		for at: float in suspicions.values():
			if room.clock - at < 2: count += 1
		var lost_link := not room.authority() and not room.peers.has(room.host_key)
		if key == room.host_key or lost_link or room.clock - heard > 3 or count >= floori((voters.size() - 1) / 2.0) + 1:
			start()
	if room.phase != "recovering" or packet.get("term") != base_term or not candidates.has(key): return
	if not BattleProtocol.integer(packet.get("attempt"), attempt, candidates.size() - 1): return
	if int(packet.attempt) > attempt: advance(int(packet.attempt))
	match kind:
		"br_moffer":
			if room.local_key != candidate(): return
			var state := BattleCheckpoint.decode(packet.get("blob"), room.members)
			if not state.is_empty() and state.options == room.options: offers[key] = {"blob": packet.blob, "seq": int(state.seq)}
		"br_mproposal", "br_mvote", "br_mcommit", "br_mready", "br_mgo": election.receive(self, key, packet)

func step(delta: float) -> void:
	if room.phase == "playing" and room.authority() and not room.offline and not checkpoint.is_empty():
		var count := 1
		for key: String in voters:
			if key != room.local_key and room.clock - float(leases.get(key, since)) < 3: count += 1
		if count < floori(voters.size() / 2.0) + 1: start()
	if room.phase != "recovering": return
	pulse += delta
	if pulse >= 0.4:
		pulse = 0
		cast("br_migrate")
		if candidates.has(room.local_key):
			var offer := {"kind": "br_moffer", "epoch": room.epoch, "term": base_term, "attempt": attempt, "blob": checkpoint}
			if candidate() == room.local_key: receive(room.local_key, offer)
			elif not offers.has(room.local_key):
				room.send(candidate(), offer)
				offers[room.local_key] = true # One full offer per attempt; streams are reliable.
		election.repeat(self)
	election.step(self)
	if room.phase != "recovering" or election.countdown >= 0: return
	if room.clock - since > 4:
		if attempt + 1 < candidates.size(): advance(attempt + 1)
		else: room.finish("Not enough connected players could agree on a new host. Please start a new match.")

func complete(active: Array) -> void:
	room.host_key = candidate()
	room.term = base_term + 1
	room.connected.clear()
	for key: String in active:
		if key == room.local_key or room.peers.has(key): room.connected[key] = true
	voters = active.duplicate()
	leases.clear()
	since = room.clock
	heard = room.clock
	suspicions.clear()
	if not active.has(room.local_key):
		room.finish("Your connection was replaced by a CPU during host recovery. Please return to the lobby.")
		return
	room.phase = "playing"
	resumed.emit()
	room.changed.emit()

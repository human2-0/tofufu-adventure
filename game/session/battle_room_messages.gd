class_name BattleRoomMessages
extends RefCounted
## Connection-bound admission and epoch gates before app gameplay dispatch.

static func receive(room: BattleRoom, key: String, data: Dictionary) -> void:
	if not room.peers.has(key) or data.size() > 18: return
	room._rates[key] = int(room._rates.get(key, 0)) + 1
	if room._rates[key] > 90: return
	var kind: Variant = data.get("kind")
	if not kind is String or not kind.begins_with("br_"): return
	match kind:
		"br_offer": _offer(room, key, data)
		"br_join": _join(room, key, data)
		"br_roster": _roster(room, key, data)
		"br_ready":
			if room.authority() and room.phase == "loading" and data.get("epoch") == room.epoch and _member(room, key):
				room.ready_members[key] = true
				room._try_running()
		"br_go":
			if key == room.host_key and room.phase == "loading" and data.get("epoch") == room.epoch:
				room.phase = "playing"
				room.running.emit()
		"br_leave":
			if data.get("epoch") != room.epoch or data.get("term", 0) != room.term: return
			room.connected.erase(key)
			if room.phase == "recovering": room.migration.departed(key)
			if key == room.host_key: room.authority_lost()
			elif room.authority() and room.phase == "waiting":
				for row: Dictionary in room.members.duplicate():
					if row.key == key: room.members.erase(row)
				room.broadcast_roster()
		_:
			if not _member(room, key): return
			if kind in ["br_checkpoint", "br_lease", "br_migrate", "br_moffer", "br_mproposal", "br_mvote", "br_mcommit", "br_mready", "br_mgo"]:
				room.migration.receive(key, data)
			elif data.get("epoch") == room.epoch and data.get("term") == room.term and room.phase == "playing" and room.connected.has(key):
				room.gameplay.emit(key, data)

static func _member(room: BattleRoom, key: String) -> bool:
	for row: Dictionary in room.members:
		if row.key == key: return true
	return false

static func _offer(room: BattleRoom, key: String, data: Dictionary) -> void:
	if data.get("build") != BattleProtocol.BUILD: return
	if data.get("v") != BattleProtocol.VERSION or not data.get("open") is bool or not BattleProtocol.integer(data.get("count"), 0, 20): return
	if room.auto_queue and data.get("duos", false) != BattleOptions.duos(room.options):
		room.offers.erase(key)
		return
	if data.open and int(data.count) < 20: room.offers[key] = int(data.count)
	else: room.offers.erase(key)
	if room.host_key.is_empty() and room.target_host == key and data.open: room.join(key)

static func _join(room: BattleRoom, key: String, data: Dictionary) -> void:
	if data.get("build") != BattleProtocol.BUILD: return
	if not room.authority() or room.phase != "waiting" or data.get("v") != BattleProtocol.VERSION: return
	if not BattleProtocol.integer(data.get("skin"), 0, 7): return
	if room.auto_queue and data.get("duos", false) != BattleOptions.duos(room.options): return
	if not _member(room, key):
		if room.members.size() >= 20: return
		room.members.append({"key": key, "name": str(room.peers[key]).left(24), "skin": int(data.skin)})
	room.connected[key] = true
	room.broadcast_roster()

static func _roster(room: BattleRoom, key: String, data: Dictionary) -> void:
	if data.get("build") != BattleProtocol.BUILD: return
	if key != room.target_host or room.phase not in ["joining", "waiting"]: return
	if data.get("v") != BattleProtocol.VERSION or not BattleProtocol.token(data.get("epoch")) or not BattleProtocol.roster(data.get("members")): return
	if not BattleOptions.valid(data.get("options")): return
	if data.get("phase") == "loading" and not BattleOptions.playable(data.options, data.members.size()): return
	if data.members[0].key != key or data.get("phase") not in ["waiting", "loading"]: return
	var contains_local := false
	for row: Dictionary in data.members:
		if row.key == room.local_key: contains_local = true
	if not contains_local: return
	if not room.epoch.is_empty() and room.epoch != data.epoch: return
	room.host_key = key
	room.epoch = data.epoch
	room.members = data.members.duplicate(true)
	room.options = BattleOptions.canonical(data.options)
	room.phase = data.phase
	room.deadline = room.clock + 130
	for row: Dictionary in room.members: room.connected[row.key] = true
	room.status = "Waiting for players · Choose CPUs or invite friends"
	room.changed.emit()
	if room.phase == "loading": room.started.emit()

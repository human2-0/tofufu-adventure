class_name RoomMessages
extends RefCounted
## Bounded room-message dispatch against explicit per-room state.

static func packet(room: PlaytestRoom, key: String, data: Dictionary) -> void:
	match data.get("type"):
		"presence":
			room.peers[key].hosting = data.get("hosting") == true
			room.peers[key].busy = data.get("busy") == true
		"join":
			if not room.hosting or (room.members.size() >= 4 and key not in room.members) or data.get("version") != room.GAME_VERSION or (room.admission.is_valid() and not room.admission.call(key)):
				room.send_packet.call(key, {"type": "reject"})
				return
			if key not in room.members: room.members.append(key)
			room._broadcast_roster()
			room.status = "%d / 4 beans gathered. Ready when you are." % room.members.size()
		"welcome":
			_welcome(room, key, data)
		"reject":
			if key == room._pending:
				room._pending = ""
				room.status = "This meadow is full, unavailable, or running a different game version."
		"begin":
			if key != room.host_key or room.hosting or room.playing or data.get("epoch") != room.epoch: return
			room.playing = true
			room._presence()
			room.started.emit(false, room.members.duplicate(), room.local_key)
		"leave":
			if data.get("epoch") != room.epoch: return
			if key == room.host_key and not room.hosting: room._reset_session("The host closed the meadow.")
			elif room.hosting and key in room.members:
				room.members.erase(key)
				room._broadcast_roster()
		"removed":
			if key == room.host_key and not room.hosting and data.get("epoch") == room.epoch:
				room._reset_session(str(data.get("reason", "The host ended this connection.")).left(160))
				room._presence()
		"input", "snapshot", "ready", "ping", "pong", "chat_text", "chat_voice", "inventory_transfer", "seed_storage_transfer", "seed_storage_quick_transfer", "shop_result", "storage_result", "grandma_quest", "inventory_consume", "currency_result", "farm_action", "farm_result", "apple_harvest", "tofu_puzzle", "tofu_puzzle_result", "parrot_action", "parrot_result":
			if room.playing and (key in room.members or key == room.host_key) and data.get("epoch") == room.epoch:
				room.gameplay_packet.emit(key, data)

static func _welcome(room: PlaytestRoom, key: String, data: Dictionary) -> void:
	if key != room._pending and key != room.host_key: return
	if not data.get("members") is Array or data.members.size() > 4 or data.members.size() < 1: return
	if not data.get("dedicated", false) is bool: return
	if (key not in data.members and not data.get("dedicated", false)) or room.local_key not in data.members: return
	if data.get("dedicated", false) and key in data.members: return
	for member: Variant in data.members:
		if not ExplorationProtocol.key(member) or data.members.count(member) != 1: return
	if not data.get("epoch") is String or data.epoch.length() != 32: return
	if not data.get("names") is Dictionary or data.names.size() > 4 or not data.get("playing") is bool: return
	for member: Variant in data.names:
		if member not in data.members or not data.names[member] is String or data.names[member].length() > 24: return
	room.dedicated = data.get("dedicated", false)
	room.names = data.names
	room.host_key = key
	room.epoch = data.epoch
	room.members = data.members
	room._pending = ""
	room.status = "Connected · %d beans in the meadow. Waiting for the host to start." % room.members.size()
	if data.playing and not room.playing:
		room.playing = true
		room.started.emit(false, room.members.duplicate(), room.local_key)

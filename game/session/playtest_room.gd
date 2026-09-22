class_name PlaytestRoom
extends Node
## Lobby lifecycle and admission. Identity is supplied by the authenticated transport.

signal changed
signal started(is_host: bool, members: Array, local_key: String)
signal gameplay_packet(key: String, data: Dictionary)
signal ended(reason: String)
var send_packet: Callable
var peers: Dictionary = {}
var members: Array = []
var names: Dictionary = {}
var admission: Callable
var local_key: String = ""
var local_name: String = "Host"
var host_key: String = ""
var epoch: String = ""
var hosting: bool = false
var playing: bool = false
var dedicated: bool = false # Authority has no player actor in this explicitly selected mode.
var status: String = "Choose a name, then discover other testers."
var _pending: String = ""
var _timeout: float = 0
var _retry_clock: float = 0
var _presence_clock: float = 0
const GAME_VERSION: int = 11

func receive(event: Dictionary) -> void:
	var key := str(event.get("key", ""))
	match event.get("type"):
		"ready":
			local_key = key
			local_name = str(event.get("name", "Host")).left(24)
			status = "Searching for testers… You are discoverable while co-op is open."
		"searching": status = "Discovery active. Waiting for other testers to open co-op."
		"peer":
			peers[key] = {"name": str(event.get("name", "Fufu")).left(24), "hosting": false, "busy": false}
			_send_presence(key)
		"left":
			peers.erase(key)
			if key == _pending:
				status = "Connection interrupted. Waiting for your friend to reconnect…"
			if key == host_key and not hosting:
				_reset_session("Connection interrupted. Reconnecting to your friend…")
				_pending = key
				_timeout = 20
				_retry_clock = 0
			elif hosting and key in members:
				members.erase(key)
				_broadcast_roster()
		"packet":
			if peers.has(key) and event.get("data") is Dictionary:
				_packet(key, event.data)
				if event.data.get("type") in ["input", "snapshot", "ready", "ping", "pong", "chat_text", "chat_voice"]: return
		"error":
			_reset_session(str(event.get("message", "Connection failed.")))
			peers.clear()
			local_key = ""
	changed.emit()

func create_room() -> void:
	if local_key.is_empty() or not host_key.is_empty() or not _pending.is_empty(): return
	hosting = true
	host_key = local_key
	epoch = Crypto.new().generate_random_bytes(16).hex_encode()
	members = [] if dedicated else [local_key]
	names = {local_key: local_name}
	status = "Your meadow is open · up to 4 testers. Start exploring now; friends can join later."
	_presence()
	changed.emit()

func join_room(key: String) -> void:
	if not host_key.is_empty() or not _pending.is_empty() or not peers.has(key): return
	_pending = key
	_timeout = 20
	_retry_clock = 0
	status = "Connecting to %s…" % peers[key].name
	send_packet.call(key, {"type": "join", "version": GAME_VERSION})
	changed.emit()

func pending_host() -> String:
	return _pending

func begin() -> void:
	if not hosting or (members.is_empty() and not dedicated) or playing: return
	playing = true
	for key: String in members:
		if key != local_key: send_packet.call(key, {"type": "begin", "epoch": epoch})
	_presence()
	started.emit(true, members.duplicate(), local_key)

func send_game(key: String, data: Dictionary) -> void:
	if not playing or (key not in members and key != host_key): return
	data["epoch"] = epoch
	send_packet.call(key, data)

func leave(reason: String = "You left the meadow.") -> void:
	if dedicated and not hosting and not host_key.is_empty():
		send_packet.call(host_key, {"type": "leave", "epoch": epoch})
	for key: String in members:
		if key != local_key: send_packet.call(key, {"type": "leave", "epoch": epoch})
	_reset_session(reason)
	_presence()
	changed.emit()

func _packet(key: String, data: Dictionary) -> void:
	match data.get("type"):
		"presence":
			peers[key].hosting = data.get("hosting") == true
			peers[key].busy = data.get("busy") == true
		"join":
			if not hosting or (members.size() >= 4 and key not in members) or data.get("version") != GAME_VERSION or (admission.is_valid() and not admission.call(key)):
				send_packet.call(key, {"type": "reject"})
				return
			if key not in members: members.append(key)
			_broadcast_roster()
			status = "%d / 4 beans gathered. Ready when you are." % members.size()
		"welcome":
			if key != _pending and key != host_key: return
			if not data.get("members") is Array or data.members.size() > 4 or data.members.size() < 1: return
			if not data.get("dedicated", false) is bool: return
			if (key not in data.members and not data.get("dedicated", false)) or local_key not in data.members: return
			if data.get("dedicated", false) and key in data.members: return
			for member: Variant in data.members:
				if not ExplorationProtocol.key(member) or data.members.count(member) != 1: return
			if not data.get("epoch") is String or data.epoch.length() != 32: return
			if not data.get("names") is Dictionary or data.names.size() > 4 or not data.get("playing") is bool: return
			for member: Variant in data.names:
				if member not in data.members or not data.names[member] is String or data.names[member].length() > 24: return
			dedicated = data.get("dedicated", false)
			names = data.names
			host_key = key
			epoch = data.epoch
			members = data.members
			_pending = ""
			status = "Connected · %d beans in the meadow. Waiting for the host to start." % members.size()
			if data.playing and not playing:
				playing = true
				started.emit(false, members.duplicate(), local_key)
		"reject":
			if key == _pending:
				_pending = ""
				status = "This meadow is full, unavailable, or running a different game version."
		"begin":
			if key != host_key or hosting or playing or data.get("epoch") != epoch: return
			playing = true
			_presence()
			started.emit(false, members.duplicate(), local_key)
		"leave":
			if data.get("epoch") != epoch: return
			if key == host_key and not hosting: _reset_session("The host closed the meadow.")
			elif hosting and key in members:
				members.erase(key)
				_broadcast_roster()
		"removed":
			if key == host_key and not hosting and data.get("epoch") == epoch:
				_reset_session(str(data.get("reason", "The host ended this connection.")).left(160))
				_presence()
		"input", "snapshot", "ready", "ping", "pong", "chat_text", "chat_voice", "inventory_transfer", "shop_result", "farm_action", "farm_result":
			if playing and (key in members or key == host_key) and data.get("epoch") == epoch:
				gameplay_packet.emit(key, data)

func _broadcast_roster() -> void:
	if not hosting: return
	names.clear()
	for key: String in members: names[key] = local_name if key == local_key else str(peers.get(key, {}).get("name", "Fufu"))
	for key: String in members:
		if key != local_key: send_packet.call(key, {"type": "welcome", "epoch": epoch, "members": members, "names": names, "playing": playing, "dedicated": dedicated})

func _send_presence(key: String) -> void:
	send_packet.call(key, {"type": "presence", "hosting": hosting, "busy": playing or (not host_key.is_empty() and not hosting)})

func _presence() -> void:
	for key: String in peers: _send_presence(key)

func _process(delta: float) -> void:
	_presence_clock += delta
	if _presence_clock >= 5:
		_presence_clock = 0
		_presence()
	if _pending.is_empty(): return
	_timeout -= delta
	_retry_clock += delta
	if _timeout <= 0:
		_pending = ""
		status = "Could not reach your friend. Ask them to keep their meadow open, then try Join meadow again."
		changed.emit()
	elif _retry_clock >= 2 and peers.has(_pending) and peers[_pending].hosting:
		_retry_clock = 0
		send_packet.call(_pending, {"type": "join", "version": GAME_VERSION})

func _reset_session(reason: String) -> void:
	var was_playing := playing
	admission = Callable()
	hosting = false
	playing = false
	host_key = ""
	epoch = ""
	members.clear()
	_pending = ""
	status = reason
	if was_playing: ended.emit(reason)

func disconnect_member(key: String, reason: String) -> void:
	if not hosting or key == local_key or key not in members: return
	send_packet.call(key, {"type": "removed", "epoch": epoch, "reason": reason.left(160)})
	members.erase(key)
	_broadcast_roster()
	changed.emit()

func clear_discovery() -> void:
	peers.clear()
	names.clear()
	local_key = ""
	local_name = "Host"
	_presence_clock = 0
	changed.emit()

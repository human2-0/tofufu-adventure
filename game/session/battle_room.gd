class_name BattleRoom
extends Node
## Separate 20-seat lobby; the four-player adventure contract stays unchanged.

signal changed
signal started
signal running
signal ended(reason: String)
signal gameplay(key: String, packet: Dictionary)

var send_packet: Callable
var send_batch: Callable
var local_key: String = ""
var host_key: String = ""
var epoch: String = ""
var nickname: String = "Tofufu"
var skin: int = 0
var phase: String = "idle"
var status: String = ""
var members: Array = []
var peers: Dictionary = {}
var offers: Dictionary = {}
var ready_members: Dictionary = {}
var connected: Dictionary = {}
var auto_queue: bool = false
var offline: bool = false
var target_host: String = ""
var clock: float = 0
var deadline: float = 0
var _pulse: float = 0
var _rates: Dictionary = {}
var _join_retry: float = 0
var term: int = 0
var migration := BattleMigration.new()
var options: Array = [19, BattleOptions.NORMAL]

func _init() -> void:
	migration.room = self

func authority() -> bool:
	return not local_key.is_empty() and local_key == host_key

func receive(event: Dictionary) -> void:
	match event.get("type"):
		"ready":
			local_key = str(event.key)
			phase = "finding" if not target_host.is_empty() else ("search" if auto_queue else "idle")
			deadline = clock + (20 if phase == "finding" else 6)
			status = "Finding reachable Battle Royale players…"
		"peer":
			if not BattleProtocol.key(event.get("key")): return
			peers[event.key] = str(event.get("name", "Tofufu")).left(24)
			connected[event.key] = true
			advertise(str(event.key))
		"left":
			var key := str(event.get("key", ""))
			peers.erase(key)
			offers.erase(key)
			connected.erase(key)
			if phase == "recovering": migration.departed(key)
			if key == host_key: authority_lost()
			elif authority() and phase == "waiting":
				for row: Dictionary in members.duplicate():
					if row.key == key: members.erase(row)
				broadcast_roster()
		"packet":
			if event.get("data") is Dictionary: BattleRoomMessages.receive(self, str(event.get("key", "")), event.data)
			return # Gameplay traffic does not rebuild a hidden lobby.
		"error": finish(str(event.get("message", "Connection failed.")))
	changed.emit()

func host() -> void:
	if local_key.is_empty() or not host_key.is_empty(): return
	host_key = local_key
	epoch = Crypto.new().generate_random_bytes(12).hex_encode()
	members = [{"key": local_key, "name": nickname.left(24), "skin": skin}]
	connected[local_key] = true
	phase = "waiting"
	deadline = clock + 30
	status = "Waiting for players · Choose CPUs or invite friends"
	changed.emit()

func join(key: String) -> void:
	if not BattleProtocol.key(key) or key == local_key or not peers.has(key): return
	if not host_key.is_empty() and host_key != key: return
	target_host = key
	phase = "joining"
	deadline = clock + 20
	_request_join()

func _request_join() -> void:
	_join_retry = clock + 2
	send(target_host, {"kind": "br_join", "v": BattleProtocol.VERSION, "build": BattleProtocol.BUILD, "skin": skin, "duos": BattleOptions.duos(options)})

func configure(value: Array) -> void:
	if not authority() or phase != "waiting" or not BattleOptions.valid(value): return
	options = BattleOptions.canonical(value)
	offers.clear()
	broadcast_roster()

func begin() -> void:
	if not authority() or phase != "waiting": return
	if not BattleOptions.playable(options, members.size()):
		if status == BattleOptions.minimum_message(options): return
		status = BattleOptions.minimum_message(options)
		changed.emit()
		return
	phase = "loading"
	deadline = clock + 120
	for key: String in peers: advertise(key)
	broadcast_roster()
	started.emit()

func loaded() -> void:
	if phase != "loading": return
	ready_members[local_key] = true
	if not authority(): send(host_key, {"kind": "br_ready", "epoch": epoch})
	_try_running()

func _try_running() -> void:
	if not authority() or phase != "loading": return
	for row: Dictionary in members:
		if not ready_members.has(row.key) and connected.has(row.key) and clock < deadline: return
	phase = "playing"
	for row: Dictionary in members:
		if not ready_members.has(row.key): connected.erase(row.key)
	broadcast({"kind": "br_go", "epoch": epoch})
	running.emit()
	changed.emit()

func practice() -> void:
	offline = true
	local_key = "0".repeat(64)
	host()
	begin()

func send(key: String, packet: Dictionary) -> void:
	if send_packet.is_valid() and key != local_key: send_packet.call(key, packet)

func broadcast(packet: Dictionary) -> void:
	var recipients: Array[String] = []
	for row: Dictionary in members:
		if row.key != local_key and connected.has(row.key): recipients.append(str(row.key))
	if send_batch.is_valid(): send_batch.call(recipients, packet)
	else:
		for key: String in recipients: send(key, packet)

func broadcast_roster() -> void:
	broadcast({"kind": "br_roster", "v": BattleProtocol.VERSION, "build": BattleProtocol.BUILD, "epoch": epoch, "members": members, "phase": phase, "options": options})
	changed.emit()

func advertise(key: String) -> void:
	send(key, {"kind": "br_offer", "v": BattleProtocol.VERSION, "build": BattleProtocol.BUILD, "open": authority() and phase == "waiting", "count": members.size(), "duos": BattleOptions.duos(options)})

func finish(reason: String) -> void:
	if phase == "ended": return
	phase = "ended"
	status = reason
	ended.emit(reason)
	changed.emit()

func authority_lost() -> void:
	if phase == "playing": migration.start()
	elif phase != "recovering": finish("The match authority disconnected. Return to the lobby to play again.")

func _process(delta: float) -> void:
	clock += delta
	migration.step(delta)
	_pulse += delta
	if _pulse >= 1:
		_pulse = 0
		_rates.clear()
		if not offline and phase in ["idle", "search", "waiting", "joining", "finding"]:
			for key: String in peers: advertise(key)
	if phase == "search" and clock >= deadline:
		var candidates: Array = offers.keys()
		candidates.sort()
		if not candidates.is_empty(): join(str(candidates[0]))
		else: host()
	elif phase in ["connecting", "finding"] and clock >= deadline:
		finish("Could not join this match. Retry discovery or use CPU practice.")
	elif phase == "joining":
		if clock >= deadline: finish("Could not join this match. Retry discovery or use CPU practice.")
		elif clock >= _join_retry: _request_join()
	elif phase == "waiting" and authority():
		if auto_queue and members.size() == 1:
			for key: String in offers:
				if key < local_key:
					host_key = ""
					epoch = ""
					members.clear()
					join(key)
					return
		if (auto_queue and clock >= deadline) or members.size() == 20: begin()
	elif phase == "loading":
		_try_running()
		if not authority() and clock > deadline: finish("Match loading timed out. Return to the lobby and retry.")

class_name CoopConnectionHealth
extends Node
## Samples real server tick throughput and sends bounded health display values.

var session: CoopSession
var tick_hz: float = 0
var _ticks: int = 0
var _since: int = Time.get_ticks_msec()

func _ready() -> void:
	session.room.gameplay_packet.connect(_packet)

func _physics_process(_delta: float) -> void:
	if not session.authority: return
	_ticks += 1
	var now := Time.get_ticks_msec()
	var elapsed := now - _since
	if elapsed < 1000: return
	tick_hz = minf(120, float(_ticks) * 1000 / elapsed)
	_ticks = 0
	_since = now
	for key: String in session.room.members:
		if session._ready_peers.has(key): session.room.send_game(key, {"type": "server_health", "hz": tick_hz})

func _packet(key: String, data: Dictionary) -> void:
	if not session.authority and key == session.room.host_key and data.get("type") == "server_health":
		if ExplorationProtocol.number(data.get("hz"), 120) and data.hz >= 0: tick_hz = data.hz

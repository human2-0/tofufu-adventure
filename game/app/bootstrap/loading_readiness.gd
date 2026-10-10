class_name LoadingReadiness
extends Node
## Retains bounded authenticated readiness while the host world is still loading.
var room: PlaytestRoom
var loader: AdventureLoader
var _pending: Dictionary[String, String] = {}

func _ready() -> void:
	room.gameplay_packet.connect(_record)
	room.ended.connect(func(_reason: String) -> void: _pending.clear())

func _record(key: String, data: Dictionary) -> void:
	if not loader.busy or not room.hosting or key not in room.members: return
	if data.get("type") != "ready" or data.get("epoch") != room.epoch: return
	if not _pending.has(key) and _pending.size() >= 4: return
	_pending[key] = room.epoch

func replay(session: CoopSession) -> void:
	for key: String in _pending:
		if key in room.members and _pending[key] == room.epoch:
			session._packet(key, {"type": "ready"})
	_pending.clear()

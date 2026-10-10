extends SessionTransport
## In-memory discovery for UI tests and previews. No child process or network.
var starts: int = 0
var active: bool = false
var announce_ready: bool = true
var nickname: String = ""
var key: String = "a".repeat(64)
var packets: Array[Dictionary] = []

func start(display_name: String) -> void:
	starts += 1
	active = true
	nickname = display_name
	if announce_ready: event_received.emit({"type": "ready", "key": key, "name": nickname})

func send_packet(target: String, data: Dictionary) -> void:
	packets.append({"key": target, "data": data.duplicate(true)})

func close() -> void:
	active = false

func is_closed() -> bool:
	return not active

static func inject(app: Node) -> SessionTransport:
	app.get_node("Transport").free()
	var fake: SessionTransport = load("res://tests/lobby_test_transport.gd").new()
	app.add_child(fake)
	app.transport = fake
	return fake

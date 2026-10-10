class_name SessionConnection
extends Node
## Wires a transport to room rules; owns discovery and disconnect lifecycle.

var transport: SessionTransport
var room: PlaytestRoom
var discovering: bool = false
var failed: bool = false
var _stopping: bool = false

func _ready() -> void:
	room.send_packet = transport.send_packet
	transport.event_received.connect(_receive)

func select_transport(next: SessionTransport) -> void:
	if next == transport: return
	await shutdown()
	transport.event_received.disconnect(_receive)
	transport = next
	room.send_packet = transport.send_packet
	transport.event_received.connect(_receive)
	room.status = "Open co-op to find friends."

func ensure_discovery(display_name: String) -> void:
	if _stopping or discovering or not room.local_key.is_empty() or failed: return
	discover(display_name)

func discover(display_name: String) -> void:
	disconnect_session()
	discovering = true
	failed = false
	room.status = "Connecting to friends…" if transport.can_host() else "Connecting to server…"
	room.changed.emit()
	transport.start(display_name)

func _receive(event: Dictionary) -> void:
	if event.get("type") == "error":
		discovering = false
		failed = true
	room.receive(event)

func disconnect_session() -> void:
	_stopping = true
	discovering = false
	failed = false
	room.leave()
	transport.close()
	room.dedicated = false
	room.clear_discovery()
	_stopping = false

func shutdown() -> void:
	disconnect_session()
	_stopping = true
	await transport.shutdown()
	_stopping = false

func _exit_tree() -> void:
	if transport.event_received.is_connected(_receive):
		transport.event_received.disconnect(_receive)
	room.send_packet = Callable()
	transport.close()

class_name SessionConnection
extends Node
## Wires a transport to room rules; owns discovery and disconnect lifecycle.

var transport: SessionTransport
var room: PlaytestRoom

func _ready() -> void:
	room.send_packet = transport.send_packet
	transport.event_received.connect(room.receive)

func discover(display_name: String) -> void:
	disconnect_session()
	room.status = "Starting %s…" % transport.backend_name()
	room.changed.emit()
	transport.start(display_name)

func disconnect_session() -> void:
	room.leave()
	transport.close()
	room.clear_discovery()

func shutdown() -> void:
	disconnect_session()
	await transport.shutdown()

func _exit_tree() -> void:
	if transport.event_received.is_connected(room.receive):
		transport.event_received.disconnect(room.receive)
	room.send_packet = Callable()
	transport.close()

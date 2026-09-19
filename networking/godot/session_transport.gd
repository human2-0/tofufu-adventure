@abstract
class_name SessionTransport
extends Node
## Substitutable discovery + reliable, ordered, authenticated message delivery.
## See COOP.md N1a for event schemas, identity and lifecycle requirements.
## Implementations own bounded queues, connection deadlines and resource cleanup.

signal event_received(event: Dictionary)

@abstract
func start(display_name: String) -> void

@abstract
func send_packet(key: String, data: Dictionary) -> void

## Idempotent; immediately stop events/delivery, then retire owned resources.
@abstract
func close() -> void

## True only when all connections and background resources have stopped.
@abstract
func is_closed() -> bool

func shutdown() -> void:
	close()
	while not is_closed():
		await get_tree().process_frame

func backend_name() -> String:
	return "Co-op"

func discovery_description() -> String:
	return "Discover other players using the configured co-op service. Leaving co-op stops discovery."

func can_host() -> bool:
	return true

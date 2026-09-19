class_name OracleSocketLink
extends RefCounted
## Bounded JSON WebSocket connection; never decodes Godot objects.

var socket := WebSocketPeer.new()
var stream: StreamPeerTCP
var key: String = ""
var created: int = Time.get_ticks_msec()
var sent_auth: bool = false
var _last_received: int = Time.get_ticks_msec()
var _ping: int = Time.get_ticks_msec()
var _window: int = Time.get_ticks_msec()
var _count: int = 0
var _bytes: int = 0
var _blocked: int = 0

func _init() -> void:
	socket.inbound_buffer_size = 262144
	socket.outbound_buffer_size = 262144
	socket.max_queued_packets = 256
	socket.heartbeat_interval = 5

func poll() -> bool:
	socket.poll()
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN: socket.set_no_delay(true)
	var now := Time.get_ticks_msec()
	if key.is_empty() and now - created > 10000: return false
	if now - _last_received > 20000: return false
	if not key.is_empty() and now - _ping >= 5000:
		_ping = now
		if not send({"_oracle_ping": true}): return false
	if socket.get_current_outbound_buffered_amount() > 131072:
		if _blocked == 0: _blocked = now
		if now - _blocked > 3000: return false
	else: _blocked = 0
	return socket.get_ready_state() in [WebSocketPeer.STATE_CONNECTING, WebSocketPeer.STATE_OPEN]

func receive() -> Dictionary:
	var bytes := socket.get_packet()
	_last_received = Time.get_ticks_msec()
	var now := Time.get_ticks_msec()
	if now - _window >= 1000:
		_window = now
		_count = 0
		_bytes = 0
	_count += 1
	_bytes += bytes.size()
	if bytes.size() > 65536 or _count > 240 or _bytes > 4194304: return {}
	var parser := JSON.new()
	if parser.parse(bytes.get_string_from_utf8()) != OK: return {}
	return parser.data if parser.data is Dictionary else {}

func send(data: Dictionary) -> bool:
	var bytes := JSON.stringify(data).to_utf8_buffer()
	if bytes.size() > 65536 or socket.get_ready_state() != WebSocketPeer.STATE_OPEN: return false
	if socket.get_current_outbound_buffered_amount() + bytes.size() > 262144: return false
	return socket.put_packet(bytes) == OK

func close() -> void:
	socket.close(-1)
	if stream != null: stream.disconnect_from_host()

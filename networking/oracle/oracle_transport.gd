class_name OracleTransport
extends SessionTransport
## Explicit dedicated connection. Public traffic uses Caddy TLS; listener is loopback only.

@export var server_mode: bool = false
@export var endpoint: String = ""
@export var credential_file: String = "user://oracle-client.json"
var port: int = 9080
var credentials: Dictionary = {} # Injected by tests or read from the private config file.
var _listener := TCPServer.new()
var _links: Array[OracleSocketLink] = []
var _key: String = ""
var _name: String = ""
var _active: bool = false

func backend_name() -> String:
	return "Dedicated meadow"

func discovery_description() -> String:
	return "Connect to the dedicated meadow, then choose Join meadow. The server keeps the adventure and saves everyone’s progress."

func start(display_name: String) -> void:
	close()
	_name = display_name.left(24)
	var config_env := "TOFUFU_SERVER_CONFIG" if server_mode else "TOFUFU_CLIENT_CONFIG"
	if OS.has_environment(config_env) and credential_file in ["user://oracle-client.json", "/etc/tofufu/server.json"]:
		credential_file = OS.get_environment(config_env)
	if server_mode and OS.has_environment("TOFUFU_SERVER_PORT"):
		var setting := OS.get_environment("TOFUFU_SERVER_PORT")
		if not setting.is_valid_int() or int(setting) < 1 or int(setting) > 65535:
			_fail("Server port must be between 1 and 65535.")
			return
		port = int(setting)
	if credentials.is_empty():
		var file := FileAccess.open(credential_file, FileAccess.READ)
		if file != null and file.get_length() <= 16384:
			var parser := JSON.new()
			if parser.parse(file.get_as_text()) == OK and parser.data is Dictionary: credentials = parser.data
	if server_mode:
		if not _valid_server_config():
			_fail("Invalid Oracle server configuration.")
			return
		_key = str(credentials.server_id)
		if _listener.listen(port, "127.0.0.1") != OK:
			_fail("Could not listen on the Oracle port.")
			return
		_active = true
		event_received.emit({"type": "ready", "key": _key, "name": _name})
	else:
		endpoint = str(credentials.get("endpoint", endpoint))
		if not _hex_key(credentials.get("token")) or not (endpoint.begins_with("wss://") or endpoint.begins_with("ws://127.0.0.1:")):
			_fail("Choose a valid player connection file, then reconnect.")
			return
		var link := OracleSocketLink.new()
		if link.socket.connect_to_url(endpoint) != OK:
			_fail("Could not connect to the dedicated meadow.")
			return
		_links.append(link)
		_active = true

func _process(_delta: float) -> void:
	_poll()

func _physics_process(_delta: float) -> void:
	_poll()

func _poll() -> void:
	if not _active: return
	if server_mode and _listener.is_connection_available():
		var stream := _listener.take_connection()
		if _links.size() >= 16: stream.disconnect_from_host()
		else:
			stream.set_no_delay(true)
			var link := OracleSocketLink.new()
			link.stream = stream
			if link.socket.accept_stream(stream) == OK: _links.append(link)
	for link: OracleSocketLink in _links.duplicate():
		if not _active: return
		if not link.poll():
			_drop(link)
			continue
		if not server_mode and not link.sent_auth and link.socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
			link.sent_auth = true
			if not link.send({"auth": credentials.token, "name": _name}):
				_drop(link)
				continue
		while _active and link in _links and link.socket.get_available_packet_count() > 0:
			var data := link.receive()
			if data.is_empty():
				_drop(link)
				break
			if link.key.is_empty(): _authenticate(link, data)
			elif data.get("_oracle_ping") == true:
				if not link.send({"_oracle_pong": true}): _drop(link)
			elif data.get("_oracle_pong") == true: pass
			else: event_received.emit({"type": "packet", "key": link.key, "data": data})

func _authenticate(link: OracleSocketLink, data: Dictionary) -> void:
	if server_mode:
		var token: Variant = data.get("auth")
		if not _hex_key(token) or not credentials.players.has(str(token).sha256_text()) or not data.get("name") is String:
			_drop(link)
			return
		var identity := str(token).sha256_text()
		for other: OracleSocketLink in _links:
			if other.key == identity:
				_drop(link)
				return
		link.key = identity
		if not link.send({"server": _key, "identity": identity, "name": _name}):
			_drop(link)
			return
		event_received.emit({"type": "peer", "key": identity, "name": str(data.name).left(24)})
	else:
		if not _hex_key(data.get("server")) or data.get("identity") != str(credentials.token).sha256_text():
			_drop(link)
			return
		_key = str(data.identity)
		link.key = str(data.server)
		event_received.emit({"type": "ready", "key": _key, "name": _name})
		event_received.emit({"type": "peer", "key": link.key, "name": str(data.get("name", "Oracle meadow")).left(24)})

func send_packet(key: String, data: Dictionary) -> void:
	for link: OracleSocketLink in _links:
		if link.key == key:
			if not link.send(data): _drop(link)
			return

func _drop(link: OracleSocketLink) -> void:
	_links.erase(link)
	link.close()
	if not server_mode:
		_fail("Server connection closed. Reconnect to the meadow; an update may be in progress.")
	elif not link.key.is_empty(): event_received.emit({"type": "left", "key": link.key})

func _fail(message: String) -> void:
	close()
	event_received.emit({"type": "error", "message": message})

func close() -> void:
	_active = false
	_listener.stop()
	for link: OracleSocketLink in _links: link.close()
	_links.clear()
	_key = ""

func is_closed() -> bool:
	return not _active and _links.is_empty() and not _listener.is_listening()

func _exit_tree() -> void:
	close()

func _valid_server_config() -> bool:
	if not _hex_key(credentials.get("server_id")) or not credentials.get("players") is Array: return false
	if credentials.players.is_empty() or credentials.players.size() > 32: return false
	for identity: Variant in credentials.players:
		if not _hex_key(identity) or identity == credentials.server_id: return false
	return true

func _hex_key(value: Variant) -> bool:
	if not value is String or value.length() != 64: return false
	for character: String in value:
		if character not in "0123456789abcdef": return false
	return true

func can_host() -> bool:
	return false

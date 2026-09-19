class_name HolepunchTransport
extends SessionTransport
## Process supervision + authenticated bounded loopback IPC. No actor knowledge.

var identity_path: String = "user://peer-identity.key"
var _server := TCPServer.new()
var _socket: StreamPeerTCP
var _child: Dictionary = {}
var _token: String
var _buffer := PackedByteArray()
var _authenticated: bool = false
var _deadline: float = 0.0
var _active: bool = false
var _retiring: Array[Dictionary] = []
var _frames: int = 0
var _rate_window: float = 0.0

func _enter_tree() -> void:
	process_physics_priority = -100

func start(display_name: String) -> void:
	close()
	var script := ProjectSettings.globalize_path("res://networking/sidecar/src/index.cjs")
	if OS.has_feature("standalone"):
		script = OS.get_executable_path().get_base_dir().path_join("networking/sidecar/src/index.cjs")
	if not FileAccess.file_exists(script):
		_fail("The Holepunch runtime is not installed with this build.")
		return
	var node := OS.get_environment("TOFUFU_NODE_BIN")
	if node.is_empty():
		var candidates := [OS.get_executable_path().get_base_dir().path_join("node"), "/opt/homebrew/bin/node", "/usr/local/bin/node"]
		for folder in OS.get_environment("PATH").split(";" if OS.get_name() == "Windows" else ":"):
			candidates.append(folder.path_join("node.exe" if OS.get_name() == "Windows" else "node"))
		var nvm := OS.get_environment("HOME").path_join(".nvm/versions/node")
		if DirAccess.dir_exists_absolute(nvm):
			var versions := DirAccess.get_directories_at(nvm)
			versions.sort()
			versions.reverse()
			for version in versions:
				if version.begins_with("v") and int(version.substr(1).get_slice(".", 0)) >= 22:
					candidates.append(nvm.path_join(version).path_join("bin/node"))
		for candidate in candidates:
			if FileAccess.file_exists(candidate):
				node = candidate
				break
	if node.is_empty():
		_fail("Node.js 22+ is required for this co-op playtest. Set TOFUFU_NODE_BIN to its executable.")
		return
	if _server.listen(0, "127.0.0.1") != OK:
		_fail("Could not open the local Holepunch bridge.")
		return
	_token = Crypto.new().generate_random_bytes(32).hex_encode()
	_child = OS.execute_with_pipe(node, [script], false)
	if _child.is_empty():
		_fail("Could not launch the Holepunch runtime.")
		return
	var pipe: FileAccess = _child.stdio
	pipe.store_string(JSON.stringify({"port": _server.get_local_port(), "token": _token, "name": display_name, "identity": ProjectSettings.globalize_path(identity_path)}) + "\n")
	_deadline = Time.get_ticks_msec() / 1000.0 + 12
	_active = true

func send_packet(key: String, data: Dictionary) -> void:
	_send({"type": "send", "key": key, "data": data})

func _send(value: Dictionary) -> void:
	if _socket == null or not _authenticated:
		return
	var bytes := JSON.stringify(value).to_utf8_buffer()
	if bytes.size() > 65536:
		_fail("A network message exceeded the playtest limit.")
		return
	var frame := PackedByteArray()
	frame.resize(4)
	frame.encode_u32(0, bytes.size())
	frame.reverse()
	frame.append_array(bytes)
	var sent := _socket.put_partial_data(frame)
	if sent[0] != OK or sent[1] != frame.size():
		_fail("Connection is too slow. Please reconnect.")

func _process(_delta: float) -> void:
	_reap()
	if not _active: return
	var now := Time.get_ticks_msec() / 1000.0
	if now - _rate_window >= 1:
		_rate_window = now
		_frames = 0
	if not _authenticated and now > _deadline:
		_fail("Holepunch startup timed out. Check the runtime and retry.")
		return
	if not OS.is_process_running(int(_child.get("pid", -1))):
		_fail("The Holepunch runtime stopped. Retry discovery.")
		return
	if _socket == null and _server.is_connection_available():
		_socket = _server.take_connection()
		_socket.set_no_delay(true)
		_server.stop()
	if _socket == null: return
	_socket.poll()
	if _socket.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		_fail("The local peer connection closed.")
		return
	var available := _socket.get_available_bytes()
	if _buffer.size() + available > 262144:
		_fail("Network queue limit exceeded.")
		return
	if available > 0:
		var result := _socket.get_data(available)
		if result[0] != OK:
			_fail("Could not read the peer connection.")
			return
		_buffer.append_array(result[1])
	while _buffer.size() >= 4:
		var header := _buffer.slice(0, 4)
		header.reverse()
		var length := header.decode_u32(0)
		if length == 0 or length > 65536:
			_fail("Invalid network frame.")
			return
		if _buffer.size() < length + 4: break
		var value: Variant = JSON.parse_string(_buffer.slice(4, length + 4).get_string_from_utf8())
		_buffer = _buffer.slice(length + 4)
		_frames += 1
		if not value is Dictionary or _frames > 600:
			_fail("Invalid network message or excessive traffic.")
			return
		if not _authenticated:
			if value.get("type") != "auth" or value.get("token") != _token:
				_fail("Local bridge authentication failed.")
				return
			_authenticated = true
			_token = ""
		else:
			event_received.emit(value)

func close() -> void:
	if _socket != null:
		_send({"type": "close"})
		_socket.disconnect_from_host()
	_socket = null
	_server.stop()
	if not _child.is_empty():
		var pid := int(_child.get("pid", -1))
		if pid > 0:
			_retiring.append({"pid": pid, "deadline": Time.get_ticks_msec() + 2000, "handles": _child})
		_child = {}
	_active = false
	_authenticated = false
	_buffer.clear()
	_token = ""

func _fail(message: String) -> void:
	close()
	event_received.emit({"type": "error", "message": message})

func _reap(force: bool = false) -> void:
	for child: Dictionary in _retiring.duplicate():
		if not OS.is_process_running(child.pid):
			_retiring.erase(child)
		elif force or Time.get_ticks_msec() > child.deadline:
			OS.kill(child.pid)
			_retiring.erase(child)

func _exit_tree() -> void:
	close()
	_reap(true)

func is_closed() -> bool:
	return not _active and _retiring.is_empty()

func backend_name() -> String:
	return "Holepunch"

func discovery_description() -> String:
	return "Public test meadow · Discover reachable testers through Holepunch after they enable discovery. Some networks may block direct connections. Leaving co-op stops discovery. No account needed."

func _physics_process(delta: float) -> void:
	_process(delta)

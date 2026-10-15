extends SceneTree
## Oversized exploration stays inside existing transport frames and applies atomically.

class MapSink extends RefCounted:
	var mask: String = ""
	var calls: int = 0
	func restore_exploration(value: String) -> void:
		mask = value
		calls += 1

class MapGame extends Node3D:
	var map := MapSink.new()

var failures: int = 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	var host := "a".repeat(64)
	var guest := "b".repeat(64)
	var sender := CoopPersonalMaps.new()
	var receiver := CoopPersonalMaps.new()
	var authority := CoopSession.new()
	authority.authority = true
	authority.room = PlaytestRoom.new()
	authority.room.playing = true
	authority.room.hosting = true
	authority.room.local_key = host
	authority.room.host_key = host
	authority.room.epoch = "c".repeat(32)
	authority.room.members = [host, guest]
	var packets: Array[Dictionary] = []
	authority.room.send_packet = func(_key: String, data: Dictionary) -> void: packets.append(data.duplicate(true))
	sender.session = authority
	var map := MapExploration.new()
	map.reveal(Vector2(-930, 0))
	sender.maps[guest] = map
	sender._send_map(guest)
	check(packets.size() == 2, "expanded mask splits into exactly two bounded parts")
	for packet in packets:
		var envelope := {"type": "send", "key": guest, "data": packet}
		check(JSON.stringify(envelope).to_utf8_buffer().size() < 65536, "framed map part retains the existing transport cap")
	var session := CoopSession.new()
	session.room = PlaytestRoom.new()
	session.room.host_key = host
	var game := MapGame.new()
	session.game = game
	receiver.session = session
	receiver._packet(guest, packets[0])
	check(game.map.calls == 0, "only the authenticated authority supplies exploration")
	receiver._packet(host, packets[1])
	check(game.map.calls == 0, "a partial mask never replaces exploration")
	receiver._packet(host, packets[0])
	check(game.map.calls == 1 and game.map.mask == map.capture(), "out-of-order parts assemble and validate before application")
	receiver._packet(host, packets[0])
	receiver._packet(host, packets[1])
	check(game.map.calls == 1, "replayed completed revisions do not clear discoveries")
	var bad := packets[0].duplicate(true)
	bad.revision += 1
	bad.part = 2
	receiver._packet(host, bad)
	bad.part = 0
	bad.mask = "A".repeat(40001)
	receiver._packet(host, bad)
	check(receiver._incoming_revision == map.revision and game.map.calls == 1, "invalid indices and oversized parts leave state untouched")
	bad = packets[0].duplicate(true)
	bad.revision += 1
	bad.mask = "invalid"
	receiver._packet(host, bad)
	bad = packets[1].duplicate(true)
	bad.revision += 1
	receiver._packet(host, bad)
	check(game.map.calls == 1, "malformed assembled base64 cannot replace exploration")
	var restored := MapExploration.new()
	restored.restore(game.map.mask)
	check(restored.visited(Vector2(-930, 0)), "western discoveries survive the real framed transfer")
	var legacy := PackedByteArray()
	legacy.resize(25440)
	legacy.fill(0)
	receiver._packet(host, {"type": "personal_map", "mask": Marshalls.raw_to_base64(legacy)})
	check(game.map.calls == 2, "legacy single-packet exploration still loads")
	sender.free()
	receiver.free()
	authority.room.free()
	# These sessions never enter the tree, where _ready normally parents both nodes.
	authority.roster.free()
	authority.opening.free()
	authority.free()
	session.room.free()
	session.roster.free()
	session.opening.free()
	session.free()
	game.free()
	print("Personal map transfer: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

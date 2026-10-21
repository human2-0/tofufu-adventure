class_name BattleSquadPings
extends Node
## Short-lived team callouts. Host validates identity/range; no opponent tracking.

var game: BattleRoyaleGame
var _clock: float = 0
var _sequence: int = 0
var _last: Dictionary = {}
var _events: Dictionary = {}
var _markers: Dictionary = {}
var _term: int = -1
var _watch: int = -1
var _locale: String = ""

func _ready() -> void:
	game.room.gameplay.connect(receive)
	_term = game.room.term
	_watch = game.watch_slot

func request(point: Vector3, danger: bool = false) -> void:
	if game.deployment.active() or game.pack_ui.blocked() or game.hud.exit_panel.visible: return
	if game.room.phase != "playing" or game.match_state.winner != -2 or game.match_state.rows[game.local_slot][8] <= 0: return
	_sequence += 1
	var packet := {"kind": "br_ping", "epoch": game.room.epoch, "term": game.room.term, "seq": _sequence, "at": [point.x, point.y, point.z], "danger": danger}
	if game.room.authority(): receive(game.room.local_key, packet)
	else: game.room.send(game.room.host_key, packet)

func receive(key: String, packet: Dictionary) -> void:
	if packet.get("epoch") != game.room.epoch or packet.get("term") != game.room.term or game.room.phase != "playing": return
	if packet.get("kind") == "br_ping" and game.room.authority():
		var slot := -1
		for index in game.room.members.size():
			if game.room.members[index].key == key: slot = index
		if slot < 0 or not game.room.connected.has(key) or game.match_state.rows[slot][8] <= 0: return
		if game.deployment.active() or game.match_state.winner != -2 or not _valid(packet): return
		if int(packet.seq) <= int(_last.get(key, [0, -1.0])[0]) or _clock - float(_last.get(key, [0, -1.0])[1]) < 1: return
		var point := CombatState._vector(packet.at)
		if game.bodies[slot].position.distance_squared_to(point) > 180 * 180: return
		_last[key] = [int(packet.seq), _clock]
		var event := packet.duplicate()
		event.kind = "br_ping_event"
		event.slot = slot
		for index in game.room.members.size():
			if not BattleTeams.allies(game.room.options, slot, index): continue
			var target: String = game.room.members[index].key
			if target == game.room.local_key: _show(event)
			elif game.room.connected.has(target): game.room.send(target, event)
	elif packet.get("kind") == "br_ping_event" and key == game.room.host_key:
		if _valid(packet) and BattleProtocol.integer(packet.get("slot"), 0, game.room.members.size() - 1): _show(packet)

func _valid(packet: Dictionary) -> bool:
	return BattleProtocol.integer(packet.get("seq"), 1, 2147483647) and ExplorationProtocol.vector(packet.get("at"), 3, 1000) and packet.get("danger") is bool

func _show(packet: Dictionary) -> void:
	var slot := int(packet.slot)
	if not BattleTeams.allies(game.room.options, game.local_slot, slot) or int(packet.seq) <= int(_events.get(slot, 0)): return
	_events[slot] = int(packet.seq)
	if _markers.has(slot): (_markers[slot][0] as Label3D).queue_free()
	var label := Label3D.new()
	label.text = _caption(slot, packet.danger)
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	label.modulate = Color("ff6c71") if packet.danger else Color("78e5ef")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.01
	label.font_size = 24
	label.visibility_range_end = 180
	game.add_child(label)
	label.position = CombatState._vector(packet.at) + Vector3.UP * 0.8
	_markers[slot] = [label, _clock + 8, int(packet.danger)]
	_radar()

func _process(delta: float) -> void:
	_clock += delta
	if _locale != TranslationServer.get_locale():
		_locale = TranslationServer.get_locale()
		for slot: int in _markers:
			(_markers[slot][0] as Label3D).text = _caption(slot, _markers[slot][2] == 1)
	if _term != game.room.term or game.room.phase == "recovering":
		clear()
		_term = game.room.term
	if _watch != game.watch_slot:
		clear(false)
		_watch = game.watch_slot
	for slot: int in _markers.keys():
		if _clock >= float(_markers[slot][1]):
			(_markers[slot][0] as Label3D).queue_free()
			_markers.erase(slot)
	_radar()

func clear(reset_sequences: bool = true) -> void:
	for marker: Array in _markers.values(): (marker[0] as Label3D).queue_free()
	_markers.clear()
	if reset_sequences:
		_last.clear()
		_events.clear()
	_radar()

func _radar() -> void:
	var radar := game.hud.radar
	if radar.squad_pings.is_empty() and _markers.is_empty(): return
	radar.squad_pings.clear()
	for marker: Array in _markers.values():
		var point: Vector3 = (marker[0] as Label3D).position
		radar.squad_pings.append(Vector3(point.x, point.z, marker[2]))
	radar.queue_redraw()

func _caption(slot: int, danger: bool) -> String:
	return (tr("Danger · %s") if danger else tr("Go here · %s")) % game.name_of(slot)

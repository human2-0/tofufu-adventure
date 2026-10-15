class_name CoopSnapshotFlow
extends RefCounted
## Publishes live snapshots and keeps decoding out of the session lifecycle.

var channel := SnapshotChannel.new()

func publish(session: CoopSession) -> void:
	if session._ready_peers.is_empty(): return
	var states := {}
	for key: String in session.roster.party: states[key] = session.roster.party[key].capture()
	var snapshot := {"type": "snapshot", "sequence": session._sequence, "actors": states,
		"opening": session.opening.capture(), "duel": session.duel.capture()}
	if session._world_clock >= 0.1 - 0.000001:
		snapshot.world = CoopWorld.capture(session.game)
		session._world_clock = maxf(0.0, session._world_clock - floorf((session._world_clock + 0.000001) / 0.1) * 0.1)
	snapshot = SnapshotPrecision.presentation(snapshot)
	for key: String in session.room.members:
		if key != session.room.local_key and session._ready_peers.has(key):
			session.room.send_game(key, channel.encode(key, snapshot))

func receive(session: CoopSession, packet: Dictionary) -> void:
	var data := channel.decode(packet, session.room.members)
	if data.is_empty(): return
	session._snapshot_sequence = int(data.sequence)
	session._silence = 0
	if not data.has("world") and session._pending.has("world"): data.world = session._pending.world
	session._pending = data

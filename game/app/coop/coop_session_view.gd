class_name CoopSessionView
extends RefCounted
## Formats connection health without deciding simulation outcomes.

static func process(session: CoopSession, delta: float) -> void:
	if session.authority and session.room.dedicated: return
	var mode := "Public" if session.public_mode else "Co-op"
	var label := "%s · %d/4 beans · %s" % [mode, session.room.members.size(), "Host saves" if session.authority else "%d ms RTT" % session.latency_ms]
	if session.room.dedicated:
		label += " · %.0f Hz · Server saves" % session.connection_health.tick_hz
	session.game.hud.show_session(label)
	CoopDuelView.process(session.duel)
	if session.authority: return
	for dummy: PracticeDummy in session.game.encounters.dummy_nodes:
		dummy._figure.rotation.z = lerpf(dummy._figure.rotation.z, 0, minf(1, delta * 9))

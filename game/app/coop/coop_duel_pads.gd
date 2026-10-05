class_name CoopDuelPads
extends RefCounted
## Finds a distinct player on each village tile.

var session: CoopSession

func pair() -> Array[String]:
	var occupants: Array[String] = ["", ""]
	for key: String in session.room.members:
		if not session.roster.party.has(key): continue
		var member: CoopActor = session.roster.party[key]
		if member.health.current <= 0.0: continue
		var pad: int = session.game.world.duel_arena.pad_for(member.actor.global_position)
		if pad >= 0 and occupants[pad].is_empty(): occupants[pad] = key
	var pair: Array[String] = []
	if not occupants[0].is_empty() and not occupants[1].is_empty():
		pair.append(occupants[0])
		pair.append(occupants[1])
	return pair

func contains_pair(participants: Array[String]) -> bool:
	if participants.size() != 2: return false
	for index in 2:
		if not session.roster.party.has(participants[index]): return false
		var member: CoopActor = session.roster.party[participants[index]]
		if session.game.world.duel_arena.pad_for(member.actor.global_position) != index: return false
	return true

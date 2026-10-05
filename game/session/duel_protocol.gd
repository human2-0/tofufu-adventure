class_name DuelProtocol
extends RefCounted
## Bounded match presentation carried inside the existing authoritative snapshot.

const PHASES: Array[String] = ["idle", "entry", "fight", "round", "complete"]

static func valid(data: Variant, members: Array) -> bool:
	if not data is Dictionary or data.get("phase") not in PHASES: return false
	var participants: Variant = data.get("participants")
	if not participants is Array or participants.size() not in [0, 2]: return false
	for key: Variant in participants:
		if not ExplorationProtocol.key(key) or key not in members: return false
	if participants.size() == 2 and participants[0] == participants[1]: return false
	var scores: Variant = data.get("scores")
	if not scores is Array or scores.size() != participants.size(): return false
	for score: Variant in scores:
		if not ExplorationProtocol.sequence(score) or score > 10: return false
	if not ExplorationProtocol.number(data.get("countdown"), 5) or data.countdown < 0: return false
	if not ExplorationProtocol.sequence(data.get("round")): return false
	if not ExplorationProtocol.sequence(data.get("notice_seq")): return false
	if not data.get("notice") is String or data.notice.length() > 100: return false
	var winner: Variant = data.get("winner", "")
	return winner == "" or (ExplorationProtocol.key(winner) and winner in participants)

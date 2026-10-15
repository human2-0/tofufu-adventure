class_name DuelProtocol
extends RefCounted
## Bounded match presentation carried inside the existing authoritative snapshot.

const PHASES: Array[String] = ["idle", "loadout", "entry", "fight", "round", "complete"]

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
	if not ExplorationProtocol.sequence(data.get("match", 0)): return false
	if not ExplorationProtocol.number(data.get("setup_seconds", 0), 60) or data.get("setup_seconds", 0) < 0: return false
	var choices: Variant = data.get("choices", [])
	if not choices is Array or choices.size() not in [0, 2]: return false
	for choice: Variant in choices:
		if not choice is Dictionary or not valid_choice(choice) or not choice.get("ready") is bool: return false
	var winner: Variant = data.get("winner", "")
	return winner == "" or (ExplorationProtocol.key(winner) and winner in participants)

static func valid_choice(data: Dictionary) -> bool:
	return data.get("ranged") in ["soy_gun", "sotjet"] and data.get("melee") in ["", "knife", "edamame_sword", "nori_katana", "sproutwood_staff", "celestial_sword", "celestial_staff"]

static func valid_action(data: Dictionary) -> bool:
	return data.get("action") in ["accept", "leave"] and valid_choice(data) and ExplorationProtocol.sequence(data.get("sequence")) and ExplorationProtocol.sequence(data.get("match"))

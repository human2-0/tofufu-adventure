class_name CastleTrialState
extends RefCounted
## Three finite puzzles and one-time royal reward ownership; no scene dependencies.

const ORDER: Array[int] = [2, 0, 3, 1]
var solved: Array[bool] = [false, false, false]
var lever_bits: int = 0
var sequence_step: int = 0
var dials: Array[int] = [0, 0, 0]
var defeated_guards: int = 0
var introduced: bool = false
var completed: bool = false
var participants: Array[String] = []
var rewarded: Array[String] = []
var revision: int = 0
var message: String = "Restore the three royal wards."
var last_action: int = -1
var accepted: bool = false
var feedback_revision: int = 0
var opened_chests: int = 0
var treasure_claims: Dictionary = {}

func operate(action: int) -> bool:
	if action < 0 or action >= 12: return false
	var deck := action / 4
	var control := action % 4
	if solved[deck]: return false
	last_action = action
	feedback_revision += 1
	accepted = deck != 1 or control == ORDER[sequence_step]
	if deck == 0:
		lever_bits = 0 if control == 3 else lever_bits ^ [3, 6, 7][control]
		solved[0] = lever_bits == 5
		message = "Leave Ash and Crown alight; Tide must sleep."
	elif deck == 1:
		if control == ORDER[sequence_step]:
			sequence_step += 1
		else:
			sequence_step = 0
			message = "The archive forgets a broken order. Read its inscription."
		solved[1] = sequence_step == 4
	else:
		if control < 3: dials[control] = (dials[control] + 1) % 4
		else:
			solved[2] = dials == [1, 2, 3]
			message = "The scales disagree. Ash + Tide + Crown must total six."
	if solved[deck]: message = "Ward restored. Defeat its three guardians to open the royal seal."
	revision += 1
	return true

func treasure_claimed(key: String, chest: int) -> bool:
	return int(treasure_claims.get(key, 0)) & (1 << chest) != 0

func claim_treasure(key: String, chest: int) -> bool:
	if key.is_empty() or chest < 0 or chest >= 12 or treasure_claimed(key, chest): return false
	if not treasure_claims.has(key) and treasure_claims.size() >= 32: return false
	opened_chests |= 1 << chest
	treasure_claims[key] = int(treasure_claims.get(key, 0)) | (1 << chest)
	revision += 1
	return true

func gate_open(deck: int) -> bool:
	return solved[deck] and (defeated_guards >> (deck * 3)) & 7 == 7

func guard_defeated(index: int) -> void:
	if index < 0 or index >= 9 or defeated_guards & (1 << index) != 0: return
	defeated_guards |= 1 << index
	revision += 1
	if gate_open(index / 3): message = "Royal seal released. The return shortcut is now open."

func all_open() -> bool:
	return gate_open(0) and gate_open(1) and gate_open(2)

func capture() -> Dictionary:
	return {"solved": solved.duplicate(), "levers": lever_bits, "sequence": sequence_step,
		"dials": dials.duplicate(), "guards": defeated_guards, "introduced": introduced,
		"completed": completed, "participants": participants.duplicate(),
		"rewarded": rewarded.duplicate(), "revision": revision, "message": message,
		"last_action": last_action, "accepted": accepted, "feedback_revision": feedback_revision, "opened_chests": opened_chests, "treasure_claims": treasure_claims.duplicate()}

func restore(data: Dictionary) -> void:
	for i in 3:
		solved[i] = bool(data.solved[i])
		dials[i] = int(data.dials[i])
	lever_bits = int(data.levers)
	sequence_step = int(data.sequence)
	defeated_guards = int(data.guards)
	introduced = bool(data.introduced)
	completed = bool(data.completed)
	participants.assign(data.participants)
	rewarded.assign(data.rewarded)
	revision = int(data.revision)
	message = str(data.get("message", "Restore the three royal wards."))
	last_action = int(data.get("last_action", -1))
	accepted = bool(data.get("accepted", false))
	feedback_revision = int(data.get("feedback_revision", 0))
	opened_chests = int(data.get("opened_chests", 0))
	treasure_claims = data.get("treasure_claims", {}).duplicate()

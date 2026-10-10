class_name TofuPuzzleCommand
extends RefCounted
## Bounded player intent. Authority derives all puzzle outcomes from its own state.

enum Action { INSPECT, PICK_UP, RETURN_PROP, LOAD_INTAKE, OPEN_TERMINAL, SUBMIT_PASSWORD, POUR, PLACE_STONE, RELEASE_PRESS, START_PRESS, STOP_PRESS, COMMIT_CUTS, PLACE_SLAB, SEAL_SLOT, ABANDON, RESTART, SET_PRESS_PRESET, OPEN_STASH }

const MAX_ID_LENGTH: int = 48
const MAX_PASSWORD_LENGTH: int = 32
const MAX_CUTS: int = 5

var action: Action
var target_id: String = ""
var object_id: String = ""
var run_id: int = 0
var attempt_id: int = 0
var sequence: int = 0
var expected_revision: int = 0
var text: String = ""
var cuts: Array[float] = []

func valid_shape() -> bool:
	if int(action) < 0 or int(action) >= Action.size(): return false
	if target_id.length() > MAX_ID_LENGTH or object_id.length() > MAX_ID_LENGTH: return false
	if run_id < 1 or attempt_id < 1 or sequence < 1 or expected_revision < 0: return false
	if text.length() > MAX_PASSWORD_LENGTH or cuts.size() > MAX_CUTS: return false
	for value: float in cuts:
		if not is_finite(value): return false
	return true

func is_submission() -> bool:
	return action in [Action.LOAD_INTAKE, Action.POUR, Action.RELEASE_PRESS, Action.STOP_PRESS, Action.COMMIT_CUTS]

class_name TofuCutRules
extends RefCounted
## Evaluates an authority-supplied block length and five submitted guide positions.

enum Outcome { INVALID, REJECTED, COMPLETE }

const CUT_COUNT: int = 5
const WIDTH_TOLERANCE: float = 0.05
const MIN_SEPARATION_RATIO: float = 0.05

var revision: int = 0
var block_id: String = ""
var length: float = 0.0
var completed: bool = false
var rejected: bool = false
var widths: Array[float] = []

func issue_block(id: String, block_length: float) -> bool:
	if completed or rejected or not block_id.is_empty() or id.is_empty(): return false
	if not is_finite(block_length) or block_length <= 0.0: return false
	block_id = id
	length = block_length
	revision += 1
	return true

func commit(id: String, cuts: Array[float], expected: int) -> Outcome:
	if completed or rejected or id != block_id or expected != revision: return Outcome.INVALID
	if cuts.size() != CUT_COUNT or length <= 0.0: return Outcome.INVALID
	var target: float = length / 6.0
	var previous: float = 0.0
	var candidate: Array[float] = []
	for cut: float in cuts:
		if not is_finite(cut) or cut <= 0.0 or cut >= length: return Outcome.INVALID
		if cut - previous < target * MIN_SEPARATION_RATIO: return Outcome.INVALID
		candidate.append(cut - previous)
		previous = cut
	if length - previous < target * MIN_SEPARATION_RATIO: return Outcome.INVALID
	candidate.append(length - previous)
	widths = candidate
	for width: float in candidate:
		if width < target * (1.0 - WIDTH_TOLERANCE) - 0.000001 or width > target * (1.0 + WIDTH_TOLERANCE) + 0.000001:
			rejected = true
			revision += 1
			return Outcome.REJECTED
	completed = true
	revision += 1
	return Outcome.COMPLETE

func clear_rejection() -> bool:
	if not rejected: return false
	rejected = false
	block_id = ""
	length = 0.0
	widths.clear()
	revision += 1
	return true

func capture() -> Dictionary:
	return {"revision": revision, "block_id": block_id, "length": length, "completed": completed, "rejected": rejected, "widths": widths.duplicate()}

func restore(data: Dictionary) -> bool:
	if not TofuPuzzleContract.bounded_integer(data.get("revision"), 0, 2147483646): return false
	if not data.get("block_id") is String or data.block_id.length() > 160: return false
	if not data.get("completed", false) is bool or not data.get("rejected", false) is bool: return false
	var saved_length: Variant = data.get("length", -1.0)
	if not (saved_length is float or saved_length is int): return false
	if not is_finite(float(saved_length)) or float(saved_length) < 0.0 or float(saved_length) > 10000.0: return false
	var saved_id: String = data.block_id
	var done: bool = data.get("completed", false)
	var failed: bool = data.get("rejected", false)
	var saved_widths: Variant = data.get("widths", [])
	if done and failed or not saved_widths is Array: return false
	if (saved_id.is_empty() and saved_length != 0.0) or (not saved_id.is_empty() and saved_length <= 0.0): return false
	if (done or failed) and saved_id.is_empty(): return false
	if done and saved_widths.size() != 6: return false
	if failed and saved_widths.size() != 0 and saved_widths.size() != 6: return false
	if not done and not failed and not saved_widths.is_empty(): return false
	var checked: Array[float] = []
	for width: Variant in saved_widths:
		if not width is float and not width is int: return false
		if not is_finite(float(width)) or float(width) <= 0.0: return false
		checked.append(float(width))
	if checked.size() == 6:
		if absf(_sum(checked) - float(saved_length)) > 0.0001: return false
		var accurate: bool = true
		var target: float = float(saved_length) / 6.0
		for width: float in checked:
			if width < target * MIN_SEPARATION_RATIO: return false
			accurate = accurate and width >= target * 0.95 - 0.000001 and width <= target * 1.05 + 0.000001
		if done != accurate: return false
	revision = int(data.revision) + 1
	block_id = saved_id
	length = float(saved_length)
	completed = done
	rejected = failed
	widths = checked
	return true

func _sum(values: Array[float]) -> float:
	var total: float = 0.0
	for value: float in values: total += value
	return total

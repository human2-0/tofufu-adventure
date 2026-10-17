class_name JourneyPractice
extends RefCounted
## Permanent, bounded milestones earned through confirmed play rather than EXP.

const TRACKS: Array[String] = ["trail", "rhythm", "care"]
const STEPS: Dictionary = {"trail": 500, "rhythm": 50, "care": 150}
const NAMES: Dictionary = {"trail": "Trailblazer", "rhythm": "Flowkeeper", "care": "Tenderheart"}
const CAP: int = 5
var totals: Dictionary = {"trail": 0, "rhythm": 0, "care": 0}

static func threshold(track: String, practice_rank: int) -> int:
	return int(int(STEPS.get(track, 1)) * practice_rank * (practice_rank + 1) / 2.0)

func rank(track: String) -> int:
	var result := 0
	while result < CAP and int(totals.get(track, 0)) >= threshold(track, result + 1): result += 1
	return result

func record(track: String, units: int) -> bool:
	if track not in TRACKS or units <= 0: return false
	var next := mini(threshold(track, CAP), int(totals[track]) + mini(units, 100000))
	if next == int(totals[track]): return false
	totals[track] = next
	return true

func walk_multiplier() -> float:
	return 1.0 + 0.03 * rank("trail")

func rhythm_multiplier() -> float:
	return 1.0 + 0.04 * rank("rhythm")

func recovery_multiplier() -> float:
	return 1.0 + 0.08 * rank("care")

func restore(data: Dictionary) -> void:
	for track in TRACKS: totals[track] = clampi(int(data.get(track, 0)), 0, threshold(track, CAP))

func display() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for track in TRACKS:
		var current := rank(track)
		var start := threshold(track, current)
		var goal := threshold(track, mini(CAP, current + 1))
		result.append({"id": track, "name": NAMES[track], "rank": current, "total": totals[track], "goal": goal,
			"percent": 100.0 if current == CAP else 100.0 * (int(totals[track]) - start) / (goal - start)})
	return result

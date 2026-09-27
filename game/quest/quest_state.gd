class_name QuestState
extends RefCounted
## Isolated quest progress and completion rules; no scene, input or UI access.

signal changed

enum Status { NOT_STARTED, IN_PROGRESS, COMPLETED, REWARDED }

var id: String = "cull_slimes"
var title: String = "Cull the Slimes"
var description: String = "Defeat 50 slimes roaming around Fufufarm."
var target_count: int = 50
var current_count: int = 0
var status: Status = Status.NOT_STARTED
var reward_edamame: int = 100
var armored_status: Status = Status.NOT_STARTED
var armored_count: int = 0

func start() -> void:
	if status == Status.NOT_STARTED:
		status = Status.IN_PROGRESS
		current_count = 0
		changed.emit()

func record_kill() -> bool:
	if status != Status.IN_PROGRESS:
		return false
	current_count = mini(target_count, current_count + 1)
	if current_count >= target_count:
		status = Status.COMPLETED
	changed.emit()
	return true

func claim_reward() -> bool:
	if status != Status.COMPLETED:
		return false
	status = Status.REWARDED
	changed.emit()
	return true

func capture() -> Dictionary:
	return {
		"version": 1,
		"armored_status": int(armored_status),
		"armored_count": armored_count,
		"id": id,
		"status": int(status),
		"current_count": current_count
	}

func restore(data: Dictionary) -> void:
	if data.is_empty():
		return
	armored_status = clampi(int(data.get("armored_status", 0)), 0, 3) as Status
	armored_count = clampi(int(data.get("armored_count", 0)), 0, 50)
	id = String(data.get("id", "cull_slimes"))
	status = clampi(int(data.get("status", Status.NOT_STARTED)), 0, 3) as Status
	current_count = clampi(int(data.get("current_count", 0)), 0, target_count)
	changed.emit()

func start_armored() -> void:
	if armored_status != Status.NOT_STARTED: return
	armored_status = Status.IN_PROGRESS
	changed.emit()

func record_armored_kill() -> void:
	if armored_status != Status.IN_PROGRESS: return
	armored_count = mini(50, armored_count + 1)
	if armored_count == 50: armored_status = Status.COMPLETED
	changed.emit()

func claim_armored(shell_count: int) -> bool:
	if armored_status != Status.COMPLETED or shell_count < 10: return false
	armored_status = Status.REWARDED
	changed.emit()
	return true

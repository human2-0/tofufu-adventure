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
		"id": id,
		"status": int(status),
		"current_count": current_count
	}

func restore(data: Dictionary) -> void:
	if data.is_empty():
		return
	id = String(data.get("id", "cull_slimes"))
	status = clampi(int(data.get("status", Status.NOT_STARTED)), 0, 3) as Status
	current_count = clampi(int(data.get("current_count", 0)), 0, target_count)
	changed.emit()

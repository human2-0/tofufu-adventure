class_name TofuDungeonState
extends RefCounted
## Six factory processes must be secured in order before refinement is legal.

signal changed

const STATIONS: Array[String] = ["Receiving", "Washing & Soaking", "Milk Milling", "Coagulation", "Pressing & Chopping", "Packing"]
const PROCESS_SECONDS: float = 20.0

var action_remaining: float = 0.0
var units: int = 0
var secured: bool = false
var coagulant_added: bool = false
var stage: int = 0
var active: bool = false
var completed: bool = false
var process_remaining: float = 0.0
var broken_crates: int = 0

func enter() -> void:
	if completed: return
	active = true
	changed.emit()

func begin_process() -> void:
	if not active or completed or not secured or units < required_units() or process_remaining > 0.0: return
	process_remaining = PROCESS_SECONDS
	changed.emit()

func step(delta: float) -> bool:
	action_remaining = maxf(0.0, action_remaining - delta)
	if process_remaining <= 0.0: return false
	process_remaining = maxf(0.0, process_remaining - delta)
	if process_remaining > 0.0: return false
	units = 0
	secured = false
	coagulant_added = false
	stage += 1
	if stage >= STATIONS.size(): completed = true
	changed.emit()
	return true

func capture() -> Dictionary:
	return {"stage": stage, "completed": completed, "broken_crates": broken_crates, "units": units, "coagulant_added": coagulant_added}

func crate_broken(index: int) -> bool:
	return index >= 0 and index < 12 and (broken_crates & (1 << index)) != 0

func mark_crate(index: int) -> void:
	if index < 0 or index >= 12: return
	broken_crates |= 1 << index
	changed.emit()

func restore(data: Dictionary) -> void:
	action_remaining = 0.0
	completed = bool(data.get("completed", false))
	stage = STATIONS.size() if completed else clampi(int(data.get("stage", 0)), 0, STATIONS.size() - 1)
	broken_crates = clampi(int(data.get("broken_crates", 0)), 0, 4095)
	units = clampi(int(data.get("units", 0)), 0, 3)
	coagulant_added = bool(data.get("coagulant_added", false))
	secured = false
	active = false
	process_remaining = 0.0
	changed.emit()

func required_units() -> int:
	return 1 if stage == 1 or stage == 3 else 3

func operate() -> bool:
	if not active or completed or action_remaining > 0 or process_remaining > 0 or (not secured and stage != 3): return false
	if units >= required_units(): return false
	action_remaining = 1.0
	units += 1
	if stage == 3: coagulant_added = true
	changed.emit()
	begin_process()
	return true

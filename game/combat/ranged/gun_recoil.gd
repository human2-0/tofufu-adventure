class_name GunRecoil
extends RefCounted
## Per-weapon bloom, built by confirmed shots and recovered between bursts.

var heat: float = 0.0
var quiet_time: float = 0.0

func step(trigger: bool, delta: float, tuning: CombatTuning) -> void:
	quiet_time = 0.0 if trigger else quiet_time + delta
	if quiet_time >= tuning.recoil_recovery_delay:
		heat = move_toward(heat, 0.0, delta * tuning.recoil_recovery_speed)

func fired(tuning: CombatTuning) -> void:
	heat = minf(1.0, heat + tuning.recoil_per_shot)
	quiet_time = 0.0

func spread_degrees(precise: bool, tuning: CombatTuning) -> float:
	var base := tuning.aim_spread_degrees if precise else tuning.hip_spread_degrees
	return base + heat * (tuning.aim_recoil_spread if precise else tuning.hip_recoil_spread)

func reset() -> void:
	heat = 0.0
	quiet_time = 0.0

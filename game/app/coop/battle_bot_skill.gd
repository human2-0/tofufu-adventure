class_name BattleBotSkill
extends RefCounted
## Stateless perception/cadence keeps distributed workers and recovery consistent.
## All profiles use the same health, damage, ammunition and finite inventory.

const REACTION: Array[float] = [0.60, 0.30, 0.12]
const AIM_ERROR: Array[float] = [0.16, 0.075, 0.025]
const BURST_PERIOD: Array[float] = [1.40, 0.90, 0.60]
const BURST_LENGTH: Array[float] = [0.35, 0.45, 0.48]
const RANGE: Array[float] = [22.0, 27.0, 30.0]

static func perceived(state: BattleMatch, target: int) -> Vector3:
	var row: Array = state.rows[target]
	var reaction := REACTION[int(state.options[1])]
	var age := reaction + fmod(state.time, reaction)
	return state.position_of(target) - Vector3(row[3], row[4], row[5]) * age

static func aim(direction: Vector2, slot: int, state: BattleMatch) -> Vector2:
	var skill := int(state.options[1])
	var sample := floorf(state.time / REACTION[skill])
	var error := sin(sample * 1.73 + slot * 2.41) * AIM_ERROR[skill]
	return direction.rotated(error)

static func firing(slot: int, state: BattleMatch) -> bool:
	var skill := int(state.options[1])
	return fmod(state.time + slot * 0.17, BURST_PERIOD[skill]) < BURST_LENGTH[skill]

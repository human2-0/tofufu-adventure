class_name BattleOptions
extends RefCounted
## Bounded lobby settings; the selected count is clamped by remaining human seats.

const MAX_CPUS: int = 50
const DEFAULT_CPUS: int = 7
const NORMAL: int = 1

static func valid(value: Variant) -> bool:
	return value is Array and value.size() in [2, 3] and BattleProtocol.integer(value[0], 0, MAX_CPUS) and BattleProtocol.integer(value[1], 0, 2) and (value.size() == 2 or BattleProtocol.integer(value[2], 0, 1))

static func cpu_count(options: Array, humans: int) -> int:
	var count := mini(int(options[0]), BattleProtocol.CAPACITY - humans)
	if duos(options) and (humans + count) % 2 != 0:
		count += 1 if count < MAX_CPUS and humans + count < BattleProtocol.CAPACITY else -1
	return count

static func seats(options: Array, humans: int) -> int:
	return humans + cpu_count(options, humans)

static func canonical(value: Array) -> Array:
	return [int(value[0]), int(value[1]), 1] if duos(value) else [int(value[0]), int(value[1])]

static func duos(options: Array) -> bool:
	return options.size() == 3 and int(options[2]) == 1

static func playable(options: Array, humans: int) -> bool:
	return seats(options, humans) >= (4 if duos(options) else 2)

static func minimum_message(options: Array) -> String:
	return "Duos need two teams. Add more CPUs or invite more friends." if duos(options) else "Add a CPU or invite a friend to start the match."

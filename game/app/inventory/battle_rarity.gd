class_name BattleRarity
extends RefCounted
## Grades are derived from stable match catalog IDs, never saved adventure items.
const NAMES: Array[String] = ["Common", "Rare", "Legendary"]
const COLORS: Array[Color] = [Color("e7eddf"), Color("79bfff"), Color("ffcf62")]

static func grade(kind: int) -> int:
	if kind in [9, 10, 11, 33] or (kind >= 20 and kind <= 23): return 2
	if (kind >= 3 and kind <= 8) or (kind >= 16 and kind <= 19) or kind in [25, 26]: return 1
	return 0

static func title(kind: int, name: String) -> String:
	return TranslationServer.translate("%s · %s") % [TranslationServer.translate(NAMES[grade(kind)]), TranslationServer.translate(name)]

static func roll(rng: RandomNumberGenerator, pool: Array[int], weights: Array[int] = [60, 32, 8]) -> int:
	var groups: Array = [[], [], []]
	for kind in pool: groups[grade(kind)].append(kind)
	var total := 0
	for tier in 3:
		if not groups[tier].is_empty(): total += weights[tier]
	var draw := rng.randi_range(1, total)
	for tier in 3:
		if groups[tier].is_empty(): continue
		draw -= weights[tier]
		if draw <= 0: return groups[tier][rng.randi_range(0, groups[tier].size() - 1)]
	return pool[0]

static func pool(first: int, last: int) -> Array[int]:
	var result: Array[int] = []
	for kind in range(first, last + 1): result.append(kind)
	return result

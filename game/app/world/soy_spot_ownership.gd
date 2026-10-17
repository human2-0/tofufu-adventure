class_name SoySpotOwnership
extends RefCounted
## Personal unlocks survive defeat; only app authority grants a new spot.

var mask: int = 0

func owns(index: int) -> bool:
	return index >= 0 and index < SoySaveSpotSites.IDS.size() and (mask & (1 << index)) != 0

func claim(index: int) -> bool:
	if index < 0 or index >= SoySaveSpotSites.IDS.size() or owns(index): return false
	mask |= 1 << index
	return true

func restore(value: int) -> void:
	if value >= 0 and value < (1 << SoySaveSpotSites.IDS.size()): mask = value

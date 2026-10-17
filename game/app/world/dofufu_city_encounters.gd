class_name DofufuCityEncounters
extends RefCounted
## App composition supplies world-owned directional art to the combat guard.

static func guard() -> DofufuCityGuard:
	var guard_node := DofufuCityGuard.new()
	var art := DofufuCityArt.new()
	art.role = 3
	art.facing = Vector2.RIGHT
	guard_node.art = art
	return guard_node

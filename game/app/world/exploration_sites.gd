class_name ExplorationSites
extends Node

signal discovered(title: String, count: int)
var explorer: Node3D
var companions: Array[Node3D] = []
var _found: Array[String] = []
const PLACE_ALIASES := {
	"Fufufarm Village / Shops coming soon": "Fufufarm Village / Grandpa Fufu's gear shop",
	"Fufufarm Village / Kaji's gear shop": "Fufufarm Village / Grandpa Fufu's gear shop",
	"Seed Bank / Storage placeholder": "Stodoła / Personal storage",
	"Mayor Mame / Quests": "Grandma Fufu / Quests",
	"Mayor Mame / Quests coming soon": "Grandma Fufu / Quests",
}
var _places: Dictionary[String, Vector3] = {
	"Soybean Nursery": Vector3(-3, 0, 0),
	"Stodoła / Personal storage": Vector3(24, 0, -8),
	"Fufufarm Village / Grandpa Fufu's gear shop": Vector3(33.5, 0, -37),
	"Grandma Fufu / Quests": Vector3(46, 0, -13),
}

func _physics_process(_delta: float) -> void:
	for title: String in _places:
		if title not in _found and _near(_places[title]):
			_found.append(title)
			discovered.emit(title, _found.size())

func found_places() -> Array[String]:
	return _found.duplicate()

func restore_places(places: Array) -> void:
	_found.clear()
	for place: String in places:
		var restored_name: String = PLACE_ALIASES.get(place, place)
		if restored_name in _places and restored_name not in _found:
			_found.append(restored_name)
	if not _found.is_empty():
		discovered.emit(_found.back(), _found.size())

func _near(at: Vector3) -> bool:
	if is_instance_valid(explorer) and explorer.global_position.distance_to(at) < 3.0: return true
	for companion in companions:
		if is_instance_valid(companion) and companion.global_position.distance_to(at) < 3.0: return true
	return false

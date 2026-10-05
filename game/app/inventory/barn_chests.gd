class_name BarnChests
extends RefCounted
## Persisted personal chest contents; actor identity is injected by app composition.

const COUNT: int = 20
var banks: Array[ChestInventory] = []
var owners: Array[String] = []
var actor_key: Callable

func _init() -> void:
	for i in COUNT:
		banks.append(ChestInventory.new())
		owners.append("")

func key(actor: Node3D) -> String:
	return str(actor_key.call(actor)) if actor_key.is_valid() else "solo"

func permitted(index: int, actor: Node3D, claim: bool = false) -> bool:
	if index < 0 or index >= COUNT: return false
	var identity := key(actor)
	if identity.is_empty(): return false
	if owners[index].is_empty() and claim: owners[index] = identity
	return owners[index].is_empty() or owners[index] == identity

func capture() -> Dictionary:
	var contents: Array = []
	for bank in banks: contents.append(bank.capture())
	return {"owners": owners.duplicate(), "chests": contents}

func restore(data: Dictionary) -> void:
	for i in COUNT:
		owners[i] = str(data.owners[i])
		if data.chests[i] != banks[i].capture(): banks[i].restore(data.chests[i])

func adopt_solo(identity: String) -> void:
	for i in COUNT:
		if owners[i] == "solo": owners[i] = identity

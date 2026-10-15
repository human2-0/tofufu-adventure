class_name BarnChests
extends RefCounted
## Personal deposits keyed by identity; physical bays are interchangeable access points.

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

func permitted(index: int, actor: Node3D) -> bool:
	return index >= 0 and index < COUNT and not key(actor).is_empty()

func personal(actor: Node3D) -> ChestInventory:
	var identity := key(actor)
	if identity.is_empty(): return null
	for i in COUNT:
		if owners[i] == identity: return banks[i]
	for i in COUNT:
		if owners[i].is_empty() and banks[i].occupied_slots() == 0:
			return banks[i]
	return null

func refill(identity: String) -> void:
	# Old saves can contain several full bays for one player. Keep overflow
	# in its original records and bring it into the deposit as slots become free.
	var primary := -1
	for i in COUNT:
		if owners[i] != identity or identity.is_empty(): continue
		if primary < 0:
			primary = i
			continue
		for slot in ChestInventory.CAPACITY:
			var stack := banks[i].get_slot(slot)
			if stack == null: continue
			for destination in ChestInventory.CAPACITY:
				if banks[primary].get_slot(destination) != null: continue
				banks[i].set_slot(slot, null)
				banks[primary].set_slot(destination, stack)
				break
		if banks[i].occupied_slots() == 0: owners[i] = ""

func capture() -> Dictionary:
	var contents: Array = []
	for bank in banks: contents.append(bank.capture())
	return {"owners": owners.duplicate(), "chests": contents}

func restore(data: Dictionary) -> void:
	for i in COUNT:
		owners[i] = str(data.owners[i])
		if data.chests[i] != banks[i].capture(): banks[i].restore(data.chests[i])

	for identity: String in owners.duplicate(): refill(identity)

func adopt_solo(identity: String) -> void:
	for i in COUNT:
		if owners[i] == "solo": owners[i] = identity
	refill(identity)

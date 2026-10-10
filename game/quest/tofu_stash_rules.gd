class_name TofuStashRules
extends RefCounted
## Permanent, bounded claims independent of production attempts.

const IDS: Array[String] = ["stash_mill", "stash_press", "stash_pack"]
var opened: int = 0
var revision: int = 0

func available(id: String) -> bool:
	var index: int = IDS.find(id)
	return index >= 0 and (opened & (1 << index)) == 0

func claim(id: String, expected: int) -> bool:
	if expected != revision or not available(id): return false
	opened |= 1 << IDS.find(id)
	revision += 1
	return true

func capture() -> Dictionary:
	return {"opened": opened, "revision": revision}

func restore(data: Dictionary) -> bool:
	if data.size() != 2 or not TofuPuzzleContract.bounded_integer(data.get("opened"), 0, 7): return false
	if not TofuPuzzleContract.bounded_integer(data.get("revision"), 0, 3): return false
	var bits: int = 0
	for index in 3:
		if (int(data.opened) & (1 << index)) != 0: bits += 1
	if bits != int(data.revision): return false
	opened = int(data.opened)
	revision = int(data.revision)
	return true

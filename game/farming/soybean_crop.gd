class_name SoybeanCrop
extends RefCounted
## Per-plot lifecycle; the caller owns inventory grants and interaction reach.

enum Phase { EMPTY, SEED, SPROUT, LEAVES, VEGETATIVE, FLOWER, PODS, RIPE, HARVEST }
const GROW_SECONDS: float = 30.0
const YIELD: int = 3
var revision: int = 0
var planted: bool = false
var age: float = 0.0
var harvest_time: float = 0.0

func phase() -> Phase:
	if harvest_time > 0: return Phase.HARVEST
	if not planted: return Phase.EMPTY
	if age >= GROW_SECONDS: return Phase.RIPE
	return mini(Phase.PODS, 1 + int(age / 4.0)) as Phase

func plant() -> bool:
	if phase() != Phase.EMPTY: return false
	revision += 1
	planted = true
	age = 0
	return true

func step(delta: float) -> void:
	if not is_finite(delta) or delta <= 0: return
	if harvest_time > 0:
		harvest_time = maxf(0, harvest_time - delta)
	elif planted:
		age = minf(GROW_SECONDS, age + delta)

func harvest() -> bool:
	if phase() != Phase.RIPE: return false
	revision += 1
	planted = false
	age = 0
	harvest_time = 1.2
	return true

func pod_frame() -> int:
	if phase() == Phase.HARVEST: return 11
	return clampi(int((age - 20.0) / 10.0 * 10.0), 0, 10)

func title() -> String:
	return ["Empty soil", "Seed", "Sprouting", "First leaves", "Leaf growth", "Flowering", "Pods filling", "Ready to harvest", "Harvested!"][phase()]

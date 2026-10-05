class_name MeadowHarvest
extends Node
## Authority harvests food and fungi into shared drops; snapshots retain regrowth.

var game: Node3D
var authoritative: bool = true
var targets: Array[Damageable] = []

func _ready() -> void:
	for plant: MeadowProduce in game.world.produce:
		var target := Damageable.new()
		target.maximum = 1.0
		target.body = plant
		target.position.y = 0.5
		plant.add_child(target)
		target.depleted.connect(_harvest.bind(plant, target))
		plant.dispense = _dispense.bind(plant)
		targets.append(target)
		game.combat.targets.append(target)

func _dispense(plant: MeadowProduce) -> bool:
	if not authoritative or not game.world_items.pool.authoritative: return false
	for direction: Vector2 in [Vector2.DOWN, Vector2.RIGHT, Vector2.UP, Vector2.LEFT]:
		var origin := plant.global_position + Vector3(direction.x, 0, direction.y) * 1.2
		if game.world_items.pool.spawn(plant.item_id, 2, origin, direction) != null: return true
	return false

func _harvest(plant: MeadowProduce, target: Damageable) -> void:
	plant.harvest()
	if plant.regrow_remaining <= 0: target.current = 1.0

func _physics_process(_delta: float) -> void:
	if not authoritative: return
	for i in targets.size():
		if game.world.produce[i].regrow_remaining == 0 and targets[i].current == 0: targets[i].current = 1.0

func capture() -> Array:
	var rows: Array = []
	for plant: MeadowProduce in game.world.produce: rows.append(plant.regrow_remaining)
	return rows

func restore(rows: Array, replica: bool) -> void:
	authoritative = not replica
	for i in targets.size():
		var plant: MeadowProduce = game.world.produce[i]
		plant.set_physics_process(not replica)
		plant.regrow_remaining = float(rows[i])
		plant.present()
		targets[i].current = 1.0 if plant.regrow_remaining <= 0 else 0.0

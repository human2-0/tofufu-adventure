extends SceneTree
## Finite Soyjet, separate knife timing and exclusive attack states.

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var floor := StaticBody3D.new()
	floor.collision_layer = 1
	var floor_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20, 1, 20)
	floor_shape.shape = box
	floor_shape.position.y = -0.5
	floor.add_child(floor_shape)
	world.add_child(floor)
	var quarry := Node3D.new()
	quarry.position = Vector3(4, 0, 0)
	world.add_child(quarry)
	var fighter := FactorySoyFighter.new()
	fighter.quarry = quarry
	world.add_child(fighter)
	fighter.set_physics_process(false)
	await physics_frame
	var shots := [0]
	var strikes := [0]
	fighter.sprayed.connect(func(_damage: float, _source: Vector3, _victim: Node3D) -> void: shots[0] += 1)
	fighter.attacked.connect(func(_damage: float, _source: Vector3) -> void: strikes[0] += 1)
	for i in 20: fighter._physics_process(0.1)
	_check(shots[0] > 0 and fighter._refill > 0.0, "finite reservoir enters recovery")
	var exhausted_shots: int = shots[0]
	for i in 10: fighter._physics_process(0.1)
	_check(shots[0] == exhausted_shots, "reservoir recovery cannot spray")
	quarry.position = fighter.position + Vector3(1.0, 0, 0)
	fighter._physics_process(0.1)
	_check(fighter._knife_windup > 0.0, "close quarry starts knife telegraph")
	var before: int = shots[0]
	fighter._physics_process(0.8)
	_check(strikes[0] == 1 and shots[0] == before, "knife hit excludes simultaneous stream")
	world.queue_free()
	await process_frame
	print("Factory Soy fighter: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

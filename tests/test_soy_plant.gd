extends SceneTree
## One-minute harvest eligibility, staged art and existing snapshot round trips.

var failures: int = 0
var loot: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if condition: return
	failures += 1
	printerr("FAIL: ", message)

func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var plant := HarvestProp.new()
	world.add_child(plant)
	plant.set_physics_process(false)
	plant.target.set_physics_process(false)
	plant.harvested.connect(func(_at: Vector3, count: int) -> void: loot += count)
	check(plant.soy_visual.stage == SoyPlantVisual.Stage.MATURE, "authored plants start mature with pods")
	check(plant.target.damage(20), "mature soy is breakable")
	check(loot == 2 and plant._regrow == 60, "harvest awards two beans and starts a sixty-second cycle")
	check(plant.visible and plant.soy_visual.stage == SoyPlantVisual.Stage.SEED, "harvest leaves seed and emerging shoot")
	check(plant._body.collision_layer == 0 and not plant.target.damage(100), "young plant cannot block or reward attacks")
	plant._physics_process(6)
	check(plant.soy_visual.stage == SoyPlantVisual.Stage.SPROUT, "cotyledons and first leaves appear at six seconds")
	plant._physics_process(11)
	check(plant.soy_visual.stage == SoyPlantVisual.Stage.VEGETATION, "trifoliate branches appear at seventeen seconds")
	plant._physics_process(19)
	check(plant.soy_visual.stage == SoyPlantVisual.Stage.FLOWERING, "axillary flowers appear at thirty-six seconds")
	var replica := HarvestProp.new()
	world.add_child(replica)
	replica.set_physics_process(false)
	replica.target.set_physics_process(false)
	var row := EncounterState.prop(plant)
	EncounterState.apply_prop(replica, row)
	check(EncounterState.prop(replica) == row and replica.visible
		and replica.soy_visual.stage == SoyPlantVisual.Stage.FLOWERING, "checkpoint/replica restores growth from existing two-value record")
	# Legacy partial-health/timer rows still cannot expose premature rewards.
	EncounterState.apply_prop(replica, [20.0, 24.0])
	check(not replica.target.damage(20), "remaining timer gates damage even with legacy positive health")
	plant._physics_process(23.99)
	check(plant.target.current == 0 and loot == 2, "plant is unavailable just before sixty seconds")
	plant._physics_process(0.01)
	check(plant.soy_visual.stage == SoyPlantVisual.Stage.MATURE and plant._body.collision_layer == 1,
		"pods and original collision return at maturity")
	EncounterState.apply_prop(replica, EncounterState.prop(plant))
	check(replica.soy_visual.stage == SoyPlantVisual.Stage.MATURE and replica.target.current == 20,
		"replica returns to mature stage on authority snapshot")
	check(plant.target.damage(20) and loot == 4, "mature plant can immediately yield its next two beans")
	var crate := HarvestProp.new()
	crate.kind = 1
	world.add_child(crate)
	crate.set_physics_process(false)
	crate.target.damage(40)
	check(not crate.visible and crate._regrow == 28, "crate retains existing hidden twenty-eight-second regeneration")
	crate._physics_process(28)
	check(crate.visible and crate.target.current == 40, "crate restores normally")
	world.queue_free()
	await process_frame
	print("Soy plant growth tests: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

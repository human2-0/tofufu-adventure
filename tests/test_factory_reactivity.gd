extends SceneTree
## Confirmed interactions animate once; restored state and repeated packets stay quiet.

var failures: int = 0

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	var factory := TofuFactory.new()
	root.add_child(factory)
	factory.ensure_interior()
	await process_frame
	var attempt := TofuDungeonAttempt.new()
	attempt.configure(42, 1, 16)
	var snapshot: Dictionary = attempt.capture(true)
	FactoryProductionVisuals.present_factory(factory, snapshot)
	var views: Array[Node] = get_nodes_in_group("factory_production_visuals")
	var count: int = factory.get_child_count()
	_check(_bursts(views) == 0, "first checkpoint does not replay interactions")
	snapshot.sorting.carried_by = {"sack_mature": 7}
	snapshot.sorting.revision += 1
	FactoryProductionVisuals.present_factory(factory, snapshot)
	var sorting: FactoryProductionVisuals = views[0]
	_check(sorting._effects.pool.last_kind == "dust", "pickup releases small local sack dust")
	var bursts: int = _bursts(views)
	FactoryProductionVisuals.present_factory(factory, snapshot)
	_check(_bursts(views) == bursts, "same replicated snapshot cannot replay a burst")
	snapshot.sorting.carried_by = {}
	snapshot.sorting.assignments = {"sack_mature": "intake_tofu"}
	snapshot.sorting.revision += 1
	FactoryProductionVisuals.present_factory(factory, snapshot)
	_check(sorting._effects.pool.last_kind == "beans", "accepted intake sends beans down its hopper")
	_check(not (sorting.get_parent().get_node("BatchLine") as FactoryBatchLine).delivered, "new batch still traverses real pipe")
	snapshot.lab.carried_bottle = "container_00"
	snapshot.lab.carrier_id = 7
	snapshot.lab.revision += 1
	FactoryProductionVisuals.present_factory(factory, snapshot)
	snapshot.lab.carried_bottle = ""
	snapshot.lab.carrier_id = 0
	snapshot.lab.complete = true
	snapshot.lab.revision += 1
	FactoryProductionVisuals.present_factory(factory, snapshot)
	_check((views[1] as FactoryProductionVisuals)._effects.pool.last_kind == "steam", "successful pour gets liquid and curd steam feedback")
	var laboratory: FactoryInteractionEffects = (views[1] as FactoryProductionVisuals)._effects
	_check(laboratory._pour_pose.visible and laboratory._pour_stream.visible, "committed bottle visibly tips and pours")
	_check(not (laboratory.get_parent().get_node("container_00") as Node3D).visible, "pour bottle is not duplicated on its rack")
	laboratory._process(1.0)
	_check((laboratory.get_parent().get_node("container_00") as Node3D).visible, "sealed bottle returns to its rack after cosmetic pour")
	snapshot.press.active_sample = 0
	snapshot.press.lease_actor = 7
	snapshot.press.revision += 1
	FactoryProductionVisuals.present_factory(factory, snapshot)
	snapshot.press.stones = ["stone_1"]
	snapshot.press.revision += 1
	FactoryProductionVisuals.present_factory(factory, snapshot)
	_check((views[2] as FactoryProductionVisuals)._effects.pool.last_kind == "dust", "stone seating creates a local cloth puff")
	snapshot.press.certificates[0] = true
	snapshot.press.active_sample = -1
	snapshot.press.lease_actor = 0
	snapshot.press.revision += 1
	FactoryProductionVisuals.present_factory(factory, snapshot)
	_check((views[2] as FactoryProductionVisuals)._effects.pool.last_kind == "steam", "certification releases visible pressure")
	snapshot.cut.completed = true
	snapshot.cut.revision += 1
	FactoryProductionVisuals.present_factory(factory, snapshot)
	_check((views[3] as FactoryProductionVisuals)._effects.pool.last_kind == "crumbs", "cut carriage releases bounded tofu crumbs")
	snapshot.pack.slot_slabs[0] = 0
	snapshot.pack.revision += 1
	FactoryProductionVisuals.present_factory(factory, snapshot)
	snapshot.pack.sealed[0] = true
	snapshot.pack.revision += 1
	FactoryProductionVisuals.present_factory(factory, snapshot)
	_check((views[4] as FactoryProductionVisuals)._effects.pool.last_kind == "steam", "sealing film releases a local heat puff")
	var life: FactoryMachineLife = sorting._effects.life
	var cargo_before: Vector3 = life._cargo[0].position
	var gear_before: Vector3 = life._gears[0].rotation
	life._process(0.5)
	_check(not life._cargo[0].position.is_equal_approx(cargo_before), "secondary-line cargo visibly travels")
	_check(not life._gears[0].rotation.is_equal_approx(gear_before), "guarded gears keep the factory alive")
	for index in 100:
		sorting._effects.pool.burst("dust", Vector3.ZERO)
	_check(sorting._effects.pool.get_child_count() == FactoryEffectPool.SLOTS, "spam reuses four effect batches")
	_check(factory.get_child_count() == count, "interaction effects add no unbounded factory nodes")
	sorting._effects.pool._process(3.0)
	for batch in sorting._effects.pool._batches: _check(not batch.visible, "spent bursts hide after finite lifetime")
	bursts = _bursts(views)
	snapshot.attempt_id += 1
	FactoryProductionVisuals.present_factory(factory, snapshot)
	_check(_bursts(views) == bursts, "restored and reset attempt silently baselines completed state")
	_check((sorting.get_parent().get_node("BatchLine") as FactoryBatchLine).delivered, "restored batch does not replay milk creation")
	_check(not (views[3] as FactoryProductionVisuals)._audio._effect.playing, "restored cut does not replay its sound")
	_check((views[3] as FactoryProductionVisuals)._cut_cycle == 0.0, "restored cutter does not animate an old cut")
	_check(is_equal_approx(((views[3] as FactoryProductionVisuals).get_parent().get_node("cutter/MovingParts/Blade") as Node3D).position.y, 2.12), "restored blade returns to safe resting pose")
	_check((views[4] as FactoryProductionVisuals)._seal_cycles.is_empty(), "restored seals do not replay old film motion")
	bursts = _bursts(views)
	snapshot.cut.revision = 0
	FactoryProductionVisuals.present_factory(factory, snapshot)
	_check(_bursts(views) == bursts and (views[3] as FactoryProductionVisuals)._cut_cycle == 0.0, "checkpoint rollback silently baselines its old cut")
	factory.queue_free()
	await process_frame
	await process_frame
	if failures == 0: print("Factory reactivity: PASS")
	quit(1 if failures else 0)

func _bursts(views: Array[Node]) -> int:
	var total: int = 0
	for view: FactoryProductionVisuals in views: total += view._effects.pool.burst_count
	return total

func _check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

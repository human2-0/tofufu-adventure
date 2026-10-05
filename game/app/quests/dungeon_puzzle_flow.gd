class_name DungeonPuzzleFlow
extends RefCounted
## Scene composition for active puzzle encounters and nearby actions.

var spawned_encounter: String = ""
var observed: Dictionary = {}
var sequences: Dictionary = {}
var anchors := DungeonPuzzleAnchors.new()

func advance(dungeon: TofuDungeon) -> void:
	DungeonCrateSupply.ensure(dungeon)
	DungeonTrialLifecycle.step(dungeon)
	dungeon.puzzle.poll(dungeon.puzzle_clock)
	if dungeon.cooperative: DungeonSpectators.step(dungeon)
	for enemy: FactoryBean in dungeon._enemies:
		enemy.quarry = dungeon._nearest_actor(enemy.global_position)
		if dungeon.cooperative: dungeon._register_target(enemy.target)
	if dungeon.puzzle.phase == TofuPuzzleContract.Phase.COMBAT:
		if spawned_encounter != dungeon.puzzle.encounter_id:
			_spawn(dungeon)
	elif not dungeon._enemies.is_empty():
		_clear_enemies(dungeon)
	if dungeon.factory.interior_built and dungeon.puzzle.stage < TofuPuzzleContract.Stage.COMPLETE:
		DungeonProductionPresentation.present(dungeon)

func submit(dungeon: TofuDungeon, command: TofuPuzzleCommand, actor: Player) -> Dictionary:
	if not dungeon.enabled:
		if actor == dungeon.game.player:
			dungeon.puzzle_command_requested.emit(command)
			return {"accepted": true, "pending": true}
		return {"accepted": false}
	var now: float = dungeon.puzzle_clock
	var result: Dictionary = dungeon.puzzle_runtime.submit(command, actor, now)
	if bool(result.get("accepted", false)):
		if command.action == TofuPuzzleCommand.Action.INSPECT:
			observed["%d:%s" % [DungeonMembership.actor_id(dungeon, actor), command.target_id]] = command.target_id
		if dungeon.puzzle.stage == TofuPuzzleContract.Stage.BOSS and command.action == TofuPuzzleCommand.Action.SEAL_SLOT:
			DungeonArena.enter(dungeon)
		if int(result.get("stage", 0)) == TofuPuzzleContract.Stage.COMPLETE:
			dungeon.state.completed = true
			dungeon.state.changed.emit()
		if not str(result.get("encounter_id", "")).is_empty():
			dungeon.game.hud.announce("Production halted · Clear the encounter")
	return result

func interact(dungeon: TofuDungeon, actor: Player) -> bool:
	if not dungeon.actor_in_run(actor): return false
	if dungeon.puzzle.phase != TofuPuzzleContract.Phase.READY and dungeon.puzzle.phase != TofuPuzzleContract.Phase.OPERATING: return false
	var stage: int = int(dungeon.puzzle.stage)
	match stage:
		TofuPuzzleContract.Stage.SORT: return _sort_interact(dungeon, actor)
		TofuPuzzleContract.Stage.LAB: return _lab_interact(dungeon, actor)
		TofuPuzzleContract.Stage.PRESS: return _press_interact(dungeon, actor)
		TofuPuzzleContract.Stage.CUT: return _cut_interact(dungeon, actor)
		TofuPuzzleContract.Stage.PACK: return _pack_interact(dungeon, actor)
	return false

func encounter_cleared(dungeon: TofuDungeon, encounter_id: String) -> void:
	if not dungeon.puzzle_runtime.encounter_cleared(encounter_id): return
	spawned_encounter = ""
	if dungeon.puzzle.phase == TofuPuzzleContract.Phase.LOCKED:
		dungeon.game.hud.announce("Ten penalty waves reached · Evacuate or restart the factory attempt")
		return
	if dungeon.puzzle.mistakes == 9:
		dungeon.game.hud.announce("One production mistake remains before this attempt closes")
		return
	dungeon.game.hud.announce("Room clear · " + TofuFactory.INSTRUCTIONS[int(dungeon.puzzle.stage)])

func reset_encounter(dungeon: TofuDungeon) -> void:
	_clear_enemies(dungeon)
	spawned_encounter = ""

func _spawn(dungeon: TofuDungeon) -> void:
	spawned_encounter = dungeon.puzzle.encounter_id
	var boss: bool = spawned_encounter == "dofufu_boss"
	var count: int = 1 if boss else 4 if spawned_encounter == "lab_curd" else 3
	var center: Vector3 = TofuFactory.CENTERS[clampi(int(dungeon.puzzle.stage), 0, 5)]
	var scale: float = TofuPuzzleContract.penalty_multiplier(dungeon.puzzle.mistakes) if spawned_encounter.begins_with("penalty_") else 1.0
	for index in count:
		var enemy: FactoryBean = Dofufu.new() if boss else FactorySoyFighter.new()
		if boss: (enemy as Dofufu).combat_participants = maxi(1, dungeon.boss_members.size())
		else: enemy.kind = FactoryBean.Kind.DOFU if spawned_encounter == "lab_curd" else FactoryBean.Kind.SCOUT if index % 2 == 0 else FactoryBean.Kind.BRUISER
		enemy.health_scale = scale
		enemy.damage_scale = scale
		enemy.position = center + Vector3(-3 + index * 2, 0.1, -1)
		enemy.quarry = dungeon._nearest_actor(enemy.position)
		dungeon.game.world.add_child(enemy)
		if not dungeon.rewards.reward_available(spawned_encounter, index):
			DungeonEncounterPresentation.practice(enemy)
		enemy.targeting.connect(ActorProgression.threaten)
		enemy.attacked.connect(dungeon._enemy_attack)
		if enemy is FactorySoyFighter: (enemy as FactorySoyFighter).sprayed.connect(dungeon._enemy_spray)
		enemy.defeated.connect(dungeon._enemy_defeated.bind(enemy))
		dungeon._register_target(enemy.target)
		dungeon._enemies.append(enemy)
		dungeon._enemy_reward_ids[enemy] = [spawned_encounter, index]
	dungeon.game.hud.announce("Encounter · " + ("Dofufu" if boss else "Factory defenders"))

func _clear_enemies(dungeon: TofuDungeon) -> void:
	for enemy: FactoryBean in dungeon._enemies:
		dungeon._unregister_target(enemy.target)
		enemy.queue_free()
	dungeon._enemies.clear()
	dungeon._enemy_reward_ids.clear()

func _sort_interact(dungeon: TofuDungeon, actor: Player) -> bool:
	var actor_id: int = DungeonMembership.actor_id(dungeon, actor)
	var carrying: String = ""
	for sack: String in dungeon.puzzle.sorting.carried_by:
		if dungeon.puzzle.sorting.carried_by[sack] == actor_id: carrying = sack
	if not carrying.is_empty():
		var intake: String = _nearest(actor, TofuPuzzleContract.INTAKE_IDS)
		if intake.is_empty(): return false
		if _inspect_first(dungeon, actor, intake): return true
		return bool(submit(dungeon, _command(dungeon, actor, TofuPuzzleCommand.Action.LOAD_INTAKE, intake, carrying), actor).get("accepted", false))
	var sack_id: String = _nearest(actor, TofuPuzzleContract.SACK_IDS)
	if sack_id.is_empty(): return false
	if _inspect_first(dungeon, actor, sack_id): return true
	return bool(submit(dungeon, _command(dungeon, actor, TofuPuzzleCommand.Action.PICK_UP, sack_id), actor).get("accepted", false))

func _lab_interact(dungeon: TofuDungeon, actor: Player) -> bool:
	var special: Array[String] = ["shift_note", "lab_terminal", "coagulation_tank"]
	var selected: String = _nearest(actor, special)
	if selected == "shift_note":
		if actor == dungeon.game.player and dungeon.puzzle_views != null:
			return dungeon.puzzle_views.open_note(anchors.get_anchor(dungeon, selected))
		return bool(submit(dungeon, _command(dungeon, actor, TofuPuzzleCommand.Action.INSPECT, selected), actor).get("accepted", false))
	if selected == "lab_terminal" and actor == dungeon.game.player and dungeon.puzzle_views != null:
		return dungeon.puzzle_views.open_terminal(anchors.get_anchor(dungeon, selected))
	if selected == "coagulation_tank" and dungeon.puzzle.lab.carrier_id == DungeonMembership.actor_id(dungeon, actor):
		return bool(submit(dungeon, _command(dungeon, actor, TofuPuzzleCommand.Action.POUR, selected, dungeon.puzzle.lab.carried_bottle), actor).get("accepted", false))
	var containers: Array[String] = []
	for index in 20: containers.append("container_%02d" % index)
	var bottle: String = _nearest(actor, containers)
	if bottle.is_empty(): return false
	if _inspect_first(dungeon, actor, bottle): return true
	return bool(submit(dungeon, _command(dungeon, actor, TofuPuzzleCommand.Action.PICK_UP, bottle), actor).get("accepted", false))

func _press_interact(dungeon: TofuDungeon, actor: Player) -> bool:
	if actor != dungeon.game.player or dungeon.puzzle_views == null: return false
	var selected: String = _nearest(actor, ["traditional_press", "modern_press"])
	if selected.is_empty(): return false
	return dungeon.puzzle_views.open_press(anchors.get_anchor(dungeon, selected), selected == "modern_press")

func _cut_interact(dungeon: TofuDungeon, actor: Player) -> bool:
	if _nearest(actor, ["cutter"]) != "cutter": return false
	if actor == dungeon.game.player and dungeon.puzzle_views != null:
		return dungeon.puzzle_views.open_cutter(anchors.get_anchor(dungeon, "cutter"))
	return false

func _pack_interact(dungeon: TofuDungeon, actor: Player) -> bool:
	var slab_ids: Array[String] = []
	var package_ids: Array[String] = []
	for index in 6:
		slab_ids.append("slab_%d" % index)
		package_ids.append("package_%d" % index)
	var slab: String = _nearest(actor, slab_ids)
	if not slab.is_empty():
		return bool(submit(dungeon, _command(dungeon, actor, TofuPuzzleCommand.Action.PICK_UP, "", slab.trim_prefix("slab_")), actor).get("accepted", false))
	var package: String = _nearest(actor, package_ids)
	if package.is_empty(): return false
	var slot: int = int(package.trim_prefix("package_"))
	if dungeon.puzzle.pack.slot_slabs[slot] >= 0:
		return bool(submit(dungeon, _command(dungeon, actor, TofuPuzzleCommand.Action.SEAL_SLOT, str(slot)), actor).get("accepted", false))
	for index in 6:
		if dungeon.puzzle.pack.owners[index] == DungeonMembership.actor_id(dungeon, actor):
			return bool(submit(dungeon, _command(dungeon, actor, TofuPuzzleCommand.Action.PLACE_SLAB, str(slot), str(index)), actor).get("accepted", false))
	return false

func _nearest(actor: Player, ids: Array[String]) -> String:
	var chosen: String = ""
	var distance: float = 2.8
	for identity: String in ids:
		var at: Vector3 = TofuFactory.object_position(identity)
		if not at.is_finite(): continue
		var candidate: float = actor.global_position.distance_to(at)
		if candidate < distance:
			distance = candidate
			chosen = identity
	return chosen

func _inspect_first(dungeon: TofuDungeon, actor: Player, identity: String) -> bool:
	var key: String = "%d:%s" % [DungeonMembership.actor_id(dungeon, actor), identity]
	if observed.has(key): return false
	submit(dungeon, _command(dungeon, actor, TofuPuzzleCommand.Action.INSPECT, identity), actor)
	observed[key] = identity
	if actor == dungeon.game.player:
		dungeon.journal.hint_text = DungeonRunActions.hint(dungeon)
		dungeon.journal.open(TofuPuzzleClues.describe(identity, dungeon.puzzle), false)
	else: dungeon.game.hud.announce(TofuPuzzleClues.describe(identity, dungeon.puzzle))
	return true

func _command(dungeon: TofuDungeon, actor: Player, action: TofuPuzzleCommand.Action, target: String, object_id: String = "") -> TofuPuzzleCommand:
	return DungeonPuzzleIntent.build(self, dungeon, actor, action, target, object_id)

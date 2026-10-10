class_name DungeonPuzzleFlow
extends RefCounted
## Scene composition for active puzzle encounters and nearby actions.

var spawned_encounter: String = ""
var observed: Dictionary = {}
var sequences: Dictionary = {}
var anchors := DungeonPuzzleAnchors.new()

func advance(dungeon: TofuDungeon) -> void:
	DungeonCrateSupply.ensure(dungeon)
	DungeonStashes.present(dungeon)
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
	var result: Dictionary = DungeonStashes.submit(dungeon, command, actor) if command != null and command.action == TofuPuzzleCommand.Action.OPEN_STASH else dungeon.puzzle_runtime.submit(command, actor, now)
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
	return DungeonPuzzleInteraction.perform(dungeon, actor)

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
		var offset := Vector3(-3 + index * 2, 0.1, -1)
		if not boss: offset = Vector3((index - (count - 1) * 0.5) * 4.0, 0.1, 1.5)
		enemy.position = center + offset
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

func _command(dungeon: TofuDungeon, actor: Player, action: TofuPuzzleCommand.Action, target: String, object_id: String = "") -> TofuPuzzleCommand:
	return DungeonPuzzleIntent.build(self, dungeon, actor, action, target, object_id)

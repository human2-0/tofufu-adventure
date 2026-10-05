class_name DungeonStage
extends RefCounted
## Production-stage encounters, target registration and confirmed rewards.

static func advance_inside(dungeon: TofuDungeon, delta: float) -> void:
	for carrier: Player in dungeon._carrying.keys():
		if not is_instance_valid(carrier) or not TofuFactory.contains(carrier.global_position): dungeon._carrying.erase(carrier)
	for enemy: FactoryBean in dungeon._enemies:
		enemy.quarry = dungeon._nearest_actor(enemy.global_position)
		if dungeon.cooperative: dungeon._register_target(enemy.target)
	if dungeon.cooperative:
		for crate: FactoryCrate in dungeon._crates: dungeon._register_target(crate.target)
	if not dungeon.state.completed and dungeon._spawned_stage != dungeon.state.stage:
		var center := TofuFactory.CENTERS[dungeon.state.stage]
		for actor in dungeon._actors_inside():
			if actor.global_position.distance_to(center) < 12.0:
				dungeon._spawn_stage()
				break
	dungeon.factory.show_cargo(dungeon.cargo_positions())
	dungeon.factory.show_objective(dungeon.state.stage, dungeon.state.units, dungeon.state.secured or (dungeon.state.stage == 3 and not dungeon.state.coagulant_added), not dungeon._carrying.is_empty())
	if dungeon.state.step(delta):
		dungeon._carrying.clear()
		dungeon.factory.process_finished(dungeon.state.stage - 1)
		if dungeon.state.completed:
			dungeon.game.hud.announce("Tofu Dungeon complete! Soybean refinement is now legal.")
		else:
			dungeon.game.hud.announce("%s complete · Next: %s" % [TofuDungeonState.STATIONS[dungeon.state.stage - 1], TofuDungeonState.STATIONS[dungeon.state.stage]])
	elif dungeon.state.process_remaining > 0.0:
		dungeon.factory.show_processing(dungeon.state.stage, dungeon.state.process_remaining)

static func spawn_stage(dungeon: TofuDungeon) -> void:
	var first_visit := dungeon._spawned_stage != dungeon.state.stage
	dungeon._spawned_stage = dungeon.state.stage
	var count := 3 if dungeon.state.stage < 2 else 4
	if dungeon.state.stage == 3 and not dungeon.state.coagulant_added: count = 0
	if dungeon.state.stage == 5: count = 1
	for i in count:
		var enemy: FactoryBean = Dofufu.new() if dungeon.state.stage == 5 and i == 0 else FactorySoyFighter.new()
		if enemy is Dofufu: (enemy as Dofufu).combat_participants = maxi(1, dungeon._actors_inside().size())
		else: enemy.kind = FactoryBean.Kind.DOFU if dungeon.state.stage >= 3 else (FactoryBean.Kind.BRUISER if i % 2 == 1 else FactoryBean.Kind.SCOUT)
		enemy.position = TofuFactory.CENTERS[dungeon.state.stage] + Vector3(-3 + float(i % 3) * 3, 0.1, -1 + float(i / 3) * 3)
		enemy.quarry = dungeon._nearest_actor(enemy.position)
		dungeon.game.world.add_child(enemy)
		enemy.targeting.connect(ActorProgression.threaten)
		enemy.attacked.connect(dungeon._enemy_attack)
		if enemy is FactorySoyFighter: (enemy as FactorySoyFighter).sprayed.connect(dungeon._enemy_spray)
		enemy.defeated.connect(dungeon._enemy_defeated.bind(enemy))
		dungeon._register_target(enemy.target)
		dungeon._enemies.append(enemy)
		dungeon._enemy_reward_ids[enemy] = ["dofufu_boss" if enemy is Dofufu else "stage_%02d" % dungeon.state.stage, i]
	for i in (2 if first_visit else 0):
		var crate_index := dungeon.state.stage * 2 + i
		if dungeon.state.crate_broken(crate_index): continue
		var crate := FactoryCrate.new()
		crate.position = TofuFactory.CENTERS[dungeon.state.stage] + Vector3(-8 if i == 0 else 8, 0, 6)
		dungeon.game.world.add_child(crate)
		crate.broken.connect(dungeon._crate_broken.bind(crate, crate_index))
		dungeon._register_target(crate.target)
		dungeon._crates.append(crate)
	dungeon.game.hud.announce("%d / 6 · %s · %s" % [dungeon.state.stage + 1, TofuDungeonState.STATIONS[dungeon.state.stage], "Add nigari at the kettle" if dungeon.state.stage == 3 and not dungeon.state.coagulant_added else "Secure the production room"])

static func enemy_attack(dungeon: TofuDungeon, amount: float, source: Vector3) -> void:
	if dungeon.cooperative:
		var victim := dungeon._nearest_member(source)
		if victim != null and victim.actor.global_position.distance_to(source) < 2.5 and DungeonCombatAccess.visible(dungeon, source, victim.actor): victim.hurt(amount, source)
		return
	if not dungeon._inside or dungeon.game.health.current <= 0.0: return
	if not DungeonCombatAccess.visible(dungeon, source, dungeon.game.player): return
	dungeon.game.encounters._hurt_player(amount, source)

static func enemy_spray(dungeon: TofuDungeon, amount: float, source: Vector3, victim: Node3D) -> void:
	if not is_instance_valid(victim) or victim.global_position.distance_to(source) > 8.0: return
	if not DungeonCombatAccess.visible(dungeon, source, victim): return
	if dungeon.cooperative:
		for member: CoopActor in dungeon.party.values():
			if member.actor == victim and dungeon.actor_in_run(member.actor) and member.health.current > 0.0:
				member.hurt(amount, source)
		return
	if victim == dungeon.game.player and dungeon.actor_in_run(dungeon.game.player):
		dungeon.game.encounters._hurt_player(amount, source)

static func enemy_defeated(dungeon: TofuDungeon, _at: Vector3, enemy: FactoryBean) -> void:
	if enemy not in dungeon._enemies: return
	var reward_slot: Array = dungeon._enemy_reward_ids.get(enemy, [])
	dungeon._enemy_reward_ids.erase(enemy)
	dungeon._enemies.erase(enemy)
	dungeon._unregister_target(enemy.target)
	enemy.queue_free()
	DungeonRewards.pay(dungeon, enemy, reward_slot, _at)
	if enemy is Dofufu: return
	if dungeon.puzzle_enabled:
		if dungeon._enemies.is_empty() and reward_slot.size() == 2:
			dungeon.puzzle_flow.encounter_cleared(dungeon, str(reward_slot[0]))
		return
	if dungeon._enemies.is_empty() and not dungeon.state.completed:
		dungeon.state.secured = true
		dungeon.state.begin_process()
		dungeon.game.hud.announce("Room secure · " + TofuFactory.INSTRUCTIONS[dungeon.state.stage])

static func crate_broken(dungeon: TofuDungeon, at: Vector3, crate: FactoryCrate, index: int) -> void:
	dungeon._crates.erase(crate)
	dungeon._unregister_target(crate.target)
	if dungeon.state.crate_broken(index): return
	if index % 2 == 0:
		var room: int = clampi(index / 2, 0, 5)
		if dungeon.game.world_items.pool.spawn("soy_milk", 1, TofuFactory.recovery_anchor(room), Vector2.RIGHT) == null: return
	dungeon.state.mark_crate(index)

static func nearest_actor(dungeon: TofuDungeon, at: Vector3) -> Node3D:
	var nearest: Node3D = null
	var distance := INF
	for actor: Node3D in dungeon._actors_inside():
		if not DungeonCombatAccess.alive(dungeon, actor): continue
		var candidate := actor.global_position.distance_to(at)
		if candidate < distance:
			distance = candidate
			nearest = actor
	return nearest

static func nearest_member(dungeon: TofuDungeon, at: Vector3) -> CoopActor:
	var nearest: CoopActor = null
	var distance := INF
	for member: CoopActor in dungeon.party.values():
		if not dungeon.actor_in_run(member.actor) or member.spectating or member.health.current <= 0.0: continue
		var candidate := member.actor.global_position.distance_to(at)
		if candidate < distance:
			distance = candidate
			nearest = member
	return nearest

static func register_target(dungeon: TofuDungeon, target: Damageable) -> void:
	if not dungeon.cooperative:
		dungeon.game.combat.targets.append(target)
		return
	for member: CoopActor in dungeon.party.values():
		if target not in member.combat.targets: member.combat.targets.append(target)

static func unregister_target(dungeon: TofuDungeon, target: Damageable) -> void:
	if not dungeon.cooperative:
		dungeon.game.combat.targets.erase(target)
		return
	for member: CoopActor in dungeon.party.values(): member.combat.targets.erase(target)

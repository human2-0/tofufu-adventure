class_name DungeonPersistence
extends RefCounted
## One checkpoint record carries puzzle, rewards and legacy factory state.

static func capture(dungeon: TofuDungeon) -> Dictionary:
	var data: Dictionary = dungeon.state.capture()
	data.inspections = dungeon.puzzle_flow.observed.duplicate()
	data.actor_ids = dungeon.actor_ids.duplicate()
	data.boss_members = dungeon.boss_members.duplicate()
	data.active = dungeon.state.active
	data.reward_ledger = dungeon.rewards.capture()
	data.puzzle_mode = dungeon.puzzle_enabled
	data.puzzle = dungeon.puzzle.capture()
	return data

static func restore(dungeon: TofuDungeon, data: Dictionary) -> void:
	for enemy: FactoryBean in dungeon._enemies:
		dungeon._unregister_target(enemy.target)
		enemy.queue_free()
	for crate: FactoryCrate in dungeon._crates:
		dungeon._unregister_target(crate.target)
		crate.queue_free()
	dungeon._enemies.clear()
	dungeon._enemy_reward_ids.clear()
	dungeon._crates.clear()
	dungeon._carrying.clear()
	dungeon.actor_ids = data.get("actor_ids", {}).duplicate()
	dungeon.boss_members.assign(data.get("boss_members", []))
	dungeon.state.restore(data)
	dungeon.puzzle_enabled = bool(data.get("puzzle_mode", true))
	if data.has("puzzle"):
		if not dungeon.puzzle.restore(data.puzzle):
			dungeon.puzzle.configure(1, 1, 12345)
			dungeon.state.stage = 0
			dungeon.state.completed = false
	elif dungeon.state.completed:
		TofuAttemptSnapshot.migrate_completed(dungeon.puzzle)
	else:
		dungeon.puzzle.configure(1, 1, 12345)
		dungeon.state.stage = 0
		dungeon.state.units = 0
		dungeon.state.secured = false
	if data.has("reward_ledger"):
		dungeon.rewards.restore(data.reward_ledger)
	elif dungeon.state.completed:
		var legacy_members: Array[String] = dungeon.state.run_members.duplicate()
		if legacy_members.is_empty(): legacy_members.append("solo")
		dungeon.rewards.complete_confirmed_boss(legacy_members)
	var saved_at: Vector3 = dungeon.game.player.global_position
	if saved_at.x > 210 and saved_at.x < 230 and saved_at.z > -104 and saved_at.z < 10:
		dungeon._teleport(TofuFactory.CENTERS[mini(dungeon.state.stage, 5)] + Vector3(0, 0.2, 4))
	dungeon.state.active = bool(data.get("active", not dungeon.state.run_members.is_empty()))
	dungeon.factory.reset_gates(dungeon.state.stage)
	if not data.has("run_members") and TofuFactory.contains(dungeon.game.player.global_position):
		DungeonMembership.enter(dungeon, dungeon.game.player)
	dungeon._inside = dungeon.actor_in_run(dungeon.game.player)
	dungeon._recovery = DungeonRecovery.new()
	dungeon._spawned_stage = -1
	dungeon._cooldown = 1.0
	dungeon.puzzle_flow = DungeonPuzzleFlow.new()
	dungeon.puzzle_flow.observed = data.get("inspections", {}).duplicate()
	dungeon.puzzle_runtime.configure(dungeon, dungeon.puzzle)
	if dungeon.puzzle_enabled and dungeon.puzzle.stage == TofuPuzzleContract.Stage.BOSS and dungeon.puzzle.phase == TofuPuzzleContract.Phase.COMBAT:
		DungeonArena.enter(dungeon)
	var actor_id: String = str(DungeonMembership.actor_id(dungeon, dungeon.game.player))
	dungeon.puzzle_views.set_sequence_floor(maxi(int(dungeon.puzzle.sorting.last_sequence.get(actor_id, 0)), int(dungeon.puzzle.lab.last_sequence.get(actor_id, 0))))
	dungeon._sync_unlock()

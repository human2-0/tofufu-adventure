class_name DungeonRewards
extends RefCounted
## Confirmed death pays one shared drop and records participant entitlement.

static func pay(dungeon: TofuDungeon, enemy: FactoryBean, reward_slot: Array, at: Vector3) -> void:
	if reward_slot.size() != 2: return
	var encounter: String = str(reward_slot[0])
	var slot: int = int(reward_slot[1])
	if enemy is Dofufu:
		_pay_boss(dungeon, at)
		return
	if not dungeon.rewards.reward_available(encounter, slot): return
	var drop: WorldItemDrop = _spawn(dungeon, "edamame", at)
	if drop == null: return
	var payout: Dictionary = dungeon.rewards.claim_confirmed_defeat(encounter, slot)
	if not bool(payout.get("valid", false)) or bool(payout.get("practice", false)): return
	dungeon.state.mark_rewarded(str(payout.identity))
	_award_experience(dungeon, at, int(payout.experience))

static func _pay_boss(dungeon: TofuDungeon, at: Vector3) -> void:
	var members: Array[String] = dungeon.boss_members.duplicate() if dungeon.puzzle_enabled else dungeon.state.run_members.duplicate()
	if members.is_empty(): return
	var eligible: bool = dungeon.rewards.reward_available("dofufu_boss", 0)
	var drop: WorldItemDrop = _spawn(dungeon, "mature_bean", at) if eligible else null
	if eligible and drop == null:
		if dungeon.puzzle_enabled: dungeon.puzzle_flow.reset_encounter(dungeon)
		else: dungeon._spawned_stage = -1
		return
	if dungeon.puzzle_enabled and not dungeon.puzzle_runtime.boss_defeated("dofufu_boss"):
		if drop != null: dungeon.game.world_items.pool.remove(drop.drop_id)
		return
	var payout: Dictionary = dungeon.rewards.complete_confirmed_boss(members)
	if not bool(payout.get("valid", false)):
		if drop != null: dungeon.game.world_items.pool.remove(drop.drop_id)
		return
	if not bool(payout.get("practice", false)):
		dungeon.state.mark_rewarded(str(payout.identity))
		_award_experience(dungeon, at, int(payout.experience))
	dungeon.state.stage = TofuDungeonState.STATIONS.size()
	dungeon.state.completed = true
	dungeon.state.changed.emit()
	dungeon.factory.process_finished(5)
	dungeon.game.hud.announce("Refinery skill unlocked — bean currency can now be refined.")
	if dungeon.game.player != null and dungeon.actor_in_run(dungeon.game.player):
		dungeon.journal.play_unlock()

static func _spawn(dungeon: TofuDungeon, item_id: String, at: Vector3) -> WorldItemDrop:
	var drop: WorldItemDrop = dungeon.game.world_items.pool.spawn(item_id, 10, at, Vector2.RIGHT)
	if drop != null: return drop
	var room: int = TofuFactory.room_at(at)
	if room < 0 or room > 5: return null
	return dungeon.game.world_items.pool.spawn(item_id, 10, TofuFactory.recovery_anchor(room), Vector2.RIGHT)

static func _award_experience(dungeon: TofuDungeon, at: Vector3, amount: int) -> void:
	if dungeon.cooperative:
		var winner: CoopActor = dungeon._nearest_member(at)
		if winner != null: winner.progression.progress.award_experience(amount)
	else:
		dungeon.game.progression.progress.award_experience(amount)

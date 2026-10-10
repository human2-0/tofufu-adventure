class_name DungeonStashes
extends RefCounted
## Host validates exploration rewards and commits one shared reachable drop.

static func submit(dungeon: TofuDungeon, command: TofuPuzzleCommand, actor: Player) -> Dictionary:
	if not is_instance_valid(actor) or not command.valid_shape() or not dungeon.enabled or not dungeon.state.active or not dungeon.actor_in_run(actor): return {"accepted": false}
	if not dungeon.puzzle_runtime._actor_alive(actor): return {"accepted": false}
	if command.run_id != dungeon.puzzle.run_id or command.attempt_id != dungeon.puzzle.attempt_id or not command.object_id.is_empty(): return {"accepted": false}
	if dungeon.puzzle.phase not in [TofuPuzzleContract.Phase.READY, TofuPuzzleContract.Phase.COMPLETE]: return {"accepted": false}
	if command.expected_revision != dungeon.stashes.revision or not dungeon.stashes.available(command.target_id): return {"accepted": false}
	var at: Vector3 = FactoryHiddenChests.position_for(command.target_id)
	var room: int = TofuFactory.room_at(at)
	if room < 0 or room > dungeon.state.stage or TofuFactory.room_at(actor.global_position) != room: return {"accepted": false}
	if actor.global_position.distance_to(at) > DungeonPuzzleRuntime.INTERACTION_RANGE or not dungeon.puzzle_runtime._visible(actor, at): return {"accepted": false}
	var direction: Vector3 = actor.global_position - at
	direction.y = 0
	if direction.length_squared() < 0.001: direction = Vector3.BACK
	var dock: Vector3 = at + direction.normalized() * 0.9
	if not TofuFactory.legal_ground_anchor(dock, dungeon.state.stage): return {"accepted": false}
	var drop: WorldItemDrop = dungeon.game.world_items.pool.spawn("toasted_tofu_chunk", 1, dock, Vector2.ZERO)
	if drop == null: return {"accepted": false}
	if not dungeon.stashes.claim(command.target_id, command.expected_revision):
		dungeon.game.world_items.pool.remove(drop.drop_id)
		return {"accepted": false}
	drop.set_meta("factory_stash", command.target_id)
	dungeon.state.changed.emit()
	return {"accepted": true}

static func present(dungeon: TofuDungeon) -> void:
	if not dungeon.factory.interior_built: return
	var view: FactoryHiddenChests = dungeon.factory.get_node_or_null("HiddenChests")
	if view == null:
		view = FactoryHiddenChests.new()
		view.name = "HiddenChests"
		dungeon.factory.add_child(view)
	view.present(dungeon.stashes.opened)

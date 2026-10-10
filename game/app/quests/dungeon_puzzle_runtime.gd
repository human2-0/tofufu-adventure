class_name DungeonPuzzleRuntime
extends RefCounted
## Authority boundary between a dungeon actor and one production attempt.

const INTERACTION_RANGE: float = 2.8
const TARGET_CLEARANCE: float = 1.8

var dungeon: TofuDungeon
var attempt: TofuDungeonAttempt

func configure(quest: TofuDungeon, production: TofuDungeonAttempt) -> void:
	dungeon = quest
	attempt = production
	_sync_gates()

func submit(command: TofuPuzzleCommand, actor: Player, now_seconds: float) -> Dictionary:
	if command != null and command.action in [TofuPuzzleCommand.Action.ABANDON, TofuPuzzleCommand.Action.RESTART]:
		return _run_action(command, actor)
	if not _can_submit(command, actor, now_seconds): return _rejected()
	var previous_stage: int = int(attempt.stage)
	var result: Dictionary = attempt.submit(command, DungeonMembership.actor_id(dungeon, actor), true, now_seconds)
	if bool(result.get("accepted", false)) and int(attempt.stage) != previous_stage:
		_sync_gates()
	return result

func _run_action(command: TofuPuzzleCommand, actor: Player) -> Dictionary:
	if dungeon == null or attempt == null or not dungeon.enabled or not is_instance_valid(actor): return _rejected()
	if not command.valid_shape() or not dungeon.actor_in_run(actor) or not _actor_alive(actor): return _rejected()
	if command.run_id != attempt.run_id or command.attempt_id != attempt.attempt_id: return _rejected()
	if not command.target_id.is_empty() or not command.object_id.is_empty(): return _rejected()
	if command.action == TofuPuzzleCommand.Action.ABANDON:
		attempt.release_actor(DungeonMembership.actor_id(dungeon, actor))
		if not dungeon.cooperative: attempt.submit(command, 1, true, 0.0)
		DungeonMembership.exit(dungeon, actor)
		dungeon._teleport_actor(actor, TofuFactory.EAST_ENTRANCE + Vector3(-2.5, 0, 0))
		if not dungeon.cooperative: dungeon._inside = false
		return {"accepted": true}
	if attempt.phase != TofuPuzzleContract.Phase.LOCKED: return _rejected()
	var result: Dictionary = attempt.submit(command, DungeonMembership.actor_id(dungeon, actor), true, 0.0)
	if bool(result.get("accepted", false)):
		dungeon.boss_members.clear()
		dungeon.puzzle_flow.reset_encounter(dungeon)
		_sync_gates()
		for participant: Node3D in dungeon._actors_inside():
			dungeon._teleport_actor(participant as Player, TofuFactory.HALL_ARRIVAL)
			dungeon._recovery.seed(DungeonMembership.key_for(dungeon, participant as Player), TofuFactory.HALL_ARRIVAL, 0)
	return result

func encounter_cleared(encounter_id: String) -> bool:
	if dungeon == null or attempt == null or not dungeon.enabled: return false
	if not attempt.encounter_cleared(encounter_id): return false
	_sync_gates()
	return true

func boss_defeated(encounter_id: String) -> bool:
	if dungeon == null or attempt == null or not dungeon.enabled: return false
	if not attempt.boss_defeated(encounter_id): return false
	_sync_gates()
	return true

func release_actor(actor: Player) -> void:
	if attempt != null and is_instance_valid(actor):
		attempt.release_actor(DungeonMembership.actor_id(dungeon, actor))

func _can_submit(command: TofuPuzzleCommand, actor: Player, now_seconds: float) -> bool:
	if dungeon == null or attempt == null or command == null or not is_instance_valid(actor): return false
	if not dungeon.enabled or not dungeon.state.active or not dungeon.actor_in_run(actor): return false
	if not is_finite(now_seconds) or now_seconds < 0.0 or not command.valid_shape(): return false
	if command.run_id != attempt.run_id or command.attempt_id != attempt.attempt_id: return false
	if attempt.stage > TofuPuzzleContract.Stage.PACK: return false
	if attempt.phase != TofuPuzzleContract.Phase.READY and attempt.phase != TofuPuzzleContract.Phase.OPERATING: return false
	if not _actor_alive(actor): return false
	var room: int = TofuFactory.room_at(actor.global_position)
	if command.action == TofuPuzzleCommand.Action.RETURN_PROP and _owns_return(command, actor):
		return room >= 0 and room <= int(attempt.stage)
	var permitted_room: bool = room == int(attempt.stage)
	if attempt.stage == TofuPuzzleContract.Stage.PACK and command.action == TofuPuzzleCommand.Action.PICK_UP:
		permitted_room = room == TofuPuzzleContract.Stage.CUT
	if not permitted_room or room > dungeon.state.stage: return false
	var target: Vector3 = _target_position(command)
	if not target.is_finite() or TofuFactory.room_at(target) != room: return false
	if actor.global_position.distance_to(target) > INTERACTION_RANGE: return false
	return _visible(actor, target)

func _owns_return(command: TofuPuzzleCommand, actor: Player) -> bool:
	var owner: int = DungeonMembership.actor_id(dungeon, actor)
	match attempt.stage:
		TofuPuzzleContract.Stage.SORT: return attempt.sorting.carried_by.get(command.target_id, 0) == owner
		TofuPuzzleContract.Stage.LAB: return attempt.lab.carrier_id == owner and attempt.lab.carried_bottle == command.target_id
		TofuPuzzleContract.Stage.PACK:
			return command.target_id.is_empty() and command.object_id.is_valid_int() and int(command.object_id) in range(6) and attempt.pack.owners[int(command.object_id)] == owner
	return false

func _actor_alive(actor: Player) -> bool:
	if not dungeon.cooperative:
		return actor == dungeon.game.player and dungeon.game.health != null and dungeon.game.health.current > 0.0
	var key: String = DungeonMembership.key_for(dungeon, actor)
	if key.is_empty() or not dungeon.party.has(key): return false
	var member: CoopActor = dungeon.party[key]
	return member.health != null and member.health.current > 0.0

func _target_position(command: TofuPuzzleCommand) -> Vector3:
	match attempt.stage:
		TofuPuzzleContract.Stage.SORT:
			if command.action in [TofuPuzzleCommand.Action.INSPECT, TofuPuzzleCommand.Action.PICK_UP, TofuPuzzleCommand.Action.RETURN_PROP, TofuPuzzleCommand.Action.LOAD_INTAKE]:
				return TofuFactory.object_position(command.target_id)
		TofuPuzzleContract.Stage.LAB:
			if command.action in [TofuPuzzleCommand.Action.INSPECT, TofuPuzzleCommand.Action.PICK_UP, TofuPuzzleCommand.Action.RETURN_PROP, TofuPuzzleCommand.Action.OPEN_TERMINAL, TofuPuzzleCommand.Action.SUBMIT_PASSWORD, TofuPuzzleCommand.Action.POUR]:
				return TofuFactory.object_position(command.target_id)
		TofuPuzzleContract.Stage.PRESS:
			if command.action in [TofuPuzzleCommand.Action.START_PRESS, TofuPuzzleCommand.Action.RETURN_PROP, TofuPuzzleCommand.Action.SET_PRESS_PRESET] and command.target_id in ["traditional_press", "modern_press"]:
				return TofuFactory.object_position(command.target_id)
			if command.action == TofuPuzzleCommand.Action.STOP_PRESS and command.target_id == "modern_press":
				return TofuFactory.object_position(command.target_id)
			if command.action in [TofuPuzzleCommand.Action.PLACE_STONE, TofuPuzzleCommand.Action.RELEASE_PRESS] and command.target_id == "traditional_press":
				return TofuFactory.object_position(command.target_id)
		TofuPuzzleContract.Stage.CUT:
			if command.action == TofuPuzzleCommand.Action.COMMIT_CUTS and command.target_id == "cutter":
				return TofuFactory.object_position(command.target_id)
		TofuPuzzleContract.Stage.PACK:
			if command.action == TofuPuzzleCommand.Action.PICK_UP and command.object_id.is_valid_int():
				return TofuFactory.object_position("slab_" + command.object_id)
			if command.action in [TofuPuzzleCommand.Action.PLACE_SLAB, TofuPuzzleCommand.Action.SEAL_SLOT] and command.target_id.is_valid_int():
				return TofuFactory.object_position("package_" + command.target_id)
	return Vector3(INF, INF, INF)

func _visible(actor: Player, target: Vector3) -> bool:
	var eye: Vector3 = actor.global_position + Vector3.UP * 0.8
	var focus: Vector3 = target + Vector3.UP * 0.8
	for index in 20:
		if target.distance_to(TofuFactory.object_position("container_%02d" % index)) < 0.05:
			focus.y += 0.7
			break
	var query := PhysicsRayQueryParameters3D.create(eye, focus, 1, [actor.get_rid()])
	var hit: Dictionary = actor.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty(): return true
	var collider: Node = hit.get("collider") as Node
	for depth in 4:
		if collider == null: break
		var own_anchor: Vector3 = TofuFactory.object_position(str(collider.get_meta("factory_interaction_id", collider.name)))
		if own_anchor.is_finite() and own_anchor.distance_to(target) < 0.05:
			return (hit.position as Vector3).distance_to(focus) <= TARGET_CLEARANCE
		for identity: String in collider.get_meta("factory_interaction_ids", []):
			if TofuFactory.object_position(identity).distance_to(target) < 0.05:
				return (hit.position as Vector3).distance_to(focus) <= TARGET_CLEARANCE
		collider = collider.get_parent()
	return false

func _sync_gates() -> void:
	if dungeon != null and is_instance_valid(dungeon.factory) and attempt != null:
		# The legacy room index still drives containment and checkpoint placement.
		dungeon.state.stage = int(attempt.stage)
		dungeon.factory.reset_gates(int(attempt.stage))

func _rejected() -> Dictionary:
	return {"accepted": false, "stage": int(attempt.stage) if attempt != null else -1,
		"phase": int(attempt.phase) if attempt != null else -1}

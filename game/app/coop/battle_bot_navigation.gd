class_name BattleBotNavigation
extends RefCounted
## Authority-only cover checks, staggered at ten Hz. Never teleports or changes human input.

var _moves: Dictionary[int, Vector2] = {}
var _shoot: Dictionary[int, bool] = {}
var queries: int = 0

func clear() -> void:
	_moves.clear()
	_shoot.clear()

func adjust(slot: int, command: PlayerCommand, body: Player, state: BattleMatch, tick: int) -> void:
	if (tick + slot) % 6 == 0:
		queries = 0
		_moves[slot] = _steer(body, command.move)
		var ranged := int(state.rows[slot][10]) in [2, 7, 8, 11]
		_shoot[slot] = not ranged or _ray(body, body.position + Vector3.UP * 0.8, command.aim_point).is_empty()
	command.move = _moves.get(slot, command.move)
	if not _shoot.get(slot, false):
		command.attack_held = false
		command.attack_pressed = false
		if int(state.rows[slot][10]) in [2, 7, 8, 11]: command.guard_held = false

func _steer(body: Player, desired: Vector2) -> Vector2:
	if desired.is_zero_approx(): return desired
	var origin := body.position + Vector3.UP * 0.65
	var hit := _ray(body, origin, origin + Vector3(desired.x, 0, desired.y) * 2.2)
	var result := desired
	if not hit.is_empty():
		var normal: Vector3 = hit.normal
		var side := Vector2(normal.x, normal.z).normalized().orthogonal()
		if side.dot(desired) < 0: side = -side
		result = Vector2.ZERO
		for direction: Vector2 in [side, -side]:
			if _ray(body, origin, origin + Vector3(direction.x, 0, direction.y) * 2.2).is_empty():
				result = direction
				break
	if body.is_on_floor() and not result.is_zero_approx():
		var ahead := body.position + Vector3(result.x, 0, result.y) * 1.8
		if _ray(body, ahead + Vector3.UP, ahead + Vector3.DOWN * 2.5).is_empty(): result = Vector2.ZERO
	return result

func _ray(body: Player, from: Vector3, to: Vector3) -> Dictionary:
	queries += 1
	return body.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, 1))

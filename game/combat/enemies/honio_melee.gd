class_name HonioMelee
extends RefCounted
## Committed, dodgeable melee skills. Each Honio owns his timers and aim.
enum Phase { IDLE, WARNING, RUSH, RECOVERY }
enum Skill { JAB, PROTEIN_EXPRESS, TOFU_TENDERIZER }
const SPEED: float = 8.4
const RUSH_SPEED: float = 13.0
const SLAM_RADIUS: float = 3.0
var phase: Phase = Phase.RECOVERY
var remaining: float = 1.25
var special_rest: float = 0
var aim := Vector3.BACK
var facing := Vector3.BACK
var sequence: int = 0
var skill: Skill = Skill.JAB
var impact: float = 0
var interrupt_rest: float = 0
var bark: int = -1
var speech_time: float = 0

func step(mob: HonioMeniono, delta: float) -> Vector3:
	var resting := phase == Phase.RECOVERY
	elapse(delta)
	if resting: return Vector3.ZERO
	return _act(mob, delta)

func elapse(delta: float) -> void:
	interrupt_rest = maxf(0, interrupt_rest - delta)
	impact = maxf(0, impact - delta)
	special_rest = maxf(0, special_rest - delta)
	speech_time = maxf(0, speech_time - delta)
	if phase == Phase.RECOVERY:
		remaining = maxf(0, remaining - delta)
		if remaining == 0: phase = Phase.IDLE

func _act(mob: HonioMeniono, delta: float) -> Vector3:
	if phase == Phase.WARNING:
		remaining = maxf(0, remaining - delta)
		mob._windup = remaining
		if remaining == 0:
			if skill == Skill.PROTEIN_EXPRESS:
				phase = Phase.RUSH
				remaining = 0.58
			else:
				strike(mob)
				recover(1.15 if skill == Skill.TOFU_TENDERIZER else 0.65)
		return Vector3.ZERO
	if phase == Phase.RUSH:
		remaining = maxf(0, remaining - delta)
		if not victims(mob, 1.95, 0.5).is_empty():
			strike(mob)
			recover(1.25)
			return Vector3.ZERO
		if remaining == 0 or not safe_step(mob, aim):
			recover(1.25)
			return Vector3.ZERO
		return aim * RUSH_SPEED
	return _approach(mob, delta)

func _approach(mob: HonioMeniono, delta: float) -> Vector3:
	var home := mob._home - mob.position
	home.y = 0
	if home.length() > mob.leash_radius: mob._returning = true
	if mob._returning:
		if home.length() < 0.5: mob._returning = false
		return _walk(mob, home)
	if not is_instance_valid(mob.quarry): return _walk(mob, SnailSteering._wander(mob, delta)) * 0.2
	var offset := mob.quarry.global_position - mob.global_position
	if offset.length() > 28 or absf(offset.y) > 2.5: return Vector3.ZERO
	if bark < 0: say(4)
	if offset.length() < 2.8 and special_rest <= 0:
		begin(Skill.TOFU_TENDERIZER, offset)
	elif offset.length() < 1.75:
		begin(Skill.JAB, offset)
	elif offset.length() > 4 and offset.length() < 11 and special_rest <= 0 and mob._can_reach_quarry():
		begin(Skill.PROTEIN_EXPRESS, offset)
	else: return _walk(mob, offset)
	mob.targeting.emit(mob.quarry)
	return Vector3.ZERO

func _walk(mob: HonioMeniono, offset: Vector3) -> Vector3:
	offset.y = 0
	if offset.length_squared() < 0.01: return Vector3.ZERO
	var heading := offset.normalized()
	if not safe_step(mob, heading):
		var best := -INF
		var chosen := Vector3.ZERO
		# Keep the previous side around cover; committed rushes never steer this way.
		for angle in [PI / 3, -PI / 3, PI / 2, -PI / 2]:
			var side := heading.rotated(Vector3.UP, angle)
			var alignment := side.dot(facing)
			if alignment > best and safe_step(mob, side):
				chosen = side
				best = alignment
		if chosen.is_zero_approx(): return Vector3.ZERO
		heading = chosen
	facing = heading
	return heading * SPEED

func begin(next: Skill, offset: Vector3) -> void:
	skill = next
	aim = Vector3(offset.x, 0, offset.z).normalized()
	if aim.is_zero_approx(): aim = facing
	facing = aim
	phase = Phase.WARNING
	remaining = [0.5, 0.8, 1.0][skill]
	sequence += 1
	if skill != Skill.JAB: special_rest = 4.5
	say([0, 1, 2][skill])

func strike(mob: HonioMeniono) -> void:
	impact = 0.3
	var radius := SLAM_RADIUS if skill == Skill.TOFU_TENDERIZER else 1.95
	var cone := -1.0 if skill == Skill.TOFU_TENDERIZER else 0.5
	var targets := victims(mob, radius, cone)
	for receiver in targets:
		mob.struck.emit(receiver.body, [18.0, 26.0, 32.0][skill], mob.global_position)
		if skill != Skill.TOFU_TENDERIZER: break

func victims(mob: HonioMeniono, radius: float, cone: float) -> Array[Damageable]:
	var result: Array[Damageable] = []
	var origin := mob.global_position + Vector3.UP * 0.8
	for receiver in mob.survivors:
		if not is_instance_valid(receiver.body) or receiver.current <= 0: continue
		var offset := receiver.body.global_position - mob.global_position
		if absf(offset.y) > 1.4 or offset.length() > radius: continue
		if Vector3(offset.x, 0, offset.z).normalized().dot(aim) < cone: continue
		var ray := PhysicsRayQueryParameters3D.create(origin, receiver.body.global_position + Vector3.UP * 0.8, 1)
		if mob.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): result.append(receiver)
	result.sort_custom(func(a: Damageable, b: Damageable) -> bool:
		return a.global_position.distance_squared_to(origin) < b.global_position.distance_squared_to(origin))
	return result

func recover(seconds: float) -> void:
	phase = Phase.RECOVERY
	remaining = seconds
	if seconds >= 1: say(3)

func say(line: int) -> void:
	bark = line
	speech_time = 2.4

func cancel() -> void:
	var recovery := remaining if phase == Phase.RECOVERY else 0.0
	phase = Phase.RECOVERY
	remaining = maxf(1.25, recovery)
	impact = 0
	speech_time = 0

static func safe_step(mob: TrainingMob, heading: Vector3) -> bool:
	var space := mob.get_world_3d().direct_space_state
	var ahead := mob.global_position + heading * 1.5
	var wall := PhysicsRayQueryParameters3D.create(mob.global_position + Vector3.UP * 0.8, ahead + Vector3.UP * 0.8, 1)
	if not space.intersect_ray(wall).is_empty(): return false
	var floor_ray := PhysicsRayQueryParameters3D.create(ahead + Vector3.UP * 0.5, ahead + Vector3.DOWN * 1.2, 1)
	var floor_hit := space.intersect_ray(floor_ray)
	return not floor_hit.is_empty() and floor_hit.normal.y > 0.65

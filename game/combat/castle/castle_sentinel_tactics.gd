class_name CastleSentinelTactics
extends RefCounted
## Per-guardian combat cadence: ranged strafing, collision-safe sidesteps and shields.

var skill: int = 0
var cycle: int = 0
var dash_time: float = 0.0
var dash_cooldown: float = 0.0
var shield: float = 0.0
var side: float = 1.0
var dash_direction := Vector3.ZERO
const NAMES: Array[String] = ["HAMMER · step back", "EMBER SHARD · take cover", "LUNGE · sidestep"]

func step(guard: CastleSentinel, delta: float, offset: Vector3, clear: bool) -> Vector3:
	dash_cooldown = maxf(0, dash_cooldown - delta)
	shield = maxf(0, shield - delta)
	guard.cooldown = maxf(0, guard.cooldown - delta)
	if dash_time > 0:
		dash_time = maxf(0, dash_time - delta)
		return dash_direction * 13.0
	if guard.windup > 0:
		guard.windup = maxf(0, guard.windup - delta)
		if guard.windup <= 0:
			guard.release_attack(offset, clear)
			guard.cooldown = 1.6
			shield = 0.8
		return Vector3.ZERO
	if clear and guard.cooldown <= 0 and offset.length() < 10:
		skill = 1 if offset.length() > 3.0 else (2 if cycle % 3 == 2 else 0)
		cycle += 1
		guard.windup = 0.7 if skill != 2 else 0.9
		if skill == 2: dash_direction = Vector3(offset.x, 0, offset.z).normalized()
		return Vector3.ZERO
	if clear and guard.ranged_threat and dash_cooldown <= 0:
		request_dash(guard)
		if dash_time > 0: return dash_direction * 13.0
	if clear and offset.length() < 11 and guard.ranged_threat:
		var forward := Vector3(offset.x, 0, offset.z).normalized()
		var tangent := Vector3(forward.z, 0, -forward.x) * side
		return tangent * 3.4 + forward * (-1.2 if offset.length() < 4 else 1.0)
	var destination := guard.destination() - guard.global_position
	destination.y = 0
	return destination.normalized() * 3.2 if destination.length() > 0.25 else Vector3.ZERO

func request_dash(guard: CastleSentinel) -> void:
	if dash_cooldown > 0 or not is_instance_valid(guard.quarry): return
	var direction := guard.quarry.global_position - guard.global_position
	direction.y = 0
	var tangent := Vector3(direction.z, 0, -direction.x).normalized()
	for sign_value in [side, -side]:
		var destination: Vector3 = guard.global_position + tangent * sign_value * 2.1
		if absf(destination.x - 316) > 25.5 or absf(destination.z - 334) > 25.5 or not guard.clear_to(destination): continue
		dash_direction = tangent * sign_value
		dash_time = 0.2
		dash_cooldown = 2.6
		side = -sign_value
		return
	dash_cooldown = 0.45

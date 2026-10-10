class_name LavaKingFighter
extends CharacterBody3D
## Five telegraphed spells, locked fast chunk bursts and a faster second phase.

signal defeated
signal enraged
var target: Damageable
var spells := LavaSpellField.new()
var quarry: Node3D
var origin := Vector3.ZERO
var authoritative: bool = true
var active: bool = false
var phase: int = 1
var skill: int = 0
var cast: float = 0.0
var recovery: float = 0.0
var locked_aim := Vector3.BACK
var facing := Vector2.DOWN
var pose: String = "idle"
var hit_time: float = 0.0
var cycle: int = 0
var burst: int = 0
var burst_clock: float = 0.0
var chunk_aim := Vector3.BACK
const SKILL_NAMES: Array[String] = ["LAVA VOLLEY · dodge sideways", "CINDER RAIN · leave the circles", "CROWN SHOCKWAVE · jump", "MOLTEN FISSURE · leave its path", "FIRE TOFU BURST · get behind cover"]

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.8
	capsule.height = 3.4
	collider.shape = capsule
	collider.position.y = 1.7
	add_child(collider)
	target = Damageable.new()
	target.maximum = 1100
	target.trains_weapons = true
	target.launch_immune = true
	target.knockback_multiplier = 0.0
	target.body = self
	target.position.y = 1.2
	add_child(target)
	target.damage_filter = func(amount: float, _direction: Vector3, _kind: Damageable.HitKind) -> float: return amount if active and authoritative else 0.0
	target.depleted.connect(_defeated)
	target.hit.connect(func(_amount: float, _direction: Vector3) -> void: hit_time = 0.18)
	spells.owner_body = self
	add_child(spells)

func begin(players: int) -> void:
	global_position = origin
	active = true
	phase = 1
	cycle = 0
	burst = 0
	burst_clock = 0
	cast = 0
	recovery = 1.8
	target.maximum = 1100 * (1 + 0.6 * (clampi(players, 1, 4) - 1))
	target.current = target.maximum
	target.invulnerability = 0
	spells.clear()

func _physics_process(delta: float) -> void:
	if not active: return
	if burst > 0:
		burst_clock -= delta
		if burst_clock <= 0:
			spells.bolt(global_position + Vector3.UP * 1.4, chunk_aim, 30 if phase == 1 else 34, true)
			burst -= 1
			burst_clock = 0.14 if phase == 1 else 0.11
	hit_time = maxf(0, hit_time - delta)
	if phase == 1 and target.current <= target.maximum * 0.55:
		phase = 2
		enraged.emit()
	if not is_instance_valid(quarry): return
	var direction := quarry.global_position - global_position
	direction.y = 0
	if direction.length_squared() > 0.01: facing = Vector2(direction.x, direction.z).normalized()
	velocity = Vector3.ZERO
	if cast > 0:
		cast -= delta
		pose = "channel"
		if cast <= 0:
			_release()
			pose = "release"
			recovery = 1.6 if phase == 1 else 1.05
	else:
		recovery -= delta
		pose = "release" if recovery > (1.3 if phase == 1 else 0.75) else ("idle" if recovery > 0.9 else "walk")
		if recovery <= 0:
			_windup(direction)
		elif recovery < 0.8:
			var tangent := Vector3(direction.z, 0, -direction.x).normalized()
			var desired := global_position + tangent * delta * (2.3 if phase == 1 else 3.1)
			if absf(desired.x - origin.x) < 20 and absf(desired.z - origin.z) < 20: velocity = tangent * (2.3 if phase == 1 else 3.1)
	if hit_time > 0 and cast <= 0: pose = "hit"
	if burst > 0: pose = "release"
	velocity.y = -1
	move_and_slide()

func _windup(direction: Vector3) -> void:
	skill = cycle % 5
	cycle += 1
	locked_aim = direction.normalized() if direction.length_squared() > 0.01 else Vector3.BACK
	cast = 1.15 if phase == 1 else 0.95
	if skill == 4:
		cast = 0.5 if phase == 1 else 0.36
		chunk_aim = (quarry.global_position + Vector3.UP * 0.75 - (global_position + Vector3.UP * 1.4)).normalized() if is_instance_valid(quarry) else locked_aim
	if skill == 1:
		for actor in spells.actors:
			spells.mark(actor.global_position, cast + 0.4)
		if phase == 2: spells.mark(origin, cast + 0.75, 3.4)
	elif skill == 2: spells.shockwave(Vector3(global_position.x, origin.y, global_position.z))
	elif skill == 3:
		for i in 4: spells.mark(global_position + locked_aim * (3.5 + i * 3.5), cast + i * 0.22, 2.3)

func _release() -> void:
	if skill == 4:
		burst = 3 if phase == 1 else 4
		burst_clock = 0
		return
	if skill != 0: return
	var at := global_position + Vector3.UP * 1.1
	var aim := (quarry.global_position + Vector3.UP * 0.7 - at).normalized()
	# Locked planar aim prevents the volley from following a successful dodge.
	aim = Vector3(locked_aim.x, aim.y, locked_aim.z).normalized()
	for i in [-1, 0, 1]: spells.bolt(at, aim.rotated(Vector3.UP, i * 0.22))
	if phase == 2:
		for i in [-2, 2]: spells.bolt(at, aim.rotated(Vector3.UP, i * 0.22))

func _defeated() -> void:
	active = false
	burst = 0
	pose = "defeat"
	velocity = Vector3.ZERO
	spells.clear()
	defeated.emit()

func reset() -> void:
	active = false
	burst = 0
	pose = "idle"
	global_position = origin
	target.current = target.maximum
	cast = 0
	recovery = 0
	spells.clear()

func capture() -> Dictionary:
	return {"position": [global_position.x, global_position.y, global_position.z], "health": target.current,
		"maximum": target.maximum, "active": active, "phase": phase, "skill": skill, "cast": maxf(0, cast),
		"recovery": maxf(0, recovery), "cycle": cycle, "locked_aim": [locked_aim.x, locked_aim.y, locked_aim.z], "facing": [facing.x, facing.y], "pose": pose, "spells": spells.capture(),
		"burst": burst, "burst_clock": maxf(0, burst_clock), "chunk_aim": [chunk_aim.x, chunk_aim.y, chunk_aim.z]}

func apply(data: Dictionary, authority: bool) -> void:
	authoritative = authority
	global_position = Vector3(data.position[0], data.position[1], data.position[2])
	target.current = data.health
	target.maximum = data.maximum
	active = data.active
	phase = int(data.phase)
	skill = int(data.skill)
	cast = data.cast
	recovery = data.recovery
	cycle = int(data.cycle)
	locked_aim = Vector3(data.locked_aim[0], data.locked_aim[1], data.locked_aim[2])
	facing = Vector2(data.facing[0], data.facing[1])
	pose = data.pose
	burst = int(data.burst)
	burst_clock = data.burst_clock
	chunk_aim = Vector3(data.chunk_aim[0], data.chunk_aim[1], data.chunk_aim[2])
	spells.apply(data.spells)
	spells.authoritative = authority
	set_physics_process(authority)

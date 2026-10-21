class_name BattleMobRanged
extends RefCounted
## One swept, reflectable shot per hunt; committed aim, cover and bounded work.
var game: BattleRoyaleGame
var mob: TrainingMob
var profile: BattleHuntProfile
var warning: Label3D
var projectile: SoyProjectile
var rest: float = 0.75
var windup: float = 0
var aim := Vector3.ZERO
var sequence: int = 0
var site_id: int = -1

func build(owner_game: BattleRoyaleGame, actor: TrainingMob, kind: int, id: int) -> void:
	game = owner_game
	site_id = id
	mob = actor
	profile = BattleHuntProfile.make(kind)
	warning = MobLabels.make(mob, "RANGED!", 42, 0.012, Color("ff855d"), mob._nameplate_height() + 0.95)
	warning.visibility_range_end = 110
	warning.hide()

func step(delta: float, awake: bool) -> void:
	# Fired attacks outlive the shooter, so killing at range cannot erase the threat.
	if is_instance_valid(projectile) and not projectile.is_queued_for_deletion(): projectile._physics_process(delta)
	rest = maxf(0, rest - delta)
	if not awake or mob.target.current <= 0 or not mob.visible or mob.target.paralysis > 0:
		windup = 0
		warning.hide()
		return
	if windup > 0:
		windup = maxf(0, windup - delta)
		if windup <= 0:
			warning.hide()
			rest = profile.cooldown
			if _can_see(): _fire()
		return
	if rest > 0 or mob._windup > 0 or _flying(): return
	rest = 0.25 # Blocked sight checks run at most four times per second.
	if not _can_see(): return
	aim = _lead()
	windup = profile.windup
	warning.show()

func _can_see() -> bool:
	if not is_instance_valid(mob.quarry): return false
	var at := mob.quarry.global_position + Vector3.UP * 0.7
	if at.distance_squared_to(_origin()) > profile.reach * profile.reach: return false
	var ray := PhysicsRayQueryParameters3D.create(_origin(), at, 1)
	return game.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func _lead() -> Vector3:
	var velocity: Vector3 = mob.quarry.velocity if mob.quarry is CharacterBody3D else Vector3.ZERO
	velocity.y = 0
	var offset := mob.quarry.global_position + Vector3.UP * 0.7 + velocity * profile.windup - _origin()
	var a := velocity.length_squared() - profile.speed * profile.speed
	var b := 2 * offset.dot(velocity)
	var c := offset.length_squared()
	var time := offset.length() / profile.speed
	var discriminant := b * b - 4 * a * c
	if absf(a) > 0.001 and discriminant >= 0:
		var first := (-b - sqrt(discriminant)) / (2 * a)
		var second := (-b + sqrt(discriminant)) / (2 * a)
		if first > 0: time = first
		if second > 0 and second < time: time = second
	return (offset + velocity * minf(time, 3.6)).normalized()

func _origin() -> Vector3:
	return mob.global_position + Vector3.UP * 0.7

func _flying() -> bool:
	return is_instance_valid(projectile) and not projectile.is_queued_for_deletion()

func _create(authority: bool) -> void:
	projectile = SoyProjectile.new()
	projectile.authoritative = authority
	projectile.owner_health = mob.target
	projectile.shooter = mob
	projectile.body_damage = profile.damage
	projectile.head_damage = profile.damage # No random AI headshot spikes.
	for fighter in game.combat.fighters: projectile.targets.append(fighter.health)
	game.add_child(projectile)
	projectile.set_physics_process(false)
	projectile._sprite.modulate = Color("ff9868")
	projectile._sprite.pixel_size = 0.004

func _fire() -> void:
	if _flying(): return
	_create(true)
	projectile.global_position = _origin()
	projectile.velocity = aim * profile.speed
	projectile.remaining = 4
	projectile.place_visual(projectile.global_position)
	sequence += 1
	game.presentation.gunfire.hunt(site_id, sequence, _origin())

func capture() -> Array:
	var at: Vector3 = projectile.global_position if _flying() else Vector3.ZERO
	var velocity: Vector3 = projectile.velocity if _flying() else Vector3.ZERO
	var life: float = maxf(0, projectile.remaining) if _flying() else 0
	return BattleCombatWire.precision([rest, windup, aim.x, aim.y, aim.z, at.x, at.y, at.z, velocity.x, velocity.y, velocity.z, life, sequence])

func present(row: Array, delta: float = 0) -> void:
	warning.visible = mob.visible and row[1] > 0
	game.presentation.gunfire.hunt(site_id, int(row[12]), _origin())
	if row[11] <= 0:
		if _flying(): projectile.queue_free()
		return
	if sequence != int(row[12]) and _flying(): projectile.queue_free()
	sequence = int(row[12])
	if not _flying(): _create(false)
	var at := Vector3(row[5], row[6], row[7])
	if delta > 0 and projectile.global_position.distance_squared_to(at) < 25:
		at = projectile.global_position.lerp(at, 1.0 - exp(-30 * delta))
	projectile.global_position = at
	projectile.velocity = Vector3(row[8], row[9], row[10])
	projectile.remaining = row[11]
	projectile.place_visual(projectile.global_position)

func restore(row: Array) -> void:
	if _flying(): projectile.queue_free()
	rest = maxf(0.75, float(row[0]))
	windup = 0
	aim = Vector3(row[2], row[3], row[4])
	sequence = int(row[12])
	warning.hide()

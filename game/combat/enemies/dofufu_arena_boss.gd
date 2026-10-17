class_name DofufuArenaBoss
extends CharacterBody3D
## Solo authority boss. App injects target, navigation and damage policy.

var quarry: Node3D
var victim: Damageable
var hurt: Callable
var navigate: Callable
var target: Damageable
var art: DofufuVisuals
var warning: DofufuWarning
var rules := DofufuRules.new()
var facing := Vector3.LEFT
var committed := Vector3.LEFT
var running: bool = false
var rush_remaining: float = 0.0
var rush_hit: bool = false
var _route_clock: float = 0.0
var _destination := Vector3.ZERO
var _echo_clock: float = 0.0
var _action_pose: float = 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 3
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 2.2
	collider.shape = capsule
	collider.position.y = 1.1
	add_child(collider)
	target = Damageable.new()
	target.paralysis_allowed = true
	target.maximum = 2400.0
	target.body = self
	target.position.y = 1.0
	target.headshot_height = 1.55
	target.launch_immune = true
	target.knockback_multiplier = 0.15
	add_child(target)
	target.hit.connect(_hit)
	art = DofufuVisuals.new()
	add_child(art)
	warning = DofufuWarning.new()
	add_child(warning)

func _physics_process(delta: float) -> void:
	if not running or target.current <= 0.0 or not is_instance_valid(quarry): return
	if EnemyParalysis.hold(self, target, delta): return
	rules.enraged = target.current <= target.maximum * 0.5
	_action_pose = maxf(0.0, _action_pose - delta)
	var offset := quarry.global_position - global_position
	offset.y = 0.0
	var distance := offset.length()
	if rules.windup <= 0.0 and rush_remaining <= 0.0 and distance > 0.01: facing = offset.normalized()
	if rules.windup <= 0.0 and rules.recovery <= 0.0 and rush_remaining <= 0.0:
		if distance < 19.0 and _clear_line(global_position, victim.global_position):
			rules.begin(distance)
			committed = facing
			warning.show_skill(rules.skill, global_position, committed)
	var fired := rules.step(delta)
	if fired:
		_action_pose = 0.3
		warning.hide()
		_execute()
	var planar := Vector3.ZERO
	if rush_remaining > 0.0:
		_echo_clock -= delta
		if _echo_clock <= 0.0:
			DofufuVFX.echo(art)
			_echo_clock = 0.1
		rush_remaining = maxf(0.0, rush_remaining - delta)
		planar = committed * 22.0
	elif rules.windup <= 0.0 and distance > 2.6:
		_route_clock -= delta
		if _route_clock <= 0.0:
			_destination = navigate.call(global_position, quarry.global_position) if navigate.is_valid() else quarry.global_position
			_route_clock = 0.3
		var route := _destination - global_position
		route.y = 0.0
		planar = route.normalized() * (6.8 if rules.enraged else 5.0)
	velocity.x = planar.x
	velocity.z = planar.z
	velocity.y = maxf(-30.0, velocity.y - 30.0 * delta)
	move_and_slide()
	if rush_remaining > 0.0 and not rush_hit and _within(1.8):
		rush_hit = true
		hurt.call(40.0, global_position, committed * 7.0)
	art.present(committed if rules.windup > 0.0 or rush_remaining > 0.0 else facing, planar.length_squared() > 0.1, rules.windup > 0.0 or rush_remaining > 0.0 or _action_pose > 0.0, rules.enraged, delta)

func _execute() -> void:
	match rules.skill:
		DofufuRules.Skill.FAN:
			for index in (7 if rules.enraged else 5):
				var blade := DofufuBlade.new()
				blade.shooter = self
				blade.victim = victim
				blade.boss_health = target
				blade.hurt = hurt
				blade.velocity = committed.rotated(Vector3.UP, (index - (3 if rules.enraged else 2)) * 0.16) * 19.0
				add_child(blade)
				blade.global_position = global_position + Vector3.UP * 0.8 + committed * 0.6
		DofufuRules.Skill.DRAGON_STEP:
			rush_remaining = 0.6
			rush_hit = false
		DofufuRules.Skill.SLAM:
			DofufuVFX.wave(self, global_position, 5.5)
			CombatEffects.burst(self, global_position + Vector3.UP, "GONG!", Color("ffcc75"))
			if _within(5.5) and quarry.global_position.y - global_position.y < 1.0:
				hurt.call(55.0, global_position, facing * 8.0)
		DofufuRules.Skill.GLAIVE:
			DofufuVFX.wave(self, global_position, 3.4)
			var offset := quarry.global_position - global_position
			offset.y = 0.0
			if _within(3.4) and offset.normalized().dot(committed) > 0.35:
				hurt.call(32.0, global_position, committed * 5.0)

func _within(radius: float) -> bool:
	return global_position.distance_to(quarry.global_position) <= radius and _clear_line(global_position, victim.global_position)

func _clear_line(at: Vector3, destination: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.8, destination, 1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func clear_attacks() -> void:
	running = false
	rush_remaining = 0.0
	velocity = Vector3.ZERO
	warning.hide()
	for child in get_children():
		if child is DofufuBlade: child.queue_free()

func _hit(_amount: float, _direction: Vector3) -> void:
	CombatEffects.sparks(self, target.global_position)

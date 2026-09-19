extends SceneTree
## Real collision sweeps, head regions, cadence and hostile input validation.
var failures: int = 0
var stage: Node3D
var gun: SoyGun
var dummy: PracticeDummy

func _initialize() -> void: call_deferred("_run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func ticks(count: int) -> void:
	for index in count:
		await physics_frame
		await process_frame

func _run() -> void:
	stage = Node3D.new()
	root.add_child(stage)
	var actor: Player = load("res://game/player/player.tscn").instantiate()
	stage.add_child(actor)
	actor.set_physics_process(false)
	var combat := PlayerCombat.new()
	combat.actor = actor
	stage.add_child(combat)
	var progression := ActorProgression.new()
	progression.actor = actor
	progression.combat = combat
	stage.add_child(progression)
	gun = combat.gun
	gun.tuning = CombatTuning.new()
	gun.tuning.aim_spread_degrees = 0
	dummy = PracticeDummy.new()
	stage.add_child(dummy)
	dummy.position = Vector3(0, 0, -5)
	dummy.target.trains_weapons = true
	gun.targets.append(dummy.target)
	await ticks(3)
	combat.equipment.step(Vector2.UP, false, false, false, false, 3, 0.016)
	check(gun.selected and combat.equipment.suppress_slash(), "slot 3 selects gun and suppresses knife")
	gun.step(true, true, Vector2.UP, Vector3(0, 0.65, -5), 0.016)
	gun.step(true, true, Vector2.UP, Vector3(0, 0.65, -5), 0.016)
	var from_body := gun.shot_origin - actor.global_position
	check(from_body.x > 0.3 and from_body.z < -0.4 and from_body.y > 0.7, "authoritative beans originate at the forward outboard muzzle")
	check(gun.shot_sequence == 1, "held trigger obeys per-instance cadence")
	await ticks(10)
	check(gun.get_children().any(func(child: Node) -> bool: return child is LiquidImpact), "soybean collision creates a round splash at the target")
	check(dummy.target.current == 180, "fast swept soybean hits body for exactly 20")
	gun.cooldown = 0
	gun.step(true, true, Vector2.UP, Vector3(0, 1.85, -5), 0.016)
	await ticks(10)
	check(dummy.target.current == 140, "upper hit region deals exactly 40")
	# A thin wall between shooter and dummy must absorb the entire fast segment.
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3, 3, 0.02)
	shape.shape = box
	wall.add_child(shape)
	stage.add_child(wall)
	wall.position = Vector3(0, 0.7, -2.5)
	await ticks(2)
	gun.cooldown = 0
	gun.step(true, true, Vector2.UP, Vector3(0, 0.65, -5), 0.016)
	await ticks(10)
	check(dummy.target.current == 140, "thin world wall blocks fast projectile")
	wall.free()
	# A muzzle pushed beyond thin cover must not bypass the cover.
	var muzzle_wall := StaticBody3D.new()
	var muzzle_shape := CollisionShape3D.new()
	muzzle_shape.shape = box
	muzzle_wall.add_child(muzzle_shape)
	stage.add_child(muzzle_wall)
	muzzle_wall.position = Vector3(0, 0.7, -0.2)
	await ticks(2)
	gun.cooldown = 0
	gun.step(true, true, Vector2.UP, Vector3(0, 0.65, -5), 0.016)
	await ticks(10)
	check(dummy.target.current == 140, "cover between actor and muzzle blocks firing through it")
	muzzle_wall.free()
	# A replica can draw a shot but cannot change health.
	gun.present_shot(0, Vector3.ZERO, Vector3.ZERO)
	gun.present_shot(1, Vector3(0, 0.65, 0), Vector3(0, 0, -55))
	await ticks(10)
	check(dummy.target.current == 140, "replicated projectile never decides damage")
	check(progression.progress.practice.shooting == 2, "only two confirmed authoritative dummy hits train shooting")
	progression.progress.practice.shooting = CharacterProgress.threshold(20) * 4
	progression.progress.speed_gear_trained(CharacterProgress.threshold(99))
	check(gun.damage_multiplier > 1 and gun.spread_multiplier < 1, "progression applies gun damage and accuracy")
	gun.reset()
	gun.step(true, true, Vector2.UP, Vector3(0, 0.65, -5), 0.016)
	var sequence := gun.shot_sequence
	gun.step(true, true, Vector2.UP, Vector3(0, 0.65, -5), 0.15)
	check(gun.shot_sequence == sequence + 1, "trained attack speed fires again before base cooldown")
	var bean := gun.get_child(gun.get_child_count() - 1) as SoyProjectile
	check(is_equal_approx(bean.body_damage, 20 * gun.damage_multiplier) and is_equal_approx(bean.head_damage, 40 * gun.damage_multiplier), "both projectile damage regions scale with skill")
	var hip_max := 0.0
	var aim_max := 0.0
	for index in 1000:
		hip_max = maxf(hip_max, Vector3.FORWARD.angle_to(gun.spread(Vector3.FORWARD, 5)))
		aim_max = maxf(aim_max, Vector3.FORWARD.angle_to(gun.spread(Vector3.FORWARD, 0.35)))
	check(hip_max > deg_to_rad(4) and aim_max <= deg_to_rad(0.36), "ADS is substantially tighter than hip fire")
	var command := PlayerCommand.new()
	command.weapon_slot = 3
	command.aim_point = Vector3(0, 1.85, -5)
	var wire := CoopValues.input(command, 1, 0)
	check(ExplorationProtocol.valid_input(wire), "slot 3 and bounded aim point accepted")
	check(CoopValues.command(wire).aim_point == command.aim_point, "wire round trip retains vertical aim")
	wire.aim_point = [0, NAN, 0]
	check(not ExplorationProtocol.valid_input(wire), "nonfinite gun aim rejected")
	var state := CombatState.capture(combat)
	check(ExplorationProtocol.combat(state), "gun snapshot schema valid")
	state.shot_velocity = [0, INF, 0]
	check(not ExplorationProtocol.combat(state), "nonfinite replica velocity rejected")
	combat.equipment.step(Vector2.UP, false, false, false, false, 2, 0.016)
	check(not gun.selected, "switching away hides gun")
	var camera := CameraFollow.new()
	camera.target = actor
	stage.add_child(camera)
	camera.current = true
	camera.set_physics_process(false)
	camera.set_shoulder(true)
	camera.yaw = PI * 0.5
	camera._follow_shoulder(0.016)
	actor.visuals.present(command, Vector3.ZERO, true, false, 0.016)
	command.aim = Vector2.UP
	actor.visuals.present(command, Vector3.ZERO, true, false, 0.016)
	check(actor.visuals.current_facing == FufuVisuals.Facing.RIGHT, "world north becomes screen right after a quarter orbit")
	check(actor.visuals.billboard == BaseMaterial3D.BILLBOARD_ENABLED, "Fufu remains fully billboarded during orbit")
	var local := actor.command_source as LocalPlayerInput
	local.shoulder_view = true
	var retained := local.sample(Vector3.ZERO)
	camera.orbit(Vector2(160, -60))
	camera._follow_shoulder(0.016)
	var orbited := local.sample(Vector3.ZERO)
	check(orbited.aim.is_equal_approx(retained.aim) and orbited.aim_point.is_equal_approx(retained.aim_point), "free orbit preserves character and firing aim without a held key")
	Input.action_press("attack")
	var hip := local.sample(Vector3.ZERO)
	check(not hip.aim.is_equal_approx(retained.aim) and hip.attack_held and not hip.guard_held, "LMB immediately refocuses hip fire without enabling precise aim")
	camera.orbit(Vector2(140, 30))
	camera._follow_shoulder(0.016)
	var tracking := local.sample(Vector3.ZERO)
	check(not tracking.aim.is_equal_approx(hip.aim), "held hip fire follows camera orbit continuously")
	Input.action_release("attack")
	camera.orbit(Vector2(-140, -30))
	camera._follow_shoulder(0.016)
	check(local.sample(Vector3.ZERO).aim.is_equal_approx(tracking.aim), "releasing fire returns to independent orbit")
	Input.action_press("guard")
	var focused := local.sample(Vector3.ZERO)
	check(not focused.aim.is_equal_approx(retained.aim) and focused.guard_held, "RMB turns character into camera aiming direction")
	Input.action_release("guard")
	camera.orbit(Vector2(-260, 100))
	camera._follow_shoulder(0.016)
	var released := local.sample(Vector3.ZERO)
	check(released.aim.is_equal_approx(focused.aim), "releasing RMB retains the new character aim")
	var focused_direction := (focused.aim_point - Vector3.UP * 0.65).normalized()
	check((released.aim_point - Vector3.UP * 0.65).normalized().is_equal_approx(focused_direction), "free orbit preserves vertical firing aim too")
	camera.yaw = PI * 0.5
	camera._follow_shoulder(0.016)
	Input.action_press("move_up")
	var movement := local.sample(Vector3.ZERO)
	Input.action_release("move_up")
	check(movement.move.x < -0.99 and absf(movement.move.y) < 0.01, "shoulder movement follows camera orientation")
	local.chat_blocked = true
	check(local.sample(Vector3.ZERO).cancel_actions, "chat neutralizes shooting commands")
	local.chat_blocked = false
	camera.yaw = 0
	var camera_wall := StaticBody3D.new()
	var camera_shape := CollisionShape3D.new()
	camera_shape.shape = box
	camera_wall.add_child(camera_shape)
	stage.add_child(camera_wall)
	camera_wall.position = Vector3(0, 1, 2.5)
	await ticks(2)
	camera._follow_shoulder(0.016)
	check(camera.position.z < 2.5, "shoulder camera retracts before a world wall")
	camera.set_shoulder(false)
	check(camera.position.is_equal_approx(actor.position + camera.offset), "overhead switch restores original camera offset")
	stage.free()
	print("Soy gun: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

extends SceneTree
## Real swept steel, buffered release, physical launch, immunity and cosmetic replica checks.

const DT: float = 1.0 / 60.0
var failures: int = 0
var stage: Node3D
var combat: PlayerCombat
var actor: Node3D

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	stage = Node3D.new()
	root.add_child(stage)
	actor = Node3D.new()
	stage.add_child(actor)
	combat = PlayerCombat.new()
	combat.actor = actor
	stage.add_child(combat)
	combat.critical_roll = func() -> float: return 1.0
	_rules()
	_geometry()
	await _chain_contacts()
	await _buffered_attack()
	await _wall_blocks()
	await _practice_and_blocks()
	await _physical_reactions()
	await _player_reaction()
	_snapshot()
	stage.queue_free()
	await process_frame
	print("Melee flow, contact and reactions: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _rules() -> void:
	var base_chain := KnifeAttack.damage(0, combat.tuning, false) + KnifeAttack.damage(6, combat.tuning, false) + KnifeAttack.damage(1, combat.tuning, false) + KnifeAttack.damage(4, combat.tuning, false)
	check(base_chain < SnailTuning.new().dry_health, "a basic noncritical chain leaves a fresh level-one snail alive to launch")
	check(KnifeAttack.damage(4, combat.tuning, true) == combat.tuning.launcher_damage, "the charged launcher retains its authored damage")
	var rules := MeleeRules.new(combat.tuning)
	rules.cooldown = 0.15
	rules.step(true, DT, 1.0, true)
	check(rules.step(false, DT, 1.0, true) < 0.0 and rules.buffered(), "a release queues once during a committed swing")
	check(rules.step(false, 0.16) >= 0.0, "buffer survives the cooldown and is consumed when ready")
	check(rules.step(false, DT) < 0.0, "a buffered release cannot repeat")
	rules.step(true, DT, 1.0, true)
	rules.step(false, DT, 1.0, true)
	rules.step(false, combat.tuning.input_buffer_seconds + DT, 1.0, true)
	check(not rules.buffered(), "early mashing expires instead of building an attack queue")
	rules.step(true, DT, 1.0, true)
	rules.step(false, DT, 1.0, true)
	rules.cancel_charge()
	check(not rules.buffered(), "guard, equipment and cancellation clear pending attacks")

func _geometry() -> void:
	var tuning := combat.tuning
	for index in 8:
		var aim := Vector2.from_angle(index * PI / 4.0)
		var low := KnifeAttack.pose(KnifeAttack.Style.LAUNCHER, Vector3.ZERO, aim, tuning.cut_start, tuning)
		var high := KnifeAttack.pose(KnifeAttack.Style.LAUNCHER, Vector3.ZERO, aim, tuning.cut_end, tuning)
		check(SwordGeometry.tip(high, tuning).y > SwordGeometry.tip(low, tuning).y + 0.7, "launcher steel rises in every facing")
		var start := KnifeAttack.pose(KnifeAttack.Style.REVERSE_SLASH, Vector3.ZERO, aim, tuning.cut_start, tuning)
		var end := KnifeAttack.pose(KnifeAttack.Style.REVERSE_SLASH, Vector3.ZERO, aim, tuning.cut_end, tuning)
		var side := Vector3(-aim.y, 0, aim.x)
		check((-start.basis.z).dot(side) > 0.5 and (-end.basis.z).dot(side) < -0.5, "reverse slash travels across the opposite side")
		for style in [0, 1, 2, 3, 4, 6]:
			for sample in range(1, 101):
				var a := KnifeAttack.pose(style, Vector3.ZERO, aim, (sample - 1) / 100.0, tuning)
				var b := KnifeAttack.pose(style, Vector3.ZERO, aim, sample / 100.0, tuning)
				check(SwordGeometry.tip(a, tuning).distance_to(SwordGeometry.tip(b, tuning)) < 0.25, "weapon paths continuous: facing %d style %d phase %.2f distance %.3f" % [index, style, sample / 100.0, SwordGeometry.tip(a, tuning).distance_to(SwordGeometry.tip(b, tuning))])

func _chain_contacts() -> void:
	combat.reset()
	var target := _target(Vector3.ZERO)
	var expected := [0, 6, 1, 4, 0, 6, 1, 4]
	for style: int in expected:
		combat.strike(Vector2.DOWN, 0.0)
		check(combat.attack_style == style, "accurate hits cycle slash, reverse, thrust, launcher even after critical cap")
		var pose := combat._attack_pose(Vector3.ZERO, Vector2.DOWN, 0.5)
		target.body.position = pose.origin - pose.basis.z * combat._melee_length() * 0.5
		await physics_frame
		var before := target.current
		var paused := false
		for tick in 60:
			combat.step(Vector2.DOWN, false, DT)
			if combat.hit_pause > DT and not paused:
				var elapsed := combat._elapsed
				combat.step(Vector2.DOWN, false, DT)
				check(is_equal_approx(combat._elapsed, elapsed), "confirmed contact freezes the blade at the impact pose")
				paused = true
			if not combat.active: break
		check(paused, "every real contact produces a bounded impact pause")
		check(is_equal_approx(before - target.current, combat._melee_damage()), "swept steel deals one hit per move")
		check(combat.combo.window_remaining > 1.0, "committed recovery does not consume the follow-up window")
	combat.strike(Vector2.DOWN, 0.0)
	target.body.position = Vector3(8, 0, 8)
	await physics_frame
	for tick in 60: combat.step(Vector2.DOWN, false, DT)
	check(combat.combo.count == 0 and combat.combo.chain == 0, "a missed swing resets the chain")
	combat.targets.clear()
	target.body.queue_free()
	await physics_frame

func _buffered_attack() -> void:
	combat.reset()
	var target := _target(Vector3(0, 0.65, 0.9))
	await physics_frame
	combat.step(Vector2.DOWN, true, DT)
	combat.step(Vector2.DOWN, false, DT)
	for tick in 22: combat.step(Vector2.DOWN, false, DT)
	combat.step(Vector2.RIGHT, true, DT)
	combat.step(Vector2.RIGHT, false, DT)
	check(combat.rules.buffered(), "a tap in the current attack's recovery is retained")
	for tick in 15:
		combat.step(Vector2.UP, false, DT)
		if combat.attack_style == KnifeAttack.Style.REVERSE_SLASH: break
	check(combat.active and combat.attack_style == KnifeAttack.Style.REVERSE_SLASH, "buffered tap starts the next confirmed combo move")
	check(combat.attack_aim == Vector2.RIGHT, "buffer retains the release aim even if the mouse changes during recovery")
	combat.targets.clear()
	target.body.queue_free()
	combat.reset()
	await physics_frame

func _wall_blocks() -> void:
	var wall := StaticBody3D.new()
	wall.collision_layer = 1
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3, 3, 0.1)
	shape.shape = box
	wall.add_child(shape)
	wall.position = Vector3(0, 0.5, 0.5)
	stage.add_child(wall)
	var target := _target(Vector3(0, 0.65, 0.9))
	await physics_frame
	combat.strike(Vector2.DOWN, 0.0)
	for tick in 50: combat.step(Vector2.DOWN, false, DT)
	check(target.current == target.maximum, "wall occlusion prevents damage behind visible steel")
	combat.targets.clear()
	target.body.queue_free()
	wall.queue_free()
	combat.reset()
	await physics_frame

func _physical_reactions() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = 1
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20, 0.2, 20)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position.y = -0.1
	stage.add_child(floor_body)
	var mob := TrainingMob.new()
	mob.quarry = actor
	mob.position = Vector3(3, 0.05, 0)
	stage.add_child(mob)
	await ticks(10)
	mob._windup = 0.5
	mob.target.damage(1, Vector3.UP * 8.0, Damageable.HitKind.KNIFE)
	check(mob._windup == 0 and mob.reaction.stagger > 0, "a real hit cancels enemy wind-up and starts stagger")
	var peak := mob.position.y
	for tick in 60:
		await physics_frame
		peak = maxf(peak, mob.position.y)
	check(peak > 0.8 and mob.position.y < 0.1, "launch is physical, falls with gravity and lands on terrain")
	mob.target.damage(1, Vector3.UP * 8.0, Damageable.HitKind.KNIFE)
	await ticks(10)
	mob.target.damage(1, Vector3.DOWN * 3.0, Damageable.HitKind.KNIFE)
	check(mob.velocity.y <= -3.0, "an aerial downslash reverses the launched enemy's ascent")
	await ticks(35)
	check(mob.position.y < 0.1, "aerial follow-up returns the enemy to physical terrain")
	var armor := ArmoredSnail.new()
	armor.position = Vector3(6, 0.05, 0)
	stage.add_child(armor)
	await ticks(5)
	armor.target.damage(1, Vector3.UP * 8.0, Damageable.HitKind.KNIFE, armor.global_position + Vector3(0, 0.2, 0))
	check(armor.target.launch_immune and armor.velocity.y < 1.0, "intact shell prevents launching even on a vulnerable foot hit")
	armor.set_shell_health(0)
	armor.target.damage(1, Vector3.UP * 8.0, Damageable.HitKind.KNIFE)
	check(not armor.target.launch_immune and armor.velocity.y >= 8.0, "breaking the shell exposes the snail to a launcher")
	var bean := FactorySoyFighter.new()
	bean.position = Vector3(-3, 0.05, 0)
	bean.quarry = actor
	stage.add_child(bean)
	await ticks(5)
	bean.target.damage(1, Vector3.UP * 8.0, Damageable.HitKind.KNIFE)
	check(bean.velocity.y >= 8.0 and bean.reaction.stagger > 0.0, "factory fighters honor vertical melee impulses")
	var boss := Dofufu.new()
	stage.add_child(boss)
	check(boss.target.launch_immune, "the factory boss explicitly resists launching")
	for body in [mob, armor, bean, boss, floor_body]: body.queue_free()
	await physics_frame

func _practice_and_blocks() -> void:
	combat.reset()
	var awards: Array[int] = [0]
	var listener := func(_weapon: String) -> void: awards[0] += 1
	combat.weapon_trained.connect(listener)
	var teammate := _target(Vector3(5, 0, 5))
	combat.strike(Vector2.DOWN, 0.0)
	combat._damage(teammate)
	check(awards[0] == 0, "player/prop contacts cannot farm weapon practice")
	var first := _target(Vector3(5, 0, 6))
	var second := _target(Vector3(6, 0, 5))
	first.trains_weapons = true
	second.trains_weapons = true
	combat._damage(first)
	combat._damage(second)
	check(awards[0] == 1 and combat.combo.count == 1, "a crowd contact trains and advances the chain once per swing")
	combat.reset()
	first.damage_filter = func(_amount: float, _direction: Vector3, _kind: Damageable.HitKind) -> float:
		first.hit_absorbed = true
		return 0.0
	combat.strike(Vector2.DOWN, 0.0)
	combat._damage(first)
	check(combat.hit_pause > 0 and combat.combo.count == 0, "absorbed steel has impact resistance without rewarding a confirmed combo hit")
	combat._elapsed = combat._attack_duration() * 0.89
	combat.rules.step(true, 1.0 / 60.0, 1.0, true)
	combat.rules.step(false, 1.0 / 60.0, 1.0, true)
	combat.step(Vector2.DOWN, false, 1.0 / 60.0)
	check(combat.active, "an absorbed hit retains recovery instead of earning the confirmed-hit cancel")
	combat.weapon_trained.disconnect(listener)
	combat.targets.clear()
	for target in [teammate, first, second]: target.body.queue_free()
	combat.reset()
	await physics_frame

func _player_reaction() -> void:
	var packed := load("res://game/player/player.tscn") as PackedScene
	var player := packed.instantiate() as Player
	player.command_source = PlayerCommandSource.new()
	player.add_child(player.command_source)
	stage.add_child(player)
	player.set_physics_process(false)
	var health := Damageable.new()
	health.body = player
	player.add_child(health)
	var player_combat := PlayerCombat.new()
	player_combat.actor = player
	stage.add_child(player_combat)
	health.hit.connect(ActorMeleeImpact.receive.bind(player, player_combat, health))
	health.restored.connect(player.motor.impact.clear)
	player_combat.strike(Vector2.DOWN, 0.0)
	health.damage(1, Vector3(2, 8, 0), Damageable.HitKind.KNIFE)
	check(player.motor.impact.remaining > 0 and player.velocity.y == 8.0 and not player_combat.active, "player contact interrupts a swing and applies real launch velocity")
	var command := PlayerCommand.new()
	command.move = Vector2.LEFT
	command.jump_pressed = true
	command.dash_pressed = true
	var motion := player.motor.step(command, player.velocity, true, DT)
	check(motion.x > 0 and motion.y > 7.0 and not player.motor.is_dashing, "hit recoil cannot be overwritten by movement, jump or dash on its first tick")
	var snapshot := player.motor.impact.capture()
	check(ExplorationProtocol.impact(snapshot), "player recoil is a bounded co-op record")
	var prediction := CoopPrediction.new()
	prediction.actor = player
	prediction.initialized = true
	prediction.respawns = 0
	prediction.accept({"position": [0,0,0], "velocity": [2,7,0], "health": 59, "respawns": 0, "impact": snapshot})
	check(player.velocity.y == 7 and player.motor.impact.remaining > 0, "guest prediction adopts host recoil and vertical velocity")
	health.restore()
	check(player.motor.impact.remaining == 0.0, "restoring health clears transient player recoil")
	player.queue_free()
	player_combat.queue_free()
	await physics_frame

func _snapshot() -> void:
	combat.reset()
	combat.active = true
	combat._elapsed = 0.25
	combat._previous_elapsed = 0.23
	combat.hit_pause = 0.045
	combat.attack_aim = Vector2.RIGHT
	var physical := combat._attack_pose(Vector3.ZERO, combat.attack_aim, 0.5)
	combat.clash.record(physical, true)
	combat.render_position = func() -> Vector3: return Vector3(0.1, 0, 0)
	MeleePose.render(combat)
	check(combat.clash._pose == physical and combat.clash._ready, "render interpolation never overwrites authoritative clash samples")
	var rendered := combat._attack_pose(Vector3(0.1, 0, 0), combat.attack_aim, combat._elapsed / combat._attack_duration())
	check(combat.sword.model_tip_position().distance_to(combat._melee_tip(rendered)) < 0.001, "paused render uses the impact curve at the interpolated actor position")
	combat.reset()
	combat.attack_style = KnifeAttack.Style.REVERSE_SLASH
	combat.hit_pause = combat.tuning.heavy_hit_pause
	var state := CombatState.capture(combat)
	check(ExplorationProtocol.combat(state), "reverse swing and impact pause pass the live protocol")
	var before := combat.targets.size()
	CombatState.present(combat, state, Vector2.DOWN)
	check(combat.targets.size() == before, "replica presentation never resolves new contacts")
	state.hit_pause = 2.0
	check(not ExplorationProtocol.combat(state), "protocol rejects excessive impact pause")
	state.hit_pause = 0.0
	state.style = 99
	check(not ExplorationProtocol.combat(state), "protocol rejects undefined melee styles")

func _target(at: Vector3) -> Damageable:
	var body := StaticBody3D.new()
	body.collision_layer = 2
	body.position = at
	var collider := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.18
	collider.shape = sphere
	body.add_child(collider)
	stage.add_child(body)
	var target := Damageable.new()
	target.maximum = 1000.0
	target.body = body
	body.add_child(target)
	combat.targets.append(target)
	return target

func ticks(count: int) -> void:
	for tick in count: await physics_frame

func check(condition: bool, message: String) -> void:
	if condition: return
	failures += 1
	printerr("FAIL: ", message)

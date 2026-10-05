extends SceneTree
## Real ranged collision, dodge/cover, village exclusion, rewards and bounded replicas.

var failures: int = 0
var game: AdventureGame
var bee: WildBee
var origin := Vector3(200, 20, 100)

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func ticks(count: int) -> void:
	for index in count:
		await physics_frame
		await process_frame

func _run() -> void:
	game = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.player.set_physics_process(false)
	game.weather.set_physics_process(false)
	for mob in game.encounters.mob_nodes: mob.set_physics_process(false)
	_spawn_checks()
	bee = game.encounters.mob_nodes[39] as WildBee
	await _runtime_ground_checks()
	bee.position = origin
	bee._home = origin
	game.player.position = origin + Vector3.BACK * 6.0
	bee.quarry = game.player
	await ticks(2)
	await _ranged_checks()
	await _cover_checks()
	_safe_and_leash_checks()
	await _snapshot_checks()
	await _gun_and_rewards()
	game.queue_free()
	await process_frame
	print("Wild bees: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _spawn_checks() -> void:
	check(game.encounters.mob_nodes.size() == WorldProtocol.CURRENT_MOB_COUNT, "expanded roster has stable legacy indices")
	for index in 4:
		var mob := game.encounters.mob_nodes[39 + index] as WildBee
		check(mob != null and mob.LEVEL == 3, "four appended level-three bees")
		if mob == null: continue
		var spawn := FarmCombatGrounds.BEE_SPAWNS[index]
		check(mob.position.distance_to(game.world.ground_point(spawn.x, spawn.y, 0.1)) < 0.01, "bee sits on the southern terrain")
		check(spawn.y >= 70 and not MeadowVillage.BOUNDS.grow(40).has_point(spawn), "bee spawns far south of village")
		check(mob.visible and mob.target.current == 100, "bees are active with 100 HP in clear weather")
		mob.set_rain(true)
		check(mob.visible and mob.target.current == 100, "rain preserves bee strength")
		mob.set_rain(false)

func _runtime_ground_checks() -> void:
	var home := bee._home
	game.player.position = game.world.ground_point(home.x, home.z + 6.0, 0.1)
	game.health.invulnerability = 0.0
	var before := game.health.current
	bee.set_physics_process(true)
	await ticks(12)
	check(bee._warning.visible and game.health.current == before, "real bee physics warns on authored meadow terrain")
	await ticks(75)
	check(bee.is_on_floor() and bee.position.y > -4, "bee collision body remains supported by actual terrain")
	check(game.health.current == before - 16, "real warning and flight resolve one ranged hit on terrain")
	bee.set_physics_process(false)

func _prepare() -> void:
	bee.position = origin
	bee._home = origin
	bee.quarry = game.player
	bee._returning = false
	bee._rest = 0.0
	bee._windup = 0.0
	bee.sting.clear()
	game.player.position = origin + Vector3.BACK * 6.0
	game.player.motor.is_dashing = false
	game.combat.equipment.guarding = false
	game.health.invulnerability = 0.0
	game.health.current = game.health.maximum

func _ranged_checks() -> void:
	_prepare()
	game.player.position = origin + Vector3.BACK * 18.0
	bee._choose_direction(0.01)
	check(bee._windup > 0, "bee can answer gunfire at eighteen units")
	_prepare()
	bee._choose_direction(1.0 / 60.0)
	check(bee._warning.visible and not bee.sting.active, "six-unit ranged attack warns before launch")
	bee._choose_direction(0.35)
	check(not bee.sting.active, "warning gives time to react")
	game.player.position.x += 2.0
	await ticks(2)
	bee._choose_direction(0.36)
	check(bee.sting.active and not bee._warning.visible, "sting launches on the committed warning aim")
	bee.sting.step(1.0, bee.protected_area, bee.get_rid())
	check(game.health.current == game.health.maximum, "sidestep dodges straight sting without homing")
	_prepare()
	await ticks(2)
	bee._choose_direction(0.01)
	bee._choose_direction(0.71)
	bee.sting.step(0.6, bee.protected_area, bee.get_rid())
	check(game.health.current == game.health.maximum - 16, "swept sting hits player once at range for 16")
	check(game.health.last_hit_kind == Damageable.HitKind.MELEE and not bee.sting.active, "sting clears on hit without a slime smear")
	_prepare()
	game.player.motor.is_dashing = true
	game.encounters._bee_stung(game.player, 16, origin, bee)
	check(game.health.current == game.health.maximum, "dash immunity blocks stings")
	game.player.motor.is_dashing = false
	game.combat.equipment.guarding = true
	game.combat.equipment.facing = Vector2.UP
	game.encounters._bee_stung(game.player, 16, origin, bee)
	check(game.health.current == game.health.maximum, "directional guard blocks incoming sting")
	game.combat.equipment.guarding = false

func _cover_checks() -> void:
	_prepare()
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4, 3, 0.02)
	shape.shape = box
	wall.add_child(shape)
	game.add_child(wall)
	wall.position = origin + Vector3(0, 0.7, 3)
	await ticks(2)
	bee._choose_direction(0.01)
	check(bee._windup == 0.0, "cover blocks initiating a ranged warning")
	bee.sting.launch(origin + Vector3.UP * 0.7, Vector3.BACK)
	bee.sting.step(1.0, bee.protected_area, bee.get_rid())
	check(not bee.sting.active and game.health.current == game.health.maximum, "thin wall absorbs a fast swept sting")
	wall.queue_free()
	await ticks(2)

func _safe_and_leash_checks() -> void:
	_prepare()
	game.player.position = game.world.ground_point(46, -13)
	bee._choose_direction(0.1)
	check(not bee.sting.active and bee._windup == 0, "protected village cancels ranged attacks")
	game.encounters._bee_stung(game.player, 16, origin, bee)
	check(game.health.current == game.health.maximum, "village remains safe from existing bolts")
	bee.sting.launch(Vector3(46, 5, 30), Vector3.FORWARD)
	bee.sting.step(1.5, bee.protected_area, bee.get_rid())
	check(not bee.sting.active, "projectile crossing village protection retires")
	_prepare()
	bee.position.x += 13.0
	var direction := bee._choose_direction(0.01)
	check(bee._returning and direction.x < 0 and bee._windup == 0, "leash returns bees toward their own southern home")

func _snapshot_checks() -> void:
	_prepare()
	bee.sting.launch(origin + Vector3.UP * 0.7, Vector3.BACK)
	var row := EncounterState.mob(bee)
	bee.sting.clear()
	EncounterState.apply_mob(bee, row, true)
	check(bee.sting.active and bee.sting.global_position.distance_to(origin + Vector3.UP * 0.7) < 0.01, "snapshot presents active sting without resolving damage")
	var hp := game.health.current
	CoopWorld.disable_simulation(game)
	for frame in 45: await physics_frame
	check(game.health.current == hp, "guest bee and sting cannot decide outcomes")
	var data := CoopWorld.capture(game)
	check(WorldProtocol.valid(data), "bounded bee roster and projectile records validate")
	var invalid := data.duplicate(true)
	invalid.mobs[39][17] = 2.0
	check(not WorldProtocol.valid(invalid), "reject oversized sting lifetime")
	invalid = data.duplicate(true)
	invalid.mobs[39][14] = "invalid"
	check(not WorldProtocol.valid(invalid), "reject nonnumeric sting state without runtime errors")
	for count in [9, 15, 27, 39]:
		var legacy := data.duplicate(true)
		legacy.mobs = legacy.mobs.slice(0, count)
		check(WorldProtocol.valid(legacy), "legacy encounter checkpoint count %d remains valid" % count)
	EncounterState.apply_mob(bee, row.slice(0, 9))
	check(not bee.sting.active, "legacy bee record defaults to no live hazard")

func _gun_and_rewards() -> void:
	_prepare()
	bee.target.invulnerability = 0.0
	var shot := SoyProjectile.new()
	shot.shooter = game.player
	shot.targets.append(bee.target)
	shot.position = origin + Vector3(0, 0.65, 6)
	shot.velocity = Vector3.FORWARD * 55.0
	game.add_child(shot)
	await ticks(10)
	check(bee.target.current == 80 and bee._provoked > 0, "soy gun body shot damages and provokes bee")
	var before := game.encounters.experience
	bee.sting.launch(origin + Vector3.UP * 0.7, Vector3.BACK)
	bee.target.damage(999)
	check(not bee.visible and not bee.sting.active, "death clears bee and live projectile")
	check(game.encounters.experience == before + 75, "level-three bee rewards 75 EXP exactly once")
	check(game.encounters.pickups.values().any(func(pickup: SoybeanPickup) -> bool: return pickup.count == 3), "bee drops three stacked Edamame")
	bee.target.damage(999)
	check(game.encounters.experience == before + 75, "dead bee cannot duplicate rewards")
	bee._physics_process(31.0)
	check(bee.visible and bee.target.current == 100 and not bee.sting.active, "bee respawns cleanly at its home")

extends SceneTree
## Confirmed ranged events, fixed origins, range, teams, expiry and replica baselines.
var failures: int = 0
var game: BattleRoyaleGame
var fixture: Node3D
var pings: BattleGunfirePings

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, label: String) -> void:
	if value: return
	failures += 1
	printerr("FAIL: ", label)

func _run() -> void:
	fixture = Node3D.new()
	root.add_child(fixture)
	game = BattleRoyaleGame.new()
	game.room = BattleRoom.new()
	root.add_child(game.room)
	game.room.options = [3, 1, 1]
	game.room.practice()
	game.playing = true
	var spawns: Array[Vector3] = [Vector3.ZERO, Vector3(10, 0, 0), Vector3(45, 0, 0), Vector3(150, 0, 0)]
	for at in spawns:
		var body := (load("res://game/player/player.tscn") as PackedScene).instantiate() as Player
		body.command_source = BattleCommandSource.new()
		body.add_child(body.command_source)
		body.position = at
		fixture.add_child(body)
		body.set_physics_process(false)
		game.bodies.append(body)
	game.match_state.initialize(spawns, 1, [3, 1, 1])
	game.match_state.time = 14
	game.combat = BattleCombat.new()
	game.combat.game = game
	fixture.add_child(game.combat)
	game.combat.build()
	game.hud = BattleHUD.new()
	fixture.add_child(game.hud)
	pings = game.presentation.gunfire
	pings.game = game
	pings.reset()
	await physics_frame
	_authority()
	_hunts()
	_weapons()
	_replica()
	TranslationServer.set_locale("pl")
	GamePreferences.install_translations(self)
	check(tr("Gunfire · 100 m · 2 s") == "Strzały · 100 m · 2 s", "expanded radar legend translates live")
	fixture.queue_free()
	game.room.queue_free()
	game.free()
	await process_frame
	await create_timer(0.25).timeout
	print("Battle gunfire radar: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _shoot(slot: int) -> void:
	var gun := game.combat.fighters[slot].combat.gun
	gun.cooldown = 0
	gun.reload_remaining = 0
	gun.selected = true
	gun.step(true, false, Vector2.DOWN, game.bodies[slot].position + Vector3(0, 1, 20), 1.0 / 60)

func _authority() -> void:
	for slot in 4: _shoot(slot)
	pings.update(0)
	check(game.hud.radar.gunfire.size() == 1, "only nearby hostile fire appears: self, duo and distant shots excluded")
	var origin := game.combat.fighters[2].combat.gun.shot_origin
	var point := Vector2(origin.x, origin.z)
	var marker: Vector3 = game.hud.radar.gunfire[0]
	check(Vector2(marker.x, marker.y).is_equal_approx(point), "marker uses the confirmed muzzle origin")
	game.bodies[2].position += Vector3(25, 0, 15)
	game.bodies[3].position = Vector3(20, 0, 0)
	pings.update(1)
	marker = game.hud.radar.gunfire[0]
	check(Vector2(marker.x, marker.y).is_equal_approx(point) and is_equal_approx(marker.z, 0.5), "moving shooters do not move dots; old distant shots stay hidden and dots fade")
	pings.update(1.01)
	check(game.hud.radar.gunfire.is_empty(), "dot expires after two seconds without passive visibility")
	var combat := game.combat.fighters[2].combat
	combat.gun.reload()
	combat.gun.selected = false
	combat.equipment.step(Vector2.DOWN, false, true, false, false, 0, 0.1)
	combat.gun.charge_elapsed = 1
	pings.update(0)
	check(combat.equipment.punch_sequence > 0 and game.hud.radar.gunfire.is_empty(), "reload, melee and charging do not reveal an enemy")
	_shoot(2)
	pings.update(0)
	check(game.hud.radar.gunfire.size() == 1, "another actual shot refreshes the shooter's single dot")
	var new_origin := combat.gun.shot_origin
	check(Vector2(game.hud.radar.gunfire[0].x, game.hud.radar.gunfire[0].y).is_equal_approx(Vector2(new_origin.x, new_origin.z)), "new shot replaces the previous location")
	game.watch_slot = 2
	pings.update(0)
	check(game.hud.radar.gunfire.is_empty(), "spectating a new team clears old enemy information")
	_shoot(0)
	pings.update(0)
	check(game.hud.radar.gunfire.size() == 1, "spectator hears enemies relative to the watched survivor's team")
	game.watch_slot = 0
	pings.reset()

func _weapons() -> void:
	var combat := game.combat.fighters[2].combat
	combat.gun._fire(true, Vector2.DOWN, game.bodies[2].position + Vector3(0, 1, 20))
	pings.update(0)
	check(game.hud.radar.gunfire.size() == 1, "charged ricochet emits a shot marker")
	pings.reset()
	combat.bow.selected = true
	combat.bow.fire(Vector2.DOWN, game.bodies[2].position + Vector3(0, 1, 20), false)
	pings.update(0)
	check(game.hud.radar.gunfire.size() == 1, "bow launch emits a shot marker")
	pings.reset()
	combat.sotjet.selected = true
	combat.sotjet.step(true, false, Vector2.DOWN, game.bodies[2].position + Vector3(0, 1, 20), 1.0 / 60)
	pings.update(0)
	check(game.hud.radar.gunfire.size() == 1, "Sotjet emission emits a shot marker")
	pings.reset()
	combat.bow.impact(game.bodies[2].position)
	pings.update(0)
	check(game.hud.radar.gunfire.is_empty(), "projectile impacts do not reveal another shooter location")
	combat.gun.celestial = true
	_shoot(2)
	pings.update(0)
	check(game.hud.radar.gunfire.size() == 1, "Celestial gun uses the same confirmed shot events")

func _replica() -> void:
	game.combat.capture()
	game.room.offline = false
	game.room.host_key = "a".repeat(64)
	game.room.local_key = "b".repeat(64)
	for fighter in game.combat.fighters: fighter.authority(false)
	pings.reset()
	var historical := BattleCombatWire.unpack(game.match_state.combat[2])
	historical.shot += 10
	game.match_state.combat[2] = BattleCombatWire.pack(historical)
	game.combat.present()
	pings.update(0)
	check(game.hud.radar.gunfire.is_empty(), "first snapshot counters are a baseline, not historical shots")
	var state := BattleCombatWire.unpack(game.match_state.combat[2])
	state.shot += 1
	state.shot_origin = [35.0, 1.0, 8.0]
	game.match_state.combat[2] = BattleCombatWire.pack(state)
	game.combat.present()
	pings.update(0)
	check(game.hud.radar.gunfire.size() == 1 and game.hud.radar.gunfire[0] == Vector3(35, 8, 1), "guest presents the authoritative shot origin without predicting fire")
	pings.update(1)
	game.combat.present()
	pings.update(0)
	check(is_equal_approx(game.hud.radar.gunfire[0].z, 0.5), "duplicate snapshot cannot refresh a marker")
	game.playing = false
	pings.reset()
	game.combat.restore(game.match_state.combat, true)
	game.room.host_key = game.room.local_key
	pings.reset()
	game.playing = true
	pings.update(0)
	check(game.hud.radar.gunfire.is_empty(), "checkpoint rollback and promotion discard stale gunfire")
	_shoot(2)
	pings.update(0)
	check(game.hud.radar.gunfire.size() == 1, "replacement authority reports the next new shot immediately")

func _hunts() -> void:
	pings.reset()
	pings.hunt(0, 1, Vector3(20, 0.7, 0))
	pings.update(0)
	check(game.hud.radar.gunfire.size() == 1, "nearby NPC shots use the same brief origin markers")
	pings.hunt(1, 1, Vector3(130, 0.7, 0))
	pings.update(0)
	check(game.hud.radar.gunfire.size() == 1, "distant hunts do not disclose their position")
	pings.update(2.01)
	pings.hunt(0, 1, Vector3(25, 0.7, 0))
	pings.update(0)
	check(game.hud.radar.gunfire.is_empty(), "an old hunt shot cannot reveal subsequent mob movement")
	pings.reset()

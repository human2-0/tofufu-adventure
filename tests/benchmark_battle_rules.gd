extends SceneTree
## Fixed rule workloads expose CPU cost without loading/rendering a world.

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var state := BattleMatch.new()
	var positions: Array[Vector3] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 27027
	for i in 51: positions.append(Vector3(rng.randf_range(-400, 800), 0, rng.randf_range(-400, 800)))
	state.initialize(positions, 1, [50, 1])
	state.circle = Vector2(650, 450)
	var mobs: Array = []
	for i in 24:
		var at := positions[i * 2] + Vector3(8, 0, 8)
		mobs.append([0, at.x, at.y, at.z, [at.x, at.y, at.z], 0, 0, 0, 0, 0])
	state.mobs = [mobs, []]
	var commands: Array = []
	var checks: Array = []
	var started := Time.get_ticks_usec()
	for frame in 100:
		state.time = 13 + frame * 6.0
		for slot in 51: commands.append(BattleBot.command(slot, state))
	var commands_ms := (Time.get_ticks_usec() - started) / 1000.0
	started = Time.get_ticks_usec()
	for frame in 1000:
		var time := frame * 0.65
		for at in positions: checks.append(BattleRing.outside(at, time, state.circle))
	var ring_ms := (Time.get_ticks_usec() - started) / 1000.0
	var report := {"scope": "Fixed headless rules only; no rendering, collisions or FPS claim.",
		"commands": commands.size(), "commands_ms": commands_ms, "command_hash": var_to_str(commands).sha256_text(),
		"storm_checks": checks.size(), "storm_ms": ring_ms, "storm_hash": var_to_str(checks).sha256_text()}
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		var file := FileAccess.open(args[0], FileAccess.WRITE)
		file.store_string(JSON.stringify(report, "\t"))
	print(JSON.stringify(report))
	quit()

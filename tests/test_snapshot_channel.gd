extends SceneTree
## JSON value patches, recipient baselines, rejection before mutation and recovery.

const HOST := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
const GUEST := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
var failures: int = 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func wire(value: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(value))

func actor() -> Dictionary:
	return {"position": [0, 0, 0], "velocity": [0, 0, 0], "aim": [0, -1],
		"grounded": true, "dashing": false, "charge": 0, "cooldown": 0,
		"invulnerability": 0, "health": 100, "input_ack": 0,
		"combat": {"owned": true, "selected": true, "guard": false, "active": false,
		"aim": [0, -1], "facing": [0, -1], "charge": 0, "strength": 0,
		"elapsed": 0, "punch": 0, "cooldown": 0, "drop": [0, 0, 0]}}

func world() -> Dictionary:
	var data := {"mobs": [], "props": [], "dummies": [], "pickups": [],
		"phase": 0.3, "beans": 0, "kills": 0, "harvests": 0, "experience": 0,
		"next_pickup": 1, "places": [], "world_items": []}
	for index in 9: data.mobs.append([index, 0, 0, 0, 0, 0, 60, 0, 0])
	for index in 24: data.props.append([1, 0])
	for index in 3: data.dummies.append([200, 0, 0, 0])
	for index in 80: data.world_items.append([index + 1, "edamame", 10, 100, index, 0, 20])
	return data

func _initialize() -> void:
	var sender := SnapshotChannel.new()
	var receiver := SnapshotChannel.new()
	var state := {"type": "snapshot", "sequence": 1, "actors": {HOST: actor(), GUEST: actor()}, "opening": {"active": false}, "world": world()}
	check(ExplorationProtocol.valid_snapshot(state, [HOST, GUEST]), "test fixture is a valid snapshot")
	check(receiver.decode(wire(sender.encode(GUEST, state)), [HOST, GUEST]) == wire(state), "first join gets complete state")
	var next := state.duplicate(true)
	next.sequence = 2
	next.actors[GUEST].position[0] = 0.2
	next.actors[GUEST].combat.elapsed = 0.1
	next.actors[GUEST].input_ack = 1
	next.world.mobs[0][0] = 0.3
	var delta := wire(sender.encode(GUEST, next))
	check(delta.type == "snapshot_delta", "subsequent state uses ordered delta")
	check(JSON.stringify(delta).length() < JSON.stringify(next).length() / 4, "unchanged clutter saves most wire bytes")
	check(receiver.decode(delta, [HOST, GUEST]) == wire(next), "nested combat, mob rows and movement survive JSON exactly")
	check(receiver.decode(delta, [HOST, GUEST]).is_empty(), "replayed delta rejected")
	var future := next.duplicate(true)
	future.sequence = 3
	future.actors[GUEST].health = 98
	var legal := wire(sender.encode(GUEST, future))
	var malformed := legal.duplicate(true)
	malformed.base = 1
	check(receiver.decode(malformed, [HOST, GUEST]).is_empty(), "wrong baseline rejected")
	malformed = legal.duplicate(true)
	malformed.patch = [1, {"actors": [1, {GUEST: [1, {"health": [0, -5]}, []]}, []]}, []]
	check(receiver.decode(malformed, [HOST, GUEST]).is_empty(), "invalid reconstructed actor rejected")
	check(receiver.decode(legal, [HOST, GUEST]) == wire(future), "rejection leaves baseline untouched")
	var no_world := future.duplicate(true)
	no_world.sequence = 4
	no_world.erase("world")
	var quiet := wire(sender.encode(GUEST, no_world))
	check(not quiet.world_tick and receiver.decode(quiet, [HOST, GUEST]) == wire(no_world), "actor-only tick does not replay world work")
	var codec := SnapshotDelta.new()
	check(codec.bounded({StringName("world"): world()}), "native dictionary property keys remain valid JSON values")
	check(codec.apply([1, 2], [2, {"2": [0, 3]}]) == null, "out-of-range index rejected")
	check(codec.apply([1, 2], [2, {"01": [0, 3]}]) == null, "index aliases rejected")
	check(codec.apply({}, [0, {"number": NAN}]) == null, "nonfinite replacement rejected")
	var deep: Array = [0, 0]
	for index in 20: deep = [0, deep]
	check(codec.apply({}, deep) == null, "replacement depth is bounded")
	check(not codec.bounded({"rows": Array(range(512)).map(func(_index: int) -> Array: return Array(range(512)))}), "retained state cannot grow beyond the total value budget")
	var observer := SnapshotChannel.new()
	check(observer.decode(quiet, [HOST, GUEST]).is_empty(), "deltas cannot initialize a new recipient")
	sender.forget(GUEST)
	future.sequence = 5
	check(observer.decode(wire(sender.encode(GUEST, future)), [HOST, GUEST]) == wire(future), "rejoin resets recipient baseline")
	future.sequence = 305
	check(sender.encode(GUEST, future).type == "snapshot", "periodic complete state permits recovery")
	var exact := state.duplicate(true)
	exact.actors[GUEST].position[0] = 0.123456
	exact.actors[GUEST].health = 98.123456
	var display := SnapshotPrecision.presentation(exact)
	check(absf(display.actors[GUEST].position[0] - exact.actors[GUEST].position[0]) <= 0.0005, "wire pose differs by at most half a millimetre per axis")
	check(display.actors[GUEST].health == exact.actors[GUEST].health and exact.actors[GUEST].position[0] == 0.123456, "precision never mutates authority or damage")
	var motion := ReplicaMotion.new()
	motion.push(Vector3.ZERO, Vector3.RIGHT, 0)
	motion.push(Vector3(0.05, 0, 0), Vector3.RIGHT, 0.05)
	check(absf(motion.sample(0.05).x - 0.025) < 0.001, "remote actor display delay is 25ms")
	check(motion.sample(1).x <= 0.15 + 0.0001, "silent remote extrapolation stays bounded")
	motion.push(Vector3(10, 0, 0), Vector3.ZERO, 1, true)
	check(motion.sample(1) == Vector3(10, 0, 0), "respawn drops stale interpolation")
	print("Snapshot channel: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

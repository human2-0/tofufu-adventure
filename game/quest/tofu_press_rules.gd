class_name TofuPressRules
extends RefCounted
## Authority-clock press trials. REJECTED is one accepted production mistake.

enum Outcome { INVALID, ACCEPTED, REJECTED, CERTIFIED }
enum Sample { SOFT, FIRM, EXTRA_FIRM }

const STONE_IDS: Array[String] = ["stone_1", "stone_2", "stone_3"]
const SOFT_SECONDS: float = 3.0
const FIRM_SECONDS: float = 5.0
const RELEASE_TOLERANCE: float = 0.75
const GAUGE_SECONDS: float = 8.0
const GAUGE_MIN: float = 82.0
const GAUGE_MAX: float = 90.0

var accessible: bool = false
var revision: int = 0
var certificates: Array[bool] = [false, false, false]
var stones: Array[String] = []
var lease_actor: int = 0
var active_sample: int = -1
var started_at: float = -1.0
var rejected: bool = false

func set_accessible(value: bool, actor: int, expected: int) -> Outcome:
	if actor < 1 or expected != revision or rejected or value == accessible: return Outcome.INVALID
	if lease_actor != 0 and lease_actor != actor: return Outcome.INVALID
	if lease_actor == actor: release_lease(actor)
	else: revision += 1
	accessible = value
	return Outcome.ACCEPTED

func release_tolerance() -> float:
	return 1.25 if accessible else RELEASE_TOLERANCE

func gauge_minimum() -> float:
	return 78.0 if accessible else GAUGE_MIN

func gauge_maximum() -> float:
	return 94.0 if accessible else GAUGE_MAX

func begin_traditional(sample: Sample, actor: int, now: float, expected: int) -> Outcome:
	if not _ready(actor, now, expected) or sample == Sample.EXTRA_FIRM: return Outcome.INVALID
	if certificates[int(sample)]: return Outcome.INVALID
	lease_actor = actor
	active_sample = int(sample)
	started_at = now if stones.size() == _required_stones() else -1.0
	revision += 1
	return Outcome.ACCEPTED

func place_stone(stone_id: String, actor: int, now: float, expected: int) -> Outcome:
	if not _valid_active(actor, now, expected) or active_sample == Sample.EXTRA_FIRM: return Outcome.INVALID
	if not STONE_IDS.has(stone_id) or stones.has(stone_id): return Outcome.INVALID
	stones.append(stone_id)
	revision += 1
	if stones.size() > _required_stones(): return _reject()
	if stones.size() == _required_stones(): started_at = now
	return Outcome.ACCEPTED

func release_traditional(actor: int, now: float, expected: int) -> Outcome:
	if not _valid_active(actor, now, expected) or active_sample == Sample.EXTRA_FIRM: return Outcome.INVALID
	if stones.size() != _required_stones() or started_at < 0.0: return _reject()
	var target: float = SOFT_SECONDS if active_sample == Sample.SOFT else FIRM_SECONDS
	if absf(now - started_at - target) > release_tolerance() + 0.000001: return _reject()
	return _certify()

func start_modern(actor: int, now: float, expected: int) -> Outcome:
	if not _ready(actor, now, expected) or certificates[Sample.EXTRA_FIRM]: return Outcome.INVALID
	if not certificates[Sample.SOFT] or not certificates[Sample.FIRM]: return Outcome.INVALID
	lease_actor = actor
	active_sample = Sample.EXTRA_FIRM
	started_at = now
	revision += 1
	return Outcome.ACCEPTED

func gauge(now: float) -> float:
	if active_sample != Sample.EXTRA_FIRM or started_at < 0.0 or not is_finite(now): return 0.0
	return clampf((now - started_at) * 100.0 / GAUGE_SECONDS, 0.0, 100.0)

func stop_modern(actor: int, now: float, expected: int) -> Outcome:
	if not _valid_active(actor, now, expected) or active_sample != Sample.EXTRA_FIRM: return Outcome.INVALID
	var value: float = gauge(now)
	if value < gauge_minimum() - 0.000001 or value > gauge_maximum() + 0.000001: return _reject()
	return _certify()

func poll_modern(now: float) -> Outcome:
	if active_sample != Sample.EXTRA_FIRM or rejected or not is_finite(now): return Outcome.INVALID
	if now < started_at or gauge(now) <= gauge_maximum() + 0.000001: return Outcome.INVALID
	return _reject()

func abandon_active(actor: int, expected: int) -> Outcome:
	if actor != lease_actor or actor < 1 or expected != revision or active_sample < 0: return Outcome.INVALID
	return _reject()

func release_lease(actor: int) -> void:
	if actor != lease_actor: return
	lease_actor = 0
	active_sample = -1
	started_at = -1.0
	stones.clear()
	revision += 1

func clear_rejection() -> bool:
	if not rejected: return false
	rejected = false
	lease_actor = 0
	active_sample = -1
	started_at = -1.0
	stones.clear()
	revision += 1
	return true

func capture(live: bool = false) -> Dictionary:
	var data: Dictionary = {"accessible": accessible, "revision": revision, "certificates": certificates.duplicate(), "stones": stones.duplicate(), "rejected": rejected}
	if live:
		data["lease_actor"] = lease_actor
		data["active_sample"] = active_sample
		data["started_at"] = started_at
	return data

func restore(data: Dictionary, live: bool = false) -> bool:
	var flags: Variant = data.get("certificates", [])
	var placed: Variant = data.get("stones", [])
	if not flags is Array or not placed is Array or flags.size() != 3 or placed.size() > 3: return false
	for flag: Variant in flags:
		if not flag is bool: return false
	if bool(flags[2]) and (not bool(flags[0]) or not bool(flags[1])): return false
	var seen: Array[String] = []
	for stone: Variant in placed:
		if not stone is String or not STONE_IDS.has(stone) or seen.has(stone): return false
		seen.append(stone)
	if not TofuPuzzleContract.bounded_integer(data.get("revision"), 0, 2147483646): return false
	if not data.get("rejected", false) is bool or not data.get("accessible", false) is bool: return false
	var owner: Variant = data.get("lease_actor", 0)
	var sample: Variant = data.get("active_sample", -1)
	var start: Variant = data.get("started_at", -1.0)
	if not TofuPuzzleContract.bounded_integer(owner, 0, 2147483647): return false
	if not TofuPuzzleContract.bounded_integer(sample, -1, Sample.EXTRA_FIRM): return false
	if not (start is int or start is float) or not is_finite(float(start)) or float(start) < -1.0: return false
	if (int(owner) == 0) != (int(sample) == -1): return false
	if int(sample) >= 0 and (bool(flags[int(sample)]) or bool(data.get("rejected", false))): return false
	if int(sample) == Sample.EXTRA_FIRM and (float(start) < 0.0 or not flags[0] or not flags[1]): return false
	if int(sample) >= 0 and int(sample) != Sample.EXTRA_FIRM:
		var required: int = 1 if int(sample) == Sample.SOFT else 2
		if seen.size() > required or (seen.size() == required) != (float(start) >= 0.0): return false
	if int(sample) < 0 and float(start) != -1.0: return false
	accessible = bool(data.get("accessible", false))
	certificates = [bool(flags[0]), bool(flags[1]), bool(flags[2])]
	stones = seen
	rejected = bool(data.get("rejected", false))
	revision = int(data.revision) + (0 if live else 1)
	lease_actor = int(owner) if live else 0
	active_sample = int(sample) if live else -1
	started_at = float(start) if live else -1.0
	return true

func _ready(actor: int, now: float, expected: int) -> bool:
	return actor > 0 and is_finite(now) and now >= 0.0 and expected == revision and lease_actor == 0 and not rejected

func _valid_active(actor: int, now: float, expected: int) -> bool:
	return actor > 0 and actor == lease_actor and is_finite(now) and now >= 0.0 and now >= started_at and expected == revision and not rejected

func _required_stones() -> int:
	return 1 if active_sample == Sample.SOFT else 2

func _reject() -> Outcome:
	rejected = true
	lease_actor = 0
	active_sample = -1
	started_at = -1.0
	revision += 1
	return Outcome.REJECTED

func _certify() -> Outcome:
	certificates[active_sample] = true
	lease_actor = 0
	active_sample = -1
	started_at = -1.0
	stones.clear()
	revision += 1
	return Outcome.CERTIFIED

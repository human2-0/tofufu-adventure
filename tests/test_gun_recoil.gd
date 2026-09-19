extends SceneTree
## Burst bloom stays bounded, resets between bursts, and remains per weapon.
var failures: int = 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	var tuning := CombatTuning.new()
	var recoil := GunRecoil.new()
	var other := GunRecoil.new()
	check(is_equal_approx(recoil.spread_degrees(true, tuning), 0.35), "first aimed shot starts accurate")
	var previous := 0.0
	for shot in 12:
		recoil.fired(tuning)
		recoil.step(true, 0.18, tuning)
		check(recoil.heat >= previous and recoil.heat <= 1.0, "spray progressively builds bounded recoil")
		previous = recoil.heat
	check(is_equal_approx(recoil.spread_degrees(true, tuning), 2.95), "long aimed bursts bloom to 2.95 degrees")
	check(recoil.spread_degrees(true, tuning) < recoil.spread_degrees(false, tuning), "aimed spray remains tighter than hip spray")
	check(other.heat == 0.0, "other actors do not share recoil")
	recoil.step(false, 0.05, tuning)
	check(recoil.heat == 1.0, "release has a short recovery delay")
	for tick in 45: recoil.step(false, 1.0 / 60.0, tuning)
	check(recoil.heat == 0.0, "released trigger recovers full accuracy")
	recoil.fired(tuning)
	recoil.reset()
	check(recoil.heat == 0 and recoil.quiet_time == 0, "respawn/reset cancels recoil")
	print("Gun recoil: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

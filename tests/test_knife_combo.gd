extends SceneTree

var failures: int = 0

func _initialize() -> void:
	var tuning := CombatTuning.new()
	var combo := KnifeCombo.new(tuning)
	check(not combo.can_stab(), "a fresh knife has no combo stab")
	combo.begin_attack()
	check(combo.confirm_hit(), "the first confirmed hit starts a combo")
	check(combo.count == 1 and combo.can_stab(), "an accurate hit opens the fast follow-up window")
	check(is_equal_approx(combo.critical_chance(), tuning.combo_critical_chance_per_hit), "the first accurate hit raises critical chance")
	combo.finish_attack()
	combo.begin_attack()
	check(combo.confirm_hit(), "a follow-up accurate hit extends the combo")
	check(combo.count == 2, "the combo counter counts accurate strikes, not button presses")
	combo.finish_attack()
	combo.step(tuning.combo_window_seconds + 0.01)
	check(combo.count == 0 and not combo.can_stab(), "an expired timing window clears the combo")
	combo.begin_attack()
	combo.confirm_hit()
	combo.finish_attack()
	combo.begin_attack()
	check(combo.finish_attack(), "a completed miss breaks the accuracy streak")
	check(combo.count == 0, "a miss cannot retain critical chance")
	for hit in tuning.combo_max_count + 2:
		combo.begin_attack()
		combo.confirm_hit()
		combo.finish_attack()
	check(combo.count == tuning.combo_max_count, "combo count is capped")
	check(is_equal_approx(combo.critical_chance(), tuning.combo_critical_chance_cap), "critical chance is capped")
	check(KnifeAttack.select(0.1, false, true, tuning) == KnifeAttack.Style.AIR_SLASH, "releasing an attack in the air selects a diving slash")
	check(KnifeAttack.select(1.0, true, false, tuning) == KnifeAttack.Style.LAUNCHER, "a charged combo release selects the launcher")
	var launch := KnifeAttack.impulse(KnifeAttack.Style.LAUNCHER, Vector2.UP, tuning)
	check(is_equal_approx(launch.y, tuning.launcher_lift), "launcher impulse carries the authored vertical lift")
	var dive := KnifeAttack.pose(KnifeAttack.Style.AIR_SLASH, Vector3.ZERO, Vector2.UP, 0.5, tuning)
	check(SwordGeometry.tip(dive, tuning).y < dive.origin.y, "aerial slash points the knife down toward grounded targets")
	print("Knife rhythm, launcher and aerial slash: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func check(condition: bool, message: String) -> void:
	if condition: return
	failures += 1
	printerr("FAIL: ", message)

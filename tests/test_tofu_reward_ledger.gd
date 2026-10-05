extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if ok: return
	failures += 1
	push_error(message)

func run() -> void:
	var ledger := TofuRewardLedger.new()
	var first: Dictionary = ledger.claim_confirmed_defeat("penalty_01", 0)
	check(first.valid and not first.practice and first.identity == "penalty_01_slot_00", "stable first penalty identity")
	check(first.item_id == "edamame" and first.count == 10 and first.experience == 65, "one shared ordinary stack and EXP")
	var repeated: Dictionary = ledger.claim_confirmed_defeat("penalty_01", 0)
	check(repeated.practice and repeated.count == 0 and repeated.experience == 0, "duplicate callback is practice")
	check(not ledger.reward_available("penalty_01", 0), "restart cannot refresh paid slot")
	check(ledger.reward_available("penalty_02", 0), "next bounded wave has independent slot")
	check(not ledger.claim_confirmed_defeat("penalty_11", 0).valid, "unbounded wave refused")
	check(not ledger.claim_confirmed_defeat("lab_curd", 8).valid, "unbounded enemy slot refused")
	check(not ledger.claim_confirmed_defeat("dofufu_boss", 0).valid, "boss must use atomic completion")
	check(not ledger.refinery_unlocked("hero"), "reward state starts locked")
	var boss: Dictionary = ledger.complete_confirmed_boss(["hero", "guest:2"])
	check(boss.item_id == "mature_bean" and boss.count == 10 and boss.experience == 250, "boss replaces ordinary payout")
	check(ledger.complete_confirmed_boss(["hero", "guest:2"]).practice, "boss callback cannot pay twice")
	check(ledger.refinery_unlocked("hero") and ledger.refinery_unlocked("guest:2"), "disconnected participant entitlement retained")
	check(not ledger.refinery_unlocked("late_join"), "uninvolved joiner remains locked")
	check(not ledger.complete_confirmed_boss(["invalid space"]).valid, "invalid participant set refused")
	var saved: Dictionary = ledger.capture()
	var restored := TofuRewardLedger.new()
	check(restored.restore(saved), "bounded ledger restores")
	check(restored.claim_confirmed_defeat("penalty_01", 0).practice, "paid slot survives restore")
	check(restored.refinery_unlocked("guest:2"), "entitlement survives restore")
	var malformed: Dictionary = saved.duplicate(true)
	malformed.paid.append("penalty_01_slot_00")
	check(not restored.restore(malformed), "duplicate reward record refused")
	check(restored.refinery_unlocked("hero"), "failed restore is atomic")
	malformed = saved.duplicate(true)
	malformed.paid = ["penalty_99_slot_00"]
	check(not restored.restore(malformed), "unknown identity refused")
	malformed = saved.duplicate(true)
	malformed.entitled = ["hero", "hero"]
	check(not restored.restore(malformed), "duplicate entitlement refused")
	print("Tofu reward ledger: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

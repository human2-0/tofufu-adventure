extends SceneTree
## Untrusted puzzle packet bounds; authority still checks run state and outcomes.

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)

func packet(action: TofuPuzzleCommand.Action, target: String, object_id: String = "") -> Dictionary:
	return {"action": int(action), "target_id": target, "object_id": object_id,
		"run_id": 7, "attempt_id": 2, "sequence": 1, "expected_revision": 0}

func run() -> void:
	var intake := packet(TofuPuzzleCommand.Action.LOAD_INTAKE, "intake_tofu", "sack_mature")
	check(TofuPuzzleProtocol.valid(intake), "known intake intent accepted")
	var decoded := TofuPuzzleProtocol.command(intake)
	check(decoded == intake, "sanitized intent retains bounded fields")
	var password := packet(TofuPuzzleCommand.Action.SUBMIT_PASSWORD, "lab_terminal")
	password.text = "  tofufu  "
	check(TofuPuzzleProtocol.valid(password), "password whitespace accepted")
	password.text = "x".repeat(33)
	check(not TofuPuzzleProtocol.valid(password), "password length capped")
	var cuts := packet(TofuPuzzleCommand.Action.COMMIT_CUTS, "cutter", "batch_7_2_block")
	cuts.cuts = [1.0, 2.0, 3.0, 4.0, 5.0]
	check(TofuPuzzleProtocol.valid(cuts), "five finite cuts accepted as intent")
	check(TofuPuzzleProtocol.command(cuts).get("cuts", []).size() == 5, "cuts copied")
	cuts.cuts = [1.0, 2.0, 3.0, 4.0]
	check(not TofuPuzzleProtocol.valid(cuts), "four cuts rejected")
	cuts.cuts = [1.0, 2.0, INF, 4.0, 5.0]
	check(not TofuPuzzleProtocol.valid(cuts), "infinite cut rejected")
	cuts.cuts = [1.0, 2.0, NAN, 4.0, 5.0]
	check(not TofuPuzzleProtocol.valid(cuts), "NaN cut rejected")
	cuts.cuts = [1.0, 2.0, 1001.0, 4.0, 5.0]
	check(not TofuPuzzleProtocol.valid(cuts), "unbounded cut rejected")
	for id: String in ["container_00", "container_19", "stone_3", "5", "batch_7_2_retry_4", "shift_note"]:
		var known := packet(TofuPuzzleCommand.Action.INSPECT, id)
		check(TofuPuzzleProtocol.valid(known), "known ID accepted: " + id)
	for id: String in ["container_20", "container_-1", "stone_4", "6", "batch_7_2_retry_-1", "../../save", "x".repeat(49)]:
		var unknown := packet(TofuPuzzleCommand.Action.INSPECT, id)
		check(not TofuPuzzleProtocol.valid(unknown), "unknown ID rejected: " + id)
	for field: String in ["run_id", "attempt_id", "sequence", "expected_revision"]:
		var bad := intake.duplicate()
		bad[field] = -1
		check(not TofuPuzzleProtocol.valid(bad), "negative counter rejected: " + field)
		bad[field] = 2147483648
		check(not TofuPuzzleProtocol.valid(bad), "large counter rejected: " + field)
		bad[field] = 1.5
		check(not TofuPuzzleProtocol.valid(bad), "fractional counter rejected: " + field)
		bad[field] = 1.0
		check(TofuPuzzleProtocol.valid(bad), "JSON integral counter accepted: " + field)
	for field: String in ["health", "success", "reward", "difficulty", "multiplier", "chemical_id"]:
		var forged := intake.duplicate()
		forged[field] = 1
		check(not TofuPuzzleProtocol.valid(forged), "authoritative field rejected: " + field)
	var wrong_action := intake.duplicate()
	wrong_action.action = -1
	check(not TofuPuzzleProtocol.valid(wrong_action), "negative action rejected")
	wrong_action.action = TofuPuzzleCommand.Action.size()
	check(not TofuPuzzleProtocol.valid(wrong_action), "unknown action rejected")
	var stray := intake.duplicate()
	stray.text = "tofu"
	check(not TofuPuzzleProtocol.valid(stray), "password outside login rejected")
	check(TofuPuzzleProtocol.command({}).is_empty(), "invalid packet does not construct intent")
	var intent := TofuPuzzleCommand.new()
	intent.action = TofuPuzzleCommand.Action.COMMIT_CUTS
	intent.target_id = "cutter"
	intent.object_id = "batch_7_2_block"
	intent.run_id = 7
	intent.attempt_id = 2
	intent.sequence = 12
	intent.cuts = [1.0, 2.0, 3.0, 4.0, 5.0]
	var wire: Dictionary = CoopPuzzleBridge.encode(intent)
	check(TofuPuzzleProtocol.valid(wire), "guest emits bounded typed intent")
	var decoded_intent: TofuPuzzleCommand = CoopPuzzleBridge.decode(wire)
	check(decoded_intent != null and decoded_intent.cuts == intent.cuts and decoded_intent.sequence == 12, "host reconstructs cut intent")
	print("Tofu puzzle protocol: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

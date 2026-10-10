extends SceneTree
## Claim schemas remain bounded, one-time and compatible with older saves.

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	if value: return
	failures += 1
	push_error(label)

func run() -> void:
	var stash := TofuStashRules.new()
	check(not stash.claim("forged", 0) and stash.opened == 0, "unknown stash cannot mint rewards")
	check(stash.claim("stash_mill", 0), "first stable identity commits")
	check(not stash.claim("stash_mill", 1), "same chest stays exhausted")
	check(not stash.claim("stash_press", 0), "stale concurrent claim refuses without mutation")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(stash.capture()))
	var restored := TofuStashRules.new()
	check(restored.restore(saved) and not restored.available("stash_mill"), "claim survives JSON and fresh attempt owner")
	check(FactoryStashProtocol.valid(saved) and FactorySaveValidation.stashes(saved), "wire and local save validate same ledger")
	for bad in [{"opened": 8, "revision": 1}, {"opened": 1.5, "revision": 1}, {"opened": 7, "revision": 1}, {"opened": 1, "revision": 1, "extra": true}]:
		check(not restored.restore(bad) and not FactoryStashProtocol.valid(bad) and not FactorySaveValidation.stashes(bad), "malformed claim snapshot rejected before replacement")
	var command := TofuPuzzleCommand.new()
	command.action = TofuPuzzleCommand.Action.OPEN_STASH
	command.target_id = "stash_mill"
	command.run_id = 1
	command.attempt_id = 1
	command.sequence = 1
	var wire: Dictionary = CoopPuzzleBridge.encode(command)
	check(TofuPuzzleProtocol.valid(JSON.parse_string(JSON.stringify(wire))), "guest chest intent survives real wire encoding")
	print("Factory stashes: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

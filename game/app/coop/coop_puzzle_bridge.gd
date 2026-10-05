class_name CoopPuzzleBridge
extends RefCounted
## Converts bounded wire intent without accepting client-computed outcomes.

static func encode(command: TofuPuzzleCommand) -> Dictionary:
	if command == null or not command.valid_shape(): return {}
	var packet: Dictionary = {"action": int(command.action), "target_id": command.target_id,
		"object_id": command.object_id, "run_id": command.run_id,
		"attempt_id": command.attempt_id, "sequence": command.sequence,
		"expected_revision": command.expected_revision}
	if command.action == TofuPuzzleCommand.Action.SUBMIT_PASSWORD: packet.text = command.text
	if command.action == TofuPuzzleCommand.Action.COMMIT_CUTS: packet.cuts = command.cuts.duplicate()
	return TofuPuzzleProtocol.command(packet)

static func decode(packet: Dictionary) -> TofuPuzzleCommand:
	if not TofuPuzzleProtocol.valid(packet): return null
	var command := TofuPuzzleCommand.new()
	command.action = int(packet.action)
	command.target_id = packet.target_id
	command.object_id = packet.object_id
	command.run_id = int(packet.run_id)
	command.attempt_id = int(packet.attempt_id)
	command.sequence = int(packet.sequence)
	command.expected_revision = int(packet.expected_revision)
	if packet.has("text"): command.text = packet.text
	if packet.has("cuts"):
		for value: Variant in packet.cuts: command.cuts.append(float(value))
	return command

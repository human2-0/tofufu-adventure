class_name BattleDeploymentWire
extends RefCounted
## Fixed sites travel on keyframes/checkpoints; live countdowns carry only choices.

static func compact(packet: Dictionary, keyframe: bool) -> void:
	if keyframe or not packet.has("deployment"): return
	var state: Dictionary = packet.deployment
	if int(state.stage) < 2:
		packet.deployment_delta = [state.choices, state.locked, state.stage, state.remaining]
	packet.erase("deployment")

static func expand(packet: Dictionary, baseline: Dictionary) -> bool:
	if packet.has("deployment"): return true
	if baseline.is_empty(): return not packet.has("deployment_delta")
	var state := baseline.duplicate(true)
	if packet.has("deployment_delta"):
		var delta: Variant = packet.deployment_delta
		if not delta is Array or delta.size() != 4: return false
		if not delta[0] is Array or not delta[1] is Array or delta[0].size() != baseline.choices.size() or delta[1].size() != baseline.locked.size(): return false
		state.choices = delta[0]
		state.locked = delta[1]
		state.stage = delta[2]
		state.remaining = delta[3]
	packet.deployment = state
	return true

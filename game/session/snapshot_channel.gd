class_name SnapshotChannel
extends RefCounted
## Per-recipient baselines. Ordered deltas are validated before baseline promotion.

var _sent: Dictionary[String, Dictionary] = {}
var _keyframes: Dictionary[String, int] = {}
var _received: Dictionary = {}
var _codec := SnapshotDelta.new()
var _encoded_sequence: int = -1
var _encoded: Dictionary[String, Dictionary] = {}

func encode(key: String, snapshot: Dictionary) -> Dictionary:
	if int(snapshot.sequence) != _encoded_sequence:
		_encoded_sequence = int(snapshot.sequence)
		_encoded.clear()
	var before: Dictionary = _sent.get(key, {})
	var next := snapshot.duplicate()
	if not next.has("world") and before.has("world"): next.world = before.world
	var keyframe: bool = before.is_empty() or int(snapshot.sequence) - _keyframes.get(key, 0) >= 300
	_sent[key] = next
	var cache_key := "%d:%s" % [int(before.get("sequence", -1)), keyframe]
	if keyframe:
		_keyframes[key] = int(snapshot.sequence)
	if not _encoded.has(cache_key):
		_encoded[cache_key] = next if keyframe else {"type": "snapshot_delta", "sequence": snapshot.sequence,
			"base": before.sequence, "world_tick": snapshot.has("world"), "patch": SnapshotDelta.difference(before, next)}
	# Room adds an epoch to the envelope; the shared patch stays immutable.
	return _encoded[cache_key].duplicate()

func decode(packet: Dictionary, members: Array) -> Dictionary:
	var next: Variant
	if packet.get("type") == "snapshot":
		next = packet.duplicate()
		next.erase("epoch")
	elif packet.get("type") == "snapshot_delta":
		if _received.is_empty() or not ExplorationProtocol.sequence(packet.get("base")): return {}
		if packet.base != _received.sequence or not packet.get("world_tick") is bool: return {}
		next = _codec.apply(_received, packet.get("patch"))
		if not next is Dictionary or next.get("type") != "snapshot" or next.get("sequence") != packet.get("sequence"): return {}
	else: return {}
	var validation: Dictionary = next.duplicate()
	if packet.get("type") == "snapshot_delta" and not packet.world_tick:
		if next.get("world") != _received.get("world"): return {}
		validation.erase("world")
	if not _codec.bounded(validation) or not ExplorationProtocol.valid_snapshot(validation, members): return {}
	if int(next.sequence) <= int(_received.get("sequence", -1)): return {}
	_received = next
	var result: Dictionary = next.duplicate()
	if packet.get("type") == "snapshot_delta" and not packet.world_tick: result.erase("world")
	return result

func forget(key: String) -> void:
	_sent.erase(key)
	_keyframes.erase(key)

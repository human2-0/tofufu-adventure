class_name InputWindow
extends RefCounted
## Monotonic, rate-limited commands referring to a recent host snapshot.

var _last: Dictionary[String, int] = {}
var _counts: Dictionary[String, int] = {}
var _window: int = 0

func accept(key: String, data: Dictionary, host_tick: int) -> bool:
	if not ExplorationProtocol.valid_input(data): return false
	if data.ack > host_tick or host_tick - int(data.ack) > 180: return false
	var sequence := int(data.sequence)
	if sequence <= _last.get(key, -1): return false
	if _last.has(key) and sequence - _last[key] > 240: return false
	var now := Time.get_ticks_msec() / 1000
	if now != _window:
		_window = now
		_counts.clear()
	if _counts.get(key, 0) >= 90: return false
	_counts[key] = _counts.get(key, 0) + 1
	_last[key] = sequence
	return true

func forget(key: String) -> void:
	_last.erase(key)
	_counts.erase(key)

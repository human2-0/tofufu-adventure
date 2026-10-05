class_name FactoryMachineAudio
extends Node3D
## Positional cosmetic machine sounds from confirmed presentation snapshots.

var room: int = 0
var _loop: AudioStreamPlayer3D
var _effect: AudioStreamPlayer3D
var _working: bool = false
var _batch_started: bool = false
var _pouring: bool = false
var _rejected: bool = false
var _cut_revision: int = -1
var _sealed: Array = []
var _mill_remaining: float = 0.0

func _ready() -> void:
	position = Vector3(0, 1.0, -5)
	_loop = _player(-16.0)
	_effect = _player(-10.0)

func present(snapshot: Dictionary, motion: Dictionary) -> void:
	match room:
		0:
			var sorting: Dictionary = snapshot.get("sorting", {})
			var started: bool = (sorting.get("assignments", {}) as Dictionary).has("sack_mature")
			if started and not _batch_started:
				_play_loop("mill")
				_mill_remaining = 3.0
			_batch_started = started
			if not started: _loop.stop()
		1: _lab(snapshot.get("lab", {}))
		2:
			var working: bool = int(motion.get("active_sample", -1)) >= 0
			if working and not _working: _play_loop("pressure")
			if not working and _working: _loop.stop()
			_working = working
		3:
			var cut: Dictionary = snapshot.get("cut", {})
			var revision: int = int(cut.get("revision", 0))
			if revision != _cut_revision and (bool(cut.get("completed", false)) or bool(cut.get("rejected", false))): _play("blade")
			_cut_revision = revision
		4:
			var seals: Array = (snapshot.get("pack", {}) as Dictionary).get("sealed", [])
			for index in seals.size():
				if bool(seals[index]) and (_sealed.size() != seals.size() or not bool(_sealed[index])): _play("seal")
			_sealed = seals.duplicate()

func _lab(data: Dictionary) -> void:
	var pouring: bool = bool(data.get("curd_encounter", false)) or bool(data.get("complete", false))
	var rejected: bool = bool(data.get("combat_locked", false)) and not pouring
	if pouring and not _pouring: _play("pour")
	if rejected and not _rejected: _play("flush")
	if not rejected and _rejected: _play("pour")
	_pouring = pouring
	_rejected = rejected

func _process(delta: float) -> void:
	if _mill_remaining <= 0.0: return
	_mill_remaining = maxf(0.0, _mill_remaining - delta)
	if _mill_remaining == 0.0:
		_loop.stop()
		_play("pour")

func _player(volume: float) -> AudioStreamPlayer3D:
	var result := AudioStreamPlayer3D.new()
	result.volume_db = volume
	result.max_distance = 22.0
	result.unit_size = 4.0
	add_child(result)
	return result

func _play_loop(id: String) -> void:
	var source: AudioStreamWAV = load("res://assets/factory/sounds/%s.wav" % id)
	var stream: AudioStreamWAV = source.duplicate()
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	_loop.stream = stream
	_loop.play()

func _play(id: String) -> void:
	_effect.stream = load("res://assets/factory/sounds/%s.wav" % id)
	_effect.play()

func _exit_tree() -> void:
	_loop.stop()
	_effect.stop()
	_loop.stream = null
	_effect.stream = null

class_name PlayerFootsteps
extends Node
## Short positional dirt steps for co-op player characters.

const STEP_INTERVAL: float = 0.52
const STEP_LENGTH: float = 0.095
signal stepped(at: Vector3, speed: float)
signal landed(at: Vector3, impact: float)
var _actor: Player
var _speaker: AudioStreamPlayer3D
var _until_step: float = 0.0
var _replica_grounded: bool = false
var _has_replica_grounded: bool = false
var _replica_dashing: bool = false
var _random := RandomNumberGenerator.new()
var _step_stream: AudioStreamWAV
var _dash_stream: AudioStreamWAV
var _was_grounded: bool = true
var _fall_speed: float = 0.0
var _last_position: Vector3
var water_muffle: float = 0.0

func _ready() -> void:
	name = "PlayerFootsteps"
	_actor = get_parent() as Player
	_random.randomize()
	_speaker = AudioStreamPlayer3D.new()
	_speaker.name = "FootstepAudio"
	_step_stream = _step_sound()
	_dash_stream = _dash_sound()
	_speaker.stream = _step_stream
	_speaker.volume_db = -8.0
	_speaker.max_distance = 28.0
	_speaker.unit_size = 5.0
	_speaker.panning_strength = 1.0
	_speaker.bus = "Master"
	add_child(_speaker)
	_last_position = _actor.global_position
	_actor.dashed.connect(_dash)

func _physics_process(delta: float) -> void:
	if _actor == null or not _actor.is_visible_in_tree():
		return
	if _actor.transport_active:
		_last_position = _actor.global_position
		_was_grounded = false
		_fall_speed = 0.0
		_until_step = 0.0
		return
	var speed := Vector2(_actor.velocity.x, _actor.velocity.z).length()
	var on_ground := grounded()
	var teleported := _last_position.distance_squared_to(_actor.global_position) > 16.0
	_last_position = _actor.global_position
	if on_ground and not _was_grounded and _fall_speed > 3.0 and not teleported:
		landed.emit(_actor.global_position, _fall_speed)
		_play_step(0.72, lerpf(-9.0, -2.0, clampf(_fall_speed / 24.0, 0.0, 1.0)))
		_until_step = 0.2
	_fall_speed = 0.0 if on_ground or teleported else maxf(_fall_speed, -_actor.velocity.y)
	_was_grounded = on_ground
	if not on_ground or speed < 0.8 or _actor.motor.is_dashing or _replica_dashing:
		_until_step = 0.0
		return
	_until_step -= delta
	if _until_step > 0.0: return
	stepped.emit(_actor.global_position, speed)
	if not _speaker.playing: _play_step(_random.randf_range(0.9, 1.1), -10.0)
	_until_step = STEP_INTERVAL / clampf(speed / 4.0, 0.7, 1.5)

func present_grounded(grounded: bool) -> void:
	_replica_grounded = grounded
	_has_replica_grounded = true

func present_dashing(dashing: bool) -> void:
	if dashing and not _replica_dashing and not _actor.command_source is LocalPlayerInput:
		_dash()
	_replica_dashing = dashing

func grounded() -> bool:
	if _actor.transport_active: return false
	return _replica_grounded if _has_replica_grounded else _actor.is_on_floor()

func _play_step(pitch: float, volume: float) -> void:
	_speaker.stream = _step_stream
	_speaker.pitch_scale = pitch * lerpf(1.0, 0.62, water_muffle)
	_speaker.volume_db = volume - water_muffle * 10.0
	_speaker.play()

func _dash() -> void:
	_speaker.stream = _dash_stream
	_speaker.pitch_scale = _random.randf_range(0.92, 1.08)
	_speaker.volume_db = -14.0 - water_muffle * 10.0
	_speaker.play()

func _dash_sound() -> AudioStreamWAV:
	var rate := 22050
	var bytes := PackedByteArray()
	bytes.resize(int(rate * 0.22) * 2)
	var low := 0.0
	for i in bytes.size() / 2:
		var progress := float(i) / (bytes.size() / 2)
		low = lerpf(low, _random.randf_range(-1, 1), 0.24)
		bytes.encode_s16(i * 2, int(low * sin(progress * PI) * (1.0 - progress) * 24000))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = bytes
	return stream

func _step_sound() -> AudioStreamWAV:
	var sample_rate := 22050
	var samples := int(sample_rate * STEP_LENGTH)
	var bytes := PackedByteArray()
	bytes.resize(samples * 2)
	var low := 0.0
	for index in samples:
		var time := float(index) / sample_rate
		low = lerpf(low, _random.randf_range(-1.0, 1.0), 0.16)
		var envelope := pow(1.0 - time / STEP_LENGTH, 2.4)
		var thud := sin(time * TAU * 92.0) * 0.42
		var grit := (low * 0.62 + _random.randf_range(-0.2, 0.2)) * (1.0 - time / STEP_LENGTH)
		bytes.encode_s16(index * 2, int(clampf((thud + grit) * envelope, -1.0, 1.0) * 15000))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = bytes
	return stream

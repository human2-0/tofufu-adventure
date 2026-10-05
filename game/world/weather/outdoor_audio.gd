class_name OutdoorAudio
extends Node3D
## Soft weather/river beds and irregular positional songbird calls.

var flock: MeadowBirds
var focus: Node3D
var enabled: bool = true
var _wind: AudioStreamPlayer
var _rain: AudioStreamPlayer
var _river: AudioStreamPlayer
var _calls: Array[AudioStreamPlayer3D] = []
var _random := RandomNumberGenerator.new()
var _next_call: float = 2.0

func _ready() -> void:
	_random.randomize()
	_wind = _bed(0)
	_rain = _bed(1)
	_river = _bed(2)
	for i in 3:
		var voice := AudioStreamPlayer3D.new()
		voice.stream = _chirp(i)
		voice.max_distance = 35.0
		voice.unit_size = 5.0
		voice.volume_db = -16.0
		add_child(voice)
		_calls.append(voice)

func present(delta: float, wind: float, rain: bool, river_distance: float) -> void:
	_wind.volume_db = move_toward(_wind.volume_db, lerpf(-39.0, -24.0, wind) if enabled else -80.0, delta * 18.0)
	_rain.volume_db = move_toward(_rain.volume_db, -25.0 if rain and enabled else -80.0, delta * 24.0)
	_river.volume_db = move_toward(_river.volume_db, lerpf(-26.0, -70.0, clampf(river_distance / 22.0, 0, 1)) if enabled else -80.0, delta * 24.0)
	_next_call -= delta
	if not enabled or rain or flock.daylight < 0.18 or _next_call > 0.0: return
	_next_call = _random.randf_range(2.0, 6.5)
	var nearby: Array[int] = []
	for i in flock.flights.size():
		if flock.flights[i].at.distance_squared_to(focus.global_position) < 900.0:
			nearby.append(i)
	if nearby.is_empty(): return
	for voice in _calls:
		if voice.playing: continue
		voice.global_position = flock.flights[nearby[_random.randi_range(0, nearby.size() - 1)]].at
		voice.pitch_scale = _random.randf_range(0.85, 1.18)
		voice.play()
		break

func _bed(kind: int) -> AudioStreamPlayer:
	var rate := 22050
	var bytes := PackedByteArray()
	bytes.resize(rate * 4 * 2)
	var low := 0.0
	for i in rate * 4:
		var t := float(i) / rate
		var noise := _random.randf_range(-1.0, 1.0)
		low = lerpf(low, noise, [0.018, 0.22, 0.055][kind])
		var sample := low * 2.0 if kind == 0 else noise * 0.26 + low * 0.74
		if kind == 2:
			sample = low * 1.5 + sin(t * 1250.0 + sin(t * 19.0) * 8.0) * 0.04
		sample *= 0.72 + sin(t * TAU / 4.0) * 0.16
		# A tiny seam fade removes looping clicks without a separate audio resource.
		sample *= minf(1.0, minf(t, 4.0 - t) * 35.0)
		bytes.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 18000))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = rate * 4
	var voice := AudioStreamPlayer.new()
	voice.stream = stream
	voice.volume_db = -80.0
	add_child(voice)
	voice.play()
	return voice

func _chirp(variant: int) -> AudioStreamWAV:
	var rate := 22050
	var bytes := PackedByteArray()
	bytes.resize(int(rate * 0.68) * 2)
	var phase := 0.0
	for i in bytes.size() / 2:
		var t := float(i) / rate
		var syllable := fposmod(t, 0.22)
		var progress := clampf(syllable / 0.14, 0.0, 1.0)
		var frequency := lerpf(2600.0 + variant * 370.0, 4300.0 - variant * 240.0, progress)
		phase += TAU * frequency / rate
		var envelope := sin(progress * PI) * sin(progress * PI) * (1.0 - t * 0.7)
		bytes.encode_s16(i * 2, int(sin(phase) * envelope * 10000))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = bytes
	return stream

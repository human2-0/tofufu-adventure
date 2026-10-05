class_name RainforestAudio
extends Node3D
## Locally attenuated broadband cascade, low water rumble and varied rainforest voices.

var roar: AudioStreamPlayer3D
var voices: Array[AudioStreamPlayer3D] = []
var _random := RandomNumberGenerator.new()
var _next_call: float = 1.2

func _ready() -> void:
	_random.seed = 90421
	roar = _voice(_water(), Vector3(0, 2.5, 6.2), 70.0, -13.0)
	roar.unit_size = 12.0
	roar.play()
	for i in 4:
		voices.append(_voice(_song(i), Vector3.ZERO, 48.0, -13.0 if i < 3 else -21.0))

func _voice(stream: AudioStreamWAV, at: Vector3, reach: float, volume: float) -> AudioStreamPlayer3D:
	var voice := AudioStreamPlayer3D.new()
	voice.stream = stream
	voice.position = at
	voice.max_distance = reach
	voice.unit_size = 7.0
	voice.volume_db = volume
	add_child(voice)
	return voice

func present(delta: float, nearby: bool, daylight: float, rain: bool, wildlife: RainforestWildlife) -> void:
	roar.volume_db = move_toward(roar.volume_db, -13.0 if nearby else -80.0, delta * 24.0)
	_next_call -= delta
	if not nearby:
		for voice in voices: voice.stop()
		return
	if _next_call > 0.0: return
	_next_call = _random.randf_range(2.3, 6.8) if not rain else _random.randf_range(5.0, 10.0)
	var variant := _random.randi_range(0, 2) if daylight > 0.2 and not rain else 3
	var voice := voices[variant]
	voice.position = wildlife.birds[_random.randi_range(0, 5)].position if variant < 3 else wildlife.frogs[_random.randi_range(0, 4)].position
	voice.pitch_scale = _random.randf_range(0.88, 1.12)
	voice.play()

func _water() -> AudioStreamWAV:
	var rate := 22050
	var count := rate * 6
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var low := 0.0
	var mid := 0.0
	for i in count:
		var t := float(i) / rate
		var noise := _random.randf_range(-1.0, 1.0)
		low = lerpf(low, noise, 0.016)
		mid = lerpf(mid, noise, 0.15)
		var sample := (noise * 0.23 + mid * 0.63 + low * 1.4) * (0.83 + sin(t * TAU / 6.0) * 0.08)
		# Match the loop seam without silencing the continuous roar.
		bytes.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 22000))
	var seam := 220
	for i in seam:
		var start := bytes.decode_s16(i * 2)
		var end := bytes.decode_s16((count - seam + i) * 2)
		bytes.encode_s16((count - seam + i) * 2, int(lerpf(end, start, float(i) / seam)))
	var stream := _stream(bytes, rate)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = seam
	stream.loop_end = count
	return stream

func _song(variant: int) -> AudioStreamWAV:
	var rate := 22050
	var duration := 1.3 if variant != 3 else 0.8
	var bytes := PackedByteArray()
	bytes.resize(int(rate * duration) * 2)
	var phase := 0.0
	for i in bytes.size() / 2:
		var t := float(i) / rate
		var syllable := fposmod(t, 0.32 if variant < 3 else 0.20)
		var progress := clampf(syllable / (0.22 if variant < 3 else 0.13), 0, 1)
		var frequency := 1600.0 + variant * 650.0 + sin(progress * PI * 1.5) * 850.0
		if variant == 2: frequency = 3100.0 + sin(t * 35) * 600.0
		if variant == 3: frequency = 620.0 + sin(t * 55.0) * 140.0
		phase += TAU * frequency / rate
		var envelope := pow(sin(progress * PI), 2.0) * minf(1.0, (duration - t) * 8.0)
		var sample := (sin(phase) + sin(phase * 2.0) * 0.15) * envelope
		bytes.encode_s16(i * 2, int(sample * 11000))
	return _stream(bytes, rate)

func _stream(bytes: PackedByteArray, rate: int) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = bytes
	return stream

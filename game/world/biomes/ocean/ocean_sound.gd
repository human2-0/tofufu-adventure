class_name OceanSound
extends AudioStreamPlayer
## Soft looping surf, with a lower pitch beneath the water.

func _ready() -> void:
	name = "OceanSurf"
	var rng := RandomNumberGenerator.new()
	rng.seed = 17183
	var rate := 22050
	var count := rate * 8
	var data := PackedByteArray()
	data.resize(count * 2)
	var low := 0.0
	var deep := 0.0
	for i in count:
		var t := float(i) / rate
		low = lerpf(low, rng.randf_range(-1.0, 1.0), 0.12)
		deep = lerpf(deep, low, 0.015)
		var swell := pow(0.5 + 0.5 * sin(t * TAU / 8.0), 2.0)
		var sample := (low * 0.65 + deep * 1.4) * (0.25 + swell * 0.75)
		data.encode_s16(i * 2, int(clampf(sample, -1, 1) * 26000))
	# Fade the loop endpoints to silence to avoid a waveform discontinuity.
	for i in 512:
		var gain := float(i) / 512.0
		data.encode_s16(i * 2, int(data.decode_s16(i * 2) * gain))
		var end := (count - 1 - i) * 2
		data.encode_s16(end, int(data.decode_s16(end) * gain))
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = rate
	wave.data = data
	wave.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wave.loop_end = count
	stream = wave
	volume_db = -60
	play()

func present(at: Vector3, depth: float, enabled: bool) -> void:
	var shore := -102.0 - sin(at.x * 0.036) * 2.8
	var strength := 1.0 - smoothstep(12.0, 40.0, absf(at.z - shore))
	strength = maxf(strength, depth * 0.5)
	if VolcanicTerrain.contains(Vector2(at.x, at.z)):
		strength = 1.0 - smoothstep(0.03, 0.3, absf(VolcanicTerrain.coast_radius(Vector2(at.x, at.z)) - 1.0))
		strength = maxf(strength, depth * 0.5)
	elif absf(at.x) > OceanTerrain.HALF_WIDTH: strength = 0.0
	if not enabled: strength = 0.0
	volume_db = lerpf(-60.0, -18.0, strength)
	pitch_scale = lerpf(1.0, 0.58, depth)

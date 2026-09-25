class_name SkyEffects
extends Node
## Cosmetic atmosphere only: the existing clocks own time and weather.

var material: ShaderMaterial
var _audio: AudioStreamPlayer
var _elapsed: float = 0.0
var _next_strike: float = 9.0
var _flash_age: float = 10.0
var _thunder_delay: float = -1.0
var _random := RandomNumberGenerator.new()

func setup(environment: Environment) -> void:
	_random.randomize()
	material = ShaderMaterial.new()
	material.shader = preload("res://game/world/storybook_sky.gdshader")
	var sky := Sky.new()
	sky.sky_material = material
	sky.process_mode = Sky.PROCESS_MODE_REALTIME
	sky.radiance_size = Sky.RADIANCE_SIZE_256
	environment.sky = sky
	environment.fog_sky_affect = 0.12
	_audio = AudioStreamPlayer.new()
	_audio.stream = _make_thunder()
	_audio.volume_db = -19.0
	add_child(_audio)

func present(delta: float, phase: float, daylight: float, clouds: float) -> float:
	_elapsed += delta
	var twilight := exp(-pow((phase - 0.25) / 0.065, 2.0)) + exp(-pow((phase - 0.75) / 0.085, 2.0))
	var dusk := phase > 0.5
	var top := Color("172940").lerp(Color("86cddd"), daylight)
	var edge := Color("485779").lerp(Color("e4f2dd"), daylight)
	top = top.lerp(Color("8572ab") if dusk else Color("b8a2ca"), twilight * 0.75)
	edge = edge.lerp(Color("ffb98f") if dusk else Color("f8ccbb"), twilight)
	var light := Color("647395").lerp(Color("fff7df"), daylight).lerp(Color("f8b9ac"), twilight * 0.7)
	var shadow := Color("303d5a").lerp(Color("abcbd0"), daylight).lerp(Color("a484aa"), twilight * 0.6)
	top = top.lerp(Color("424f68"), clouds * 0.8)
	edge = edge.lerp(Color("8b9ca6"), clouds * 0.85)
	material.set_shader_parameter("zenith", top)
	material.set_shader_parameter("horizon", edge)
	material.set_shader_parameter("cloud_light", light.lerp(Color("89939e"), clouds * 0.85))
	material.set_shader_parameter("cloud_shadow", shadow.lerp(Color("3e4a61"), clouds * 0.85))
	material.set_shader_parameter("cover", clouds)
	material.set_shader_parameter("night", (1.0 - daylight) * (1.0 - twilight) * (1.0 - clouds))
	material.set_shader_parameter("clock", _elapsed)
	material.set_shader_parameter("sun_direction", Vector3(cos(phase * TAU), sin(phase * TAU - PI * 0.5), -0.6).normalized())
	var flash := _storm(delta, clouds)
	material.set_shader_parameter("flash", flash)
	return flash

func _storm(delta: float, clouds: float) -> float:
	_flash_age += delta
	if clouds < 0.9:
		_next_strike = 9.0
	else:
		_next_strike -= delta
		if _next_strike <= 0.0:
			material.set_shader_parameter("strike_offset", _random.randf_range(-0.6, 0.6))
			_flash_age = 0.0
			_thunder_delay = 1.4
			_next_strike = _random.randf_range(12.0, 23.0)
	if _thunder_delay >= 0.0:
		_thunder_delay -= delta
		if _thunder_delay < 0.0:
			_audio.pitch_scale = _random.randf_range(0.88, 1.08)
			_audio.play()
	return maxf(0.0, 1.0 - _flash_age / 0.18) * 0.65

func _make_thunder() -> AudioStreamWAV:
	# A soft low rumble, synthesized once per world; no sharp explosion.
	var bytes := PackedByteArray()
	var rate := 22050
	bytes.resize(rate * 3 * 2)
	var low: float = 0.0
	for i in rate * 3:
		var t := float(i) / rate
		low = lerpf(low, _random.randf_range(-1.0, 1.0), 0.035)
		var envelope := minf(t * 5.0, 1.0) * exp(-t * 1.6)
		var sample := clampf((low * 2.0 + sin(t * 49.0) * 0.12) * envelope, -1.0, 1.0)
		bytes.encode_s16(i * 2, int(sample * 26000))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = bytes
	return stream

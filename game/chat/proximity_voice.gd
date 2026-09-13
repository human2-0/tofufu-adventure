class_name ProximityVoice
extends Node
## Opt-in capture and bounded PCM playback; no transport or actor dependencies.

signal captured(pcm: String)
var listening: bool = true
var _microphone: AudioStreamPlayer
var _capture: AudioEffectCapture
var _bus_name: String
var _speakers: Dictionary = {}
var _last_audio: Dictionary = {}
var _talking: bool = false

func enable_microphone(enabled: bool) -> void:
	if not enabled:
		_stop_capture()
		return
	if is_instance_valid(_microphone): return
	_bus_name = "ProximityMic_%d" % get_instance_id()
	AudioServer.add_bus()
	var bus := AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus, _bus_name)
	AudioServer.set_bus_mute(bus, true)
	_capture = AudioEffectCapture.new()
	_capture.buffer_length = 0.3
	AudioServer.add_bus_effect(bus, _capture)
	_microphone = AudioStreamPlayer.new()
	_microphone.stream = AudioStreamMicrophone.new()
	_microphone.bus = _bus_name
	add_child(_microphone)

func set_talking(active: bool) -> void:
	active = active and is_instance_valid(_microphone)
	if active == _talking: return
	_talking = active
	if not is_instance_valid(_microphone): return
	if active:
		_capture.clear_buffer()
		_microphone.play()
	else:
		_microphone.stop()
		_capture.clear_buffer()

func _process(_delta: float) -> void:
	for key: String in _speakers.keys():
		if not listening or Time.get_ticks_msec() - int(_last_audio[key]) > 400:
			forget(key)
	if not _talking or _capture == null: return
	var count := int(AudioServer.get_mix_rate() / 10.0)
	if not _capture.can_get_buffer(count): return
	# Drop a stalled capture backlog; never transmit an old conversation later.
	if _capture.get_frames_available() >= count * 2:
		_capture.clear_buffer()
		return
	var frames := _capture.get_buffer(count)
	captured.emit(encode(frames))

static func encode(frames: PackedVector2Array) -> String:
	var bytes := PackedByteArray()
	bytes.resize(ProximityRules.SAMPLES * 2)
	for index in ProximityRules.SAMPLES:
		var start := int(float(index) * frames.size() / ProximityRules.SAMPLES)
		var end := maxi(start + 1, int(float(index + 1) * frames.size() / ProximityRules.SAMPLES))
		var sample: float = 0
		for source in range(start, mini(end, frames.size())):
			sample += (frames[source].x + frames[source].y) * 0.5
		sample /= end - start
		bytes.encode_s16(index * 2, int(clampf(sample, -1, 1) * 32767))
	return Marshalls.raw_to_base64(bytes)

static func decode(pcm: String) -> PackedVector2Array:
	var bytes := Marshalls.base64_to_raw(pcm)
	var frames := PackedVector2Array()
	if bytes.size() != ProximityRules.SAMPLES * 2: return frames
	frames.resize(ProximityRules.SAMPLES)
	for index in ProximityRules.SAMPLES:
		var sample := float(bytes.decode_s16(index * 2)) / 32768.0
		frames[index] = Vector2(sample, sample)
	return frames

func receive(key: String, pcm: String, gain: float) -> void:
	if not listening or gain <= 0: return
	if not _speakers.has(key):
		if _speakers.size() >= 3: return
		var player := AudioStreamPlayer.new()
		var stream := AudioStreamGenerator.new()
		stream.mix_rate = 16000
		stream.buffer_length = 0.3
		player.stream = stream
		add_child(player)
		player.play()
		_speakers[key] = player
	var speaker: AudioStreamPlayer = _speakers[key]
	speaker.volume_db = linear_to_db(clampf(gain, 0.001, 1))
	var playback := speaker.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback.can_push_buffer(ProximityRules.SAMPLES): playback.push_buffer(decode(pcm))
	_last_audio[key] = Time.get_ticks_msec()

func set_gain(key: String, gain: float) -> void:
	if gain <= 0:
		forget(key)
	elif _speakers.has(key):
		_speakers[key].volume_db = linear_to_db(clampf(gain, 0.001, 1))

func forget(key: String) -> void:
	if _speakers.has(key): _speakers[key].queue_free()
	_speakers.erase(key)
	_last_audio.erase(key)

func _stop_capture() -> void:
	set_talking(false)
	if is_instance_valid(_microphone):
		_microphone.queue_free()
		_microphone = null
	var bus := AudioServer.get_bus_index(_bus_name)
	if bus > 0: AudioServer.remove_bus(bus)
	_capture = null

func _exit_tree() -> void:
	_stop_capture()

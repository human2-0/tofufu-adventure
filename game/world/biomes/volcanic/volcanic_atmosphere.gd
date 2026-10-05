class_name VolcanicAtmosphere
extends Node3D
## Fixed pools of ground steam, crater smoke and occasional ballistic glowing cinders.

const VENTS: Array[Vector2] = [Vector2(266, 353), Vector2(374, 262), Vector2(395, 492), Vector2(576, 312), Vector2(593, 329), Vector2(570, 337), Vector2(554, 470), Vector2(619, 400)]
const ERUPTION_PERIOD: float = 43.0
var elapsed: float = 0.0
var active: bool = false
var steam: MultiMeshInstance3D
var cinders: MultiMeshInstance3D
var rumble: AudioStreamPlayer3D

func _ready() -> void:
	name = "VolcanicAtmosphere"
	steam = _pool(112, Color(0.76, 0.72, 0.68, 0.14), false)
	cinders = _pool(32, Color("ff8c30"), true)
	rumble = AudioStreamPlayer3D.new()
	rumble.position = VolcanicTerrain.point(VolcanicTerrain.VOLCANO)
	rumble.stream = _rumble_stream()
	rumble.max_distance = 310.0
	rumble.unit_size = 30.0
	rumble.volume_db = -24
	add_child(rumble)
	if DisplayServer.get_name() != "headless": rumble.play()

func erupting() -> bool:
	return fmod(elapsed, ERUPTION_PERIOD) < 5.0

func _process(delta: float) -> void:
	if not active: return
	elapsed += delta
	var crater := VolcanicTerrain.point(VolcanicTerrain.VOLCANO, 1.0)
	for i in 112:
		var phase := fmod(elapsed * (0.13 if i < 64 else 0.07) + i * 0.173, 1.0)
		var at := crater
		var size := 3.0 + phase * 11.0
		if i < 64:
			at = VolcanicTerrain.point(VENTS[i / 8], 0.3)
			size = 0.4 + phase * 1.4
		at += Vector3(sin(i * 2.4 + phase * 3) * phase * 3, phase * (8 if i < 64 else 50), phase * 4)
		var fade := sin(phase * PI)
		steam.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * size * fade), at))
	var active := erupting()
	for i in 32:
		var age := fmod(elapsed + i * 0.157, 3.5)
		var angle := i * 2.399
		var at := crater + Vector3(cos(angle) * age * 6, age * 26 - age * age * 9.0, sin(angle) * age * 6)
		var size := 0.36 + (i % 4) * 0.08 if active and at.y > crater.y - 3 else 0.0
		cinders.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * size), at))
	rumble.volume_db = move_toward(rumble.volume_db, -11.0 if active else -27.0, delta * 12)

func _pool(count: int, color: Color, glow: bool) -> MultiMeshInstance3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if not glow else BaseMaterial3D.TRANSPARENCY_DISABLED
	material.emission_enabled = glow
	material.emission = color
	material.emission_energy_multiplier = 3.0
	var mesh := SphereMesh.new()
	mesh.radial_segments = 8
	mesh.rings = 4
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.material = material
	var pool := MultiMeshInstance3D.new()
	pool.multimesh = MultiMesh.new()
	pool.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	pool.multimesh.mesh = mesh
	pool.multimesh.instance_count = count
	pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pool.custom_aabb = AABB(Vector3(220, -10, 200), Vector3(470, 215, 385))
	add_child(pool)
	return pool

func _rumble_stream() -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(22050 * 3 * 2)
	for i in 22050 * 3:
		var time := float(i) / 22050.0
		var sample := sin(time * TAU * 37) * 0.18 + sin(time * TAU * 61) * 0.07
		data.encode_s16(i * 2, int(sample * 32767))
	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = 22050
	audio.data = data
	audio.loop_mode = AudioStreamWAV.LOOP_FORWARD
	audio.loop_end = 22050 * 3
	return audio

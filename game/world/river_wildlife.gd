class_name RiverWildlife
extends Node3D
## Cosmetic fish patrols and pooled landing ripples; never create gameplay actors.

const COUNT: int = 32
const JUMP_SECONDS: float = 0.95
var elapsed: float = 0.0
var fish: Array[MeshInstance3D] = []
var ripples: Array[MeshInstance3D] = []

func _ready() -> void:
	name = "RiverWildlife"
	var mesh := RiverFishArt.build()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.45
	ring.outer_radius = 0.49
	ring.rings = 24
	ring.ring_segments = 6
	var foam := StandardMaterial3D.new()
	foam.albedo_color = Color("d0ebd9")
	foam.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material = foam
	for i in COUNT:
		var swimmer := MeshInstance3D.new()
		swimmer.mesh = mesh
		swimmer.scale = Vector3.ONE * (0.8 + (i % 4) * 0.12)
		add_child(swimmer)
		fish.append(swimmer)
		var ripple := MeshInstance3D.new()
		ripple.mesh = ring
		ripple.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ripple)
		ripples.append(ripple)
	present(0.0)

func _process(delta: float) -> void:
	elapsed += delta
	present(elapsed)

static func jump_age(index: int, time: float) -> float:
	return fposmod(time + index * 11.7, 47.0 + index * 1.31)

static func swim_position(index: int, time: float) -> Vector3:
	var age := jump_age(index, time)
	var leap := sin(clampf(age / JUMP_SECONDS, 0.0, 1.0) * PI) * 0.95 if age < JUMP_SECONDS else 0.0
	var z := -72.0 + index * 8.1 + sin(time * 0.19 + index * 2.1) * 4.8
	var lane := sin(time * 0.27 + index * 1.7) * 0.53
	if index >= 26:
		z = 148.0 + sin(time * 0.24 + index) * 5.4
		lane = cos(time * 0.24 + index) * 0.64
	return RiverCourse.point(z, lane, -0.19 + leap)

func present(time: float) -> void:
	for i in COUNT:
		var at := swim_position(i, time)
		fish[i].position = at
		var direction := swim_position(i, time + 0.04) - at
		if direction.length_squared() > 0.000001:
			fish[i].look_at(at + direction, Vector3.UP)
		var age := jump_age(i, time)
		var splash := age - JUMP_SECONDS
		ripples[i].visible = splash >= 0.0 and splash < 1.2
		if ripples[i].visible:
			var landing := swim_position(i, time - splash)
			ripples[i].position = Vector3(landing.x, RiverCourse.level(landing.z) + 0.035, landing.z)
			var radius := 0.25 + splash * 1.4
			ripples[i].scale = Vector3(radius, maxf(0.02, 1.0 - splash / 1.2), radius)

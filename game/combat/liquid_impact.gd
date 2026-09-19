class_name LiquidImpact
extends Node3D
## Short rounded splashes at a projectile's actual collision point, on every viewer.

const DURATION: float = 0.36
var age: float = 0.0
var normal := Vector3.UP
var _drops: Array[MeshInstance3D] = []
var _velocities: Array[Vector3] = []

static func spawn(parent: Node, at: Vector3, outward: Vector3) -> LiquidImpact:
	var effect := LiquidImpact.new()
	effect.normal = outward.normalized()
	parent.add_child(effect)
	effect.global_position = at + effect.normal * 0.015
	return effect

func _ready() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 0.055
	sphere.height = 0.11
	sphere.radial_segments = 16
	sphere.rings = 8
	var milk := StandardMaterial3D.new()
	milk.albedo_color = Color("fff1bd")
	milk.roughness = 0.28
	sphere.material = milk
	var tangent := normal.cross(Vector3.UP).normalized()
	if tangent.is_zero_approx(): tangent = Vector3.RIGHT
	var bitangent := normal.cross(tangent).normalized()
	for index in 7:
		var drop := MeshInstance3D.new()
		drop.mesh = sphere
		drop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(drop)
		_drops.append(drop)
		var angle := index * TAU / 7.0
		_velocities.append(normal * 1.0 + (tangent * cos(angle) + bitangent * sin(angle)) * 1.5)

func _process(delta: float) -> void:
	age += delta
	if age >= DURATION:
		queue_free()
		return
	for index in _drops.size():
		_drops[index].position = _velocities[index] * age + Vector3.DOWN * age * age * 3.0
		_drops[index].scale = Vector3.ONE * (1.0 - age / DURATION)

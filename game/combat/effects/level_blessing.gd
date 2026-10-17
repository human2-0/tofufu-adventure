class_name LevelBlessing
extends Node3D
## Three-second cosmetic blessing follows its actor; no recovery or gameplay rules.

const ART: Texture2D = preload("res://assets/effects/level_blessing/halo.png")
const LIFETIME: float = 3.2
var age: float = 0.0
var rings: Array[Sprite3D] = []
var motes: Array[Sprite3D] = []

func _ready() -> void:
	for index in 3:
		var ring := _sprite(2.3 - index * 0.25)
		ring.rotation.x = -PI * 0.5
		rings.append(ring)
	for index in 12:
		var mote := _sprite(0.11)
		mote.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		motes.append(mote)

func _sprite(span: float) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.texture = ART
	sprite.pixel_size = span / ART.get_width()
	sprite.shaded = false
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sprite)
	return sprite

func restart() -> void:
	age = 0.0

func _process(delta: float) -> void:
	age += delta
	if age >= LIFETIME:
		queue_free()
		return
	var alpha := smoothstep(0.0, 0.15, age) * (1.0 - smoothstep(2.3, LIFETIME, age))
	for index in rings.size():
		var ring := rings[index]
		ring.position.y = 0.07 if index == 0 else fmod(age * 0.65 + index * 0.55, 1.8)
		ring.rotation.z = age * (0.3 if index % 2 == 0 else -0.3)
		ring.scale = Vector3.ONE * (1.0 + sin(age * 3.0 + index) * 0.07)
		ring.modulate = Color(1.0, 0.94, 0.70, alpha * (0.9 if index == 0 else 0.55))
	for index in motes.size():
		var phase := age * 1.2 + index * TAU / motes.size()
		motes[index].position = Vector3(cos(phase) * 0.75, fmod(age * 0.9 + index * 0.17, 2.2), sin(phase) * 0.75)
		motes[index].modulate = Color(1.0, 0.96, 0.75, alpha)

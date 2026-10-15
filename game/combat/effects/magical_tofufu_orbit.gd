class_name MagicalTofufuOrbit
extends Node3D
## Three bounded cosmetic tofu spirits. No lights, gameplay or resource changes.

const TEXTURE: Texture2D = preload("res://assets/items/magical_tofufu/chunk.png")
var center: Callable
var enabled: Callable
var plane := Basis.IDENTITY
var lazy: bool = false
var radius: float = 0.20
var span: float = 0.14
var spirits: Array[Sprite3D] = []
var _time: float = 0.0

func _ready() -> void:
	process_priority = 100
	if not lazy: _build()

func _build() -> void:
	for index in 3:
		var spirit := Sprite3D.new()
		spirit.texture = TEXTURE
		spirit.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		spirit.pixel_size = span / TEXTURE.get_width()
		spirit.shaded = false
		spirit.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		spirit.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		add_child(spirit)
		spirits.append(spirit)

func _process(delta: float) -> void:
	visible = enabled.is_valid() and bool(enabled.call())
	if not visible: return
	if spirits.is_empty(): _build()
	_time = fmod(_time + delta, TAU * 100)
	if center.is_valid(): global_position = center.call()
	for index in spirits.size():
		var phase := _time * 2.2 + index * TAU / 3.0
		spirits[index].position = plane * Vector3(cos(phase) * radius, sin(phase * 2.0) * radius * 0.45, sin(phase) * radius)

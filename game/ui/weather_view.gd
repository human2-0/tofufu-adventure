class_name WeatherView
extends CanvasLayer
## Screen rain and a persistent forecast; receives presentation values only.

var _rain: ColorRect
var _wind: ColorRect
var _label: Label
var _material: ShaderMaterial
var _wind_material: ShaderMaterial
var _strength: float = 0.0
var _target: float = 0.0
var _wind_strength: float = 0.0
var _age: float = 0.0

func _ready() -> void:
	layer = 0
	_rain = ColorRect.new()
	_rain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_material = ShaderMaterial.new()
	_material.shader = preload("res://game/ui/rain.gdshader")
	_rain.material = _material
	add_child(_rain)
	_wind = ColorRect.new()
	_wind.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_wind.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wind_material = ShaderMaterial.new()
	_wind_material.shader = preload("res://game/ui/wind.gdshader")
	_wind.material = _wind_material
	add_child(_wind)
	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_label.position = Vector2(-245, 28)
	_label.size = Vector2(490, 45)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", Color("e2f0ec"))
	_label.add_theme_color_override("font_shadow_color", Color("233a49"))
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)

func present(title: String, raining: bool, windy: bool = false) -> void:
	_target = 1.0 if raining else 0.0
	_label.text = title + (" · Snails thriving!\n5 per camp · stronger · faster respawns" if raining else " · Gusts slow you when walking into them" if windy else " · Cloud cover" if title == "OVERCAST" else " · Calm fields")

func present_wind(direction: Vector2, strength: float) -> void:
	_wind_strength = strength
	_wind_material.set_shader_parameter("direction", direction.normalized())
	_wind_material.set_shader_parameter("strength", strength)

func _process(delta: float) -> void:
	_strength = move_toward(_strength, _target, delta * 0.5)
	_age += delta
	_rain.visible = _strength > 0.0
	_wind.visible = _wind_strength > 0.02
	_material.set_shader_parameter("strength", _strength)
	_material.set_shader_parameter("age", _age)

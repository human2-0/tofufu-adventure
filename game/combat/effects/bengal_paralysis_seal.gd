class_name BengalParalysisSeal
extends Node3D
## Three small fractured bonds orbit a frozen enemy for its remaining status time.

var target: Damageable
var age: float = 0
var cracks: Array[Sprite3D] = []

func _ready() -> void:
	for index in 3:
		var crack := Sprite3D.new()
		crack.texture = BengalRiftEffect.OPEN
		crack.pixel_size = 0.55 / BengalRiftEffect.OPEN.get_height()
		crack.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		crack.shaded = false
		crack.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(crack)
		cracks.append(crack)
	_process(0)

func _process(delta: float) -> void:
	if not is_instance_valid(target) or target.current <= 0 or target.paralysis <= 0:
		queue_free()
		return
	age += delta
	for index in 3:
		var angle := age * 1.8 + index * TAU / 3
		cracks[index].position = Vector3(cos(angle) * 0.5, 0.3 + sin(angle * 2) * 0.1, sin(angle) * 0.5)
		cracks[index].rotation.z = sin(age * 3 + index) * 0.16
		cracks[index].modulate = Color(0.8, 1.2, 1.5, minf(1, target.paralysis * 3) * (0.7 + sin(age * 7 + index) * 0.15))

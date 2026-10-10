class_name CloudResident
extends Node3D
## Friendly tofu court resident; sentries are solid, idle motion stays cosmetic.

var title: String = "Cloud Guardian"
var role: String = "guardian"
var greeting_text: String = "The cloud paths are safe.\nThe king welcomes peaceful travellers."
var art_key: String = ""
var art_height: float = 2.4
var greeting: Label3D
var sprite := CloudResidentArt.new()
var visual := Node3D.new()
var elapsed: float = 0.0
var phase: float = 0.0

func _ready() -> void:
	add_child(visual)
	sprite.asset = art_key if not art_key.is_empty() else role
	sprite.height = art_height
	visual.add_child(sprite)
	if role != "angel":
		var body := StaticBody3D.new()
		body.name = "ResidentBody"
		body.collision_layer = 1
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.9, 1.65, 0.7)
		shape.shape = box
		shape.position.y = 0.9
		body.add_child(shape)
		add_child(body)
		_label(title, Vector3(0, art_height + 0.6, 0), 23)
		greeting = _label(greeting_text, Vector3(0, art_height + 1.8, 0), 21)
		greeting.visible = false

func _label(text: String, at: Vector3, size: int) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = size
	label.pixel_size = 0.012
	label.modulate = Color("fff0c5")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = at
	label.visibility_range_end = 42
	add_child(label)
	return label

func _process(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera != null and camera.global_position.distance_squared_to(global_position) > 16000: return
	elapsed += delta
	visual.position.y = sin(elapsed * 1.8 + phase) * 0.045
	if role == "angel":
		visual.position.y = sin(elapsed * 2.2 + phase) * 0.3
		sprite.elapsed = elapsed + phase

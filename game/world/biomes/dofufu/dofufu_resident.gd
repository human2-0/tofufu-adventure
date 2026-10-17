class_name DofufuResident
extends Node3D
## Solid named city resident; nearby dialogue and idle rivalry are cosmetic.

var title: String
var role: int = 0
var words: String
var facing := Vector2.RIGHT
var art := DofufuCityArt.new()
var greeting: Label3D
var elapsed: float = 0
var sparring: bool = false
var view_focus: Node3D

func _ready() -> void:
	art.role = role
	art.facing = facing
	add_child(art)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.9, 1.5, 0.7)
	shape.shape = box
	shape.position.y = 0.8
	body.add_child(shape)
	add_child(body)
	_label(title, 2.3)
	greeting = _label(words, 3.0)
	greeting.visible = false

func _label(text: String, y: float) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position.y = y
	label.font_size = 25
	label.pixel_size = 0.008
	label.modulate = Color("ffe2aa")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.visibility_range_end = 22
	add_child(label)
	return label

func _process(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null: return
	var distance := camera.global_position.distance_squared_to(global_position)
	if distance > 6400: return
	elapsed += delta
	art.position.y = absf(sin(elapsed * (4.0 if sparring else 1.5))) * (0.16 if sparring else 0.025)
	art.rotation.z = sin(elapsed * 4) * 0.12 if sparring else 0.0
	if sparring: art.position.z = maxf(0, sin(elapsed * 4)) * facing.y * 0.45
	greeting.visible = is_instance_valid(view_focus) and view_focus.global_position.distance_squared_to(global_position) < 25
	if greeting.visible and not sparring:
		var toward := view_focus.global_position - global_position
		if Vector2(toward.x, toward.z).length_squared() > 0.1:
			art.facing = Vector2(toward.x, toward.z).normalized()

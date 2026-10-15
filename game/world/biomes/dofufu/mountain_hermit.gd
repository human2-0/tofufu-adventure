class_name MountainHermit
extends Node3D
## Future quest character: solid local resident with proximity dialogue, no rewards yet.

var art := MountainHybridArt.new()
var view_focus: Node3D
var greeting: Label3D
var title: Label3D

func _ready() -> void:
	name = "MofufuMountainHermit"
	add_child(art)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.height = 1.9
	capsule.radius = 0.65
	shape.shape = capsule
	shape.position.y = 0.95
	body.add_child(shape)
	add_child(body)
	title = _label("Mofufu · Mountain Hermit", 2.6, 32)
	title.visible = false
	greeting = _label("Tofufu and Dofufu... both are part of me.\nRest here, traveller. We will talk again soon.", 3.3, 32)
	greeting.visible = false

func _label(words: String, height: float, distance: float) -> Label3D:
	var label := Label3D.new()
	label.text = words
	label.position.y = height
	label.font_size = 24
	label.pixel_size = 0.008
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.visibility_range_end = distance
	label.visibility_range_end_margin = 2
	label.modulate = Color("ffedc2")
	add_child(label)
	return label

func _process(_delta: float) -> void:
	var distance := view_focus.global_position.distance_squared_to(global_position) if is_instance_valid(view_focus) else INF
	title.visible = distance < 100
	greeting.visible = distance < 20
	if greeting.visible:
		var toward := view_focus.global_position - global_position
		if Vector2(toward.x, toward.z).length_squared() > 0.2:
			art.facing = Vector2(toward.x, toward.z).normalized()

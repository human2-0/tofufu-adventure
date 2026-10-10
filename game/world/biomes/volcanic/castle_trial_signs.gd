class_name CastleTrialSigns
extends Node3D
## A nearby contextual placard turns as a whole; pedestal cards stay object-attached.

var pivot: Node3D
var status: Label3D

func build(at: Vector3, clue: String) -> void:
	position = at + Vector3(0, 2.8, -2.3)
	pivot = Node3D.new()
	add_child(pivot)
	var board := CastleMaterials.box(pivot, Vector3.ZERO, Vector3(3.8, 1.45, 0.12), Color("383140"))
	board.material_override = CastleMaterials.metal(Color("322a32"), 0.1)
	board.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var frame := CastleDecorationBatch.new()
	for side in [-1.0, 1.0]:
		frame.box("bronze", Vector3(side * 1.89, 0, 0.07), Vector3(0.06, 1.5, 0.04))
		frame.box("bronze", Vector3(0, side * 0.715, 0.07), Vector3(3.82, 0.06, 0.04))
	frame.build(pivot, "InscriptionFrame")
	var text := CastleGeometry.title(pivot, Vector3(0, 0.16, 0.08), clue, 20)
	text.pixel_size = 0.006
	text.outline_size = 5
	status = CastleGeometry.title(pivot, Vector3(0, -0.48, 0.08), "", 16)
	status.pixel_size = 0.006
	status.modulate = Color("90e8de")

func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null: return
	pivot.visible = global_position.distance_to(camera.global_position) < 25
	var direction := camera.global_position - pivot.global_position
	if pivot.visible and direction.length_squared() > 0.01:
		var up := Vector3.FORWARD if absf(direction.normalized().dot(Vector3.UP)) > 0.98 else Vector3.UP
		pivot.look_at(camera.global_position, up, true)

static func station(parent: Node3D, title: String, glyph: String) -> Array[Label3D]:
	var glyphs: Array[Label3D] = []
	for i in 4:
		var yaw := i * PI * 0.5
		var at := Vector3(0, 1.48, 0.5).rotated(Vector3.UP, yaw)
		var card := CastleMaterials.box(parent, at, Vector3(1.1, 0.3, 0.06), Color("3c303c"))
		card.material_override = CastleMaterials.metal(Color("3c303c"), 0.1)
		card.rotation.y = yaw
		var label := CastleGeometry.title(parent, at + Vector3(0, 0, 0.04).rotated(Vector3.UP, yaw), title, 19)
		label.pixel_size = 0.005
		label.rotation.y = yaw
		var mark := CastleGeometry.title(parent, Vector3(0, 1.06, 0.38).rotated(Vector3.UP, yaw), glyph, 42)
		mark.pixel_size = 0.006
		mark.rotation.y = yaw
		glyphs.append(mark)
	return glyphs

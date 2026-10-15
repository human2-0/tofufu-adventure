class_name DofufuWarning
extends Node3D
## Depth-tested ground footprints display committed attacks; never resolve hits.

var footprint: MeshInstance3D
var label: Label3D

func _ready() -> void:
	top_level = true
	footprint = MeshInstance3D.new()
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.4, 0.12, 0.45)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	footprint.material_override = material
	add_child(footprint)
	label = Label3D.new()
	label.visibility_range_end = 32.0
	label.visibility_range_end_margin = 2.0
	label.font_size = 30
	label.pixel_size = 0.012
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = false
	label.position.y = 3.0
	add_child(label)
	hide()

func show_skill(skill: int, at: Vector3, aim: Vector3) -> void:
	global_position = at + Vector3.UP * 0.06
	label.text = DofufuRules.NAMES[skill].get_slice(" · ", 0)
	var radius: float = 5.5 if skill == DofufuRules.Skill.SLAM else 3.4
	if skill == DofufuRules.Skill.DRAGON_STEP:
		var box := BoxMesh.new()
		box.size = Vector3(1.5, 0.06, 13.0)
		footprint.mesh = box
		footprint.position = aim * 6.5
		footprint.rotation.y = atan2(aim.x, aim.z)
	else:
		var disc := CylinderMesh.new()
		disc.top_radius = radius
		disc.bottom_radius = radius
		disc.height = 0.035
		disc.radial_segments = 48
		footprint.mesh = disc
		footprint.position = Vector3.ZERO
		footprint.rotation = Vector3.ZERO
	show()

func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	# Close views already show the full attack cue in the HUD.
	label.visible = camera == null or camera.global_position.distance_to(global_position) > 6.0

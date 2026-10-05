class_name FirstPersonArms
extends Node3D
## Fixed left/right camera-space sleeves connect palms through swing/ADS/reload.

var material := ShaderMaterial.new()
var _arms: Array[MeshInstance3D] = []

func _ready() -> void:
	material.shader = WeaponGripVisual.SHADER
	for index in 2:
		var arm := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.045
		mesh.bottom_radius = 0.065
		mesh.height = 1.0
		arm.mesh = mesh
		arm.material_override = material
		arm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(arm)
		_arms.append(arm)

func present(hands: Array[MeshInstance3D], tint: Color) -> void:
	material.set_shader_parameter("tint", tint)
	for index in 2:
		var arm := _arms[index]
		arm.visible = hands[index].visible
		if not arm.visible: continue
		var wrist := hands[index].global_position
		var start := Vector3(0.55 if index == 0 else -0.55, -0.70, -0.7)
		var reach := wrist - start
		var along := reach.normalized()
		var across := along.cross(Vector3.BACK).normalized()
		if across.is_zero_approx(): across = Vector3.RIGHT
		arm.global_transform = Transform3D(Basis(across, along * reach.length(), across.cross(along)), (start + wrist) * 0.5)

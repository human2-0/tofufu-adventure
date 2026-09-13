class_name GroundShadow
extends Node3D
## A ground-projected landing cue; visual scale never affects the actor collider.

var _disc: MeshInstance3D

func _ready() -> void:
	_disc = MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.4
	mesh.bottom_radius = 0.4
	mesh.height = 0.012
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.08, 0.15, 0.17, 0.24)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = material
	_disc.mesh = mesh
	_disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_disc)
	_disc.top_level = true

func _physics_process(_delta: float) -> void:
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.15, global_position + Vector3.DOWN * 30, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	_disc.visible = not hit.is_empty()
	if not hit.is_empty():
		_disc.global_position = hit.position + Vector3.UP * 0.02
		var altitude: float = global_position.y - hit.position.y
		_disc.scale = Vector3.ONE * clampf(1.0 + altitude * 0.035, 1.0, 1.35)

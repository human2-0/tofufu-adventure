class_name CloudMist
extends Node3D
## Forty-two depth-tested drifting cloud wisps, kept beneath the walkable floor.

const COUNT: int = 42
var view := MultiMeshInstance3D.new()
var poses: Array[Transform3D] = []

func _ready() -> void:
	name = "CloudMist"
	position = CloudTerrain.point(CloudTerrain.CENTER.x, CloudTerrain.CENTER.y)
	var mesh := QuadMesh.new()
	mesh.size = Vector2.ONE
	var material := ShaderMaterial.new()
	material.shader = preload("res://game/world/biomes/clouds/cloud_mist.gdshader")
	material.set_shader_parameter("cloud_texture", CloudMaterials.CLOUD)
	mesh.material = material
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	multi.instance_count = COUNT
	for i in COUNT:
		var island := CloudTerrain.ISLANDS[i % CloudTerrain.ISLANDS.size()]
		var center := CloudTerrain.CENTER + Vector2(island.x, island.y)
		var angle: float = i * 2.4
		var at := center + Vector2(cos(angle), sin(angle)) * (island.z + 0.3)
		var base := CloudTerrain.point(at.x, at.y, -2.3 - i % 3 * 1.1)
		var pose := Transform3D(Basis.IDENTITY.scaled(Vector3(7 + i % 3, 1.2, 1)), base - position)
		poses.append(pose)
		multi.set_instance_transform(i, pose)
	view.multimesh = multi
	view.visibility_range_end = 160
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(view)

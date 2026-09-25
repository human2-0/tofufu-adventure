class_name RiverSurface
extends Node3D
## A continuous subdivided ribbon includes the pond, avoiding overlapping water planes.

func _ready() -> void:
	name = "LivingRiver"
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var distance: float = 0.0
	var previous := RiverCourse.point(RiverCourse.START)
	for row in int((RiverCourse.END - RiverCourse.START) * 2.0):
		var z := RiverCourse.START + row * 0.5
		var current := RiverCourse.point(z + 0.5)
		var next_distance := distance + previous.distance_to(current)
		for column in 12:
			for corner in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]:
				var depth: float = z + corner.y * 0.5
				var across: float = (column + corner.x) / 12.0
				surface.set_uv(Vector2(across, lerpf(distance, next_distance, corner.y)))
				surface.add_vertex(RiverCourse.point(depth, across * 2.0 - 1.0))
		distance = next_distance
		previous = current
	surface.generate_normals()
	surface.generate_tangents()
	var water := MeshInstance3D.new()
	water.name = "IrrigationStream"
	water.mesh = surface.commit()
	var material := ShaderMaterial.new()
	material.shader = preload("res://game/world/river.gdshader")
	water.material_override = material
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(water)

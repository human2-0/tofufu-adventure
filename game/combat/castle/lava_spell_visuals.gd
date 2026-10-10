class_name LavaSpellVisuals
extends Node3D
## Reused world-space cores and warning rings; no damage or scene-wide lights.

var cores: Array[MeshInstance3D] = []
var rings: Array[MeshInstance3D] = []
var plumes: Array[MeshInstance3D] = []
var fire_material: StandardMaterial3D
var plume_material := ShaderMaterial.new()
var embers: Array[MeshInstance3D] = []
var warning_material: StandardMaterial3D
var chunks: Array[MeshInstance3D] = []
var trails: MultiMeshInstance3D
var bolt_capacity: int = 24
var field_capacity: int = 12

func _ready() -> void:
	plume_material.shader = preload("res://game/combat/castle/lava_spell.gdshader")
	fire_material = _material(Color("ff9d28"), 2.3)
	warning_material = _material(Color("ffd369"), 1.3)
	var chunk_material := ShaderMaterial.new()
	chunk_material.shader = preload("res://game/combat/castle/tofu_fire_chunk.gdshader")
	for i in bolt_capacity:
		var cube := BoxMesh.new()
		cube.size = Vector3.ONE * 0.68
		chunks.append(_mesh(cube, chunk_material))
		var sphere := SphereMesh.new()
		sphere.radius = 0.28
		sphere.height = 0.56
		sphere.radial_segments = 8
		sphere.rings = 4
		cores.append(_mesh(sphere, fire_material))
	_build_trails()
	for i in field_capacity:
		var torus := TorusMesh.new()
		torus.inner_radius = 0.94
		torus.outer_radius = 1.0
		torus.rings = 32
		torus.ring_segments = 6
		rings.append(_mesh(torus, warning_material))
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.15
		cylinder.bottom_radius = 1.0
		cylinder.height = 1.0
		cylinder.radial_segments = 8
		plumes.append(_mesh(cylinder, plume_material))
		for spark in 6:
			var speck := SphereMesh.new()
			speck.radius = 0.075
			speck.height = 0.16
			speck.radial_segments = 6
			speck.rings = 3
			embers.append(_mesh(speck, fire_material))

func _material(color: Color, energy: float) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.emission_enabled = true
	result.emission = color
	result.emission_energy_multiplier = energy
	result.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return result

func _mesh(shape: Mesh, material: Material) -> MeshInstance3D:
	var result := MeshInstance3D.new()
	result.mesh = shape
	result.material_override = material
	result.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	result.visible = false
	add_child(result)
	return result

func present(bolts: Array[Array], fields: Array[Array]) -> void:
	var time := Time.get_ticks_msec() * 0.001
	var trail_count := 0
	for i in cores.size():
		var chunk := i < bolts.size() and int(bolts[i][7]) == 1
		cores[i].visible = i < bolts.size() and not chunk
		chunks[i].visible = chunk
		if i >= bolts.size(): continue
		var at := Vector3(bolts[i][0], bolts[i][1], bolts[i][2])
		cores[i].global_position = at
		chunks[i].global_position = at
		chunks[i].rotation = Vector3(time * 9, time * 5 + i, time * 7)
		if chunk:
			var velocity := Vector3(bolts[i][3], bolts[i][4], bolts[i][5]).normalized()
			for tail in 3:
				var point := to_local(at - velocity * (tail + 1) * 0.38)
				trails.multimesh.set_instance_transform(trail_count, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * (1.0 - tail * 0.22)), point))
				trail_count += 1
	trails.multimesh.visible_instance_count = trail_count
	for i in rings.size():
		rings[i].visible = i < fields.size()
		plumes[i].visible = i < fields.size() and int(fields[i][0]) == 0 and fields[i][4] >= 0
		for spark in 6: embers[i * 6 + spark].visible = plumes[i].visible
		if i >= fields.size(): continue
		var data := fields[i]
		var radius: float = 2.0 if int(data[0]) == 1 and data[4] < 0 else maxf(0.1, data[7])
		rings[i].global_position = Vector3(data[1], data[2] + 0.08, data[3])
		rings[i].scale = Vector3(radius, 0.65, radius)
		var pulse := 0.75 + sin(Time.get_ticks_msec() * 0.018) * 0.25
		rings[i].material_override = warning_material if data[4] < 0 else fire_material
		plumes[i].global_position = Vector3(data[1], data[2] + 0.6, data[3])
		plumes[i].scale = Vector3(radius * 0.65, 1.0 + pulse, radius * 0.65)

		for spark in 6:
			var spark_time := time + spark * 0.43
			var angle := spark * TAU / 6 + spark_time * 0.8
			embers[i * 6 + spark].global_position = Vector3(data[1] + cos(angle) * radius * 0.45, data[2] + fmod(spark_time, 1.6) * 1.7, data[3] + sin(angle) * radius * 0.45)

func _build_trails() -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE * 0.18
	mesh.material = fire_material
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	multi.instance_count = bolt_capacity * 3
	multi.visible_instance_count = 0
	trails = MultiMeshInstance3D.new()
	trails.multimesh = multi
	trails.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(trails)

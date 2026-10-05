class_name VolcanicLandmarks
extends RefCounted
## Authored districts leave open centers for later encounters, quests and gathering.

const SITES: Array[Vector2] = [Vector2(448, 234), Vector2(585, 324), Vector2(573, 456), Vector2(635, 395), Vector2(435, 515)]
const TITLES: Array[String] = ["Cinder Harbor", "Sulfur Gardens", "Obsidian Sanctuary", "Tideglass Cove", "Ashwalker Camp"]

static func build(parent: Node3D) -> void:
	for i in SITES.size():
		var site := Node3D.new()
		site.name = TITLES[i].replace(" ", "")
		site.position = VolcanicTerrain.point(SITES[i])
		site.set_meta("map_title", TITLES[i])
		parent.add_child(site)
		match i:
			0: _harbor(site)
			1: _gardens(site)
			2: _sanctuary(site)
			3: _cove(site)
			4: _camp(site)
	_coastal_stacks(parent)

static func _harbor(site: Node3D) -> void:
	MeadowGeometry.box(site, Vector3(0, -0.15, -10), Vector3(7, 0.3, 24), Color("766354"), true)
	for z in range(-20, 3, 3):
		MeadowGeometry.box(site, Vector3(0, 0.035, z), Vector3(7.2, 0.06, 0.15), Color("4f423b"))
		for side in [-1.0, 1.0]:
			MeadowGeometry.box(site, Vector3(side * 3.4, -1.5, z), Vector3(0.5, 4, 0.5), Color("4b4144"), true)
	for side in [-1.0, 1.0]:
		_arch(site, Vector3(side * 11, 0, 7), 4.0)
		for i in 4:
			MeadowGeometry.box(site, Vector3(side * 12, 0.6, i * 2 - 4), Vector3(1.2, 1.2, 1.2), Color("ad906e"), true)
	# Broken crane and ropes make the abandoned landing recognizable at ground level.
	MeadowGeometry.box(site, Vector3(-5, 3, -12), Vector3(0.6, 6, 0.6), Color("524446"), true)
	MeadowGeometry.box(site, Vector3(-2, 5.6, -12), Vector3(6, 0.4, 0.4), Color("524446"))
	MeadowGeometry.box(site, Vector3(1, 4.2, -12), Vector3(0.08, 2.6, 0.08), Color("c4ae81"))
	MeadowGeometry.box(site, Vector3(1, 2.8, -12), Vector3(1.8, 0.2, 1.8), Color("736253"))

static func _gardens(site: Node3D) -> void:
	for i in 4:
		var center := Vector3((i % 2) * 11 - 5.5, 0.06, (i / 2) * 10 - 5)
		var pool := _disc(site, center, 4.1, 0.12, Color("5e9182"))
		var water := ShaderMaterial.new()
		water.shader = preload("res://game/world/biomes/volcanic/thermal_water.gdshader")
		pool.material_override = water
		for j in 18:
			var angle := j * TAU / 18
			MeadowGeometry.rock(site, center + Vector3(cos(angle) * 4.3, 0.1, sin(angle) * 4.3), Vector3(0.75, 0.35, 0.6), Color("c3b08a"))
	for side in [-1.0, 1.0]:
		MeadowGeometry.box(site, Vector3(side * 14, 0.4, 0), Vector3(1.1, 0.8, 20), Color("8c806b"), true)
		for i in 6:
			MeadowGeometry.box(site, Vector3(side * 14, 0.9, -9 + i * 3), Vector3(1.3, 0.2, 1.3), Color("d6bc6c"))
	_disc(site, Vector3(0, 0.08, 16), 5, 0.16, Color("bba582"))

static func _sanctuary(site: Node3D) -> void:
	_disc(site, Vector3(0, 0.1, 0), 14, 0.2, Color("8a7975"), true)
	for i in 8:
		var angle := i * TAU / 8
		var at := Vector3(cos(angle) * 12, 0, sin(angle) * 12)
		if i % 2 == 0:
			var arch := Node3D.new()
			arch.position = at
			arch.rotation.y = PI * 0.5 - angle
			site.add_child(arch)
			_arch(arch, Vector3.ZERO, 6)
		else:
			MeadowGeometry.box(site, at + Vector3.UP * 2, Vector3(1.6, 4, 1.6), Color("453d4c"), true)
			MeadowGeometry.rock(site, at + Vector3(2, 0.5, 1), Vector3(1.7, 0.7, 1.1), Color("554653"), true)
	for i in 4:
		var angle := i * PI * 0.5
		var axis := Vector3(cos(angle), 0, sin(angle))
		var ramp := MeadowGeometry.box(site, axis * 15 + Vector3.UP * 0.025, Vector3(5, 0.15, 4.2), Color("8a7975"), true)
		ramp.look_at(site.to_global(axis * 13 + Vector3.UP * 0.125), Vector3.UP)
	# A weathered tofu idol anchors the open court without assigning future rewards.
	MeadowGeometry.box(site, Vector3(0, 0.7, -5), Vector3(4.5, 1.2, 4.5), Color("655559"), true)
	MeadowGeometry.box(site, Vector3(0, 3, -5), Vector3(3.4, 3.4, 2.8), Color("b39b7e"), true)
	for side in [-1.0, 1.0]:
		MeadowGeometry.box(site, Vector3(side * 0.7, 3.3, -3.57), Vector3(0.35, 0.55, 0.07), Color("453d45"))
	MeadowGeometry.box(site, Vector3(0, 2.7, -3.57), Vector3(0.6, 0.1, 0.07), Color("453d45"))

static func _cove(site: Node3D) -> void:
	for side in [-1.0, 1.0]:
		_arch(site, Vector3(side * 14, 0, 4), 7)
	for i in 9:
		var plank := MeadowGeometry.box(site, Vector3(8 + i * 0.45, 0.4 + absf(i - 4) * 0.1, -6), Vector3(0.3, 0.25, 7 - absf(i - 4) * 0.6), Color("8d6e57"), true)
		plank.rotation.z = (i - 4) * 0.16
	MeadowGeometry.box(site, Vector3(10, 2, -6), Vector3(0.25, 4, 0.25), Color("695143"), true)
	var sail := MeadowGeometry.box(site, Vector3(11.6, 3, -6), Vector3(3, 1.4, 0.08), Color("d4bea1"))
	sail.rotation.z = -0.15
	for i in 6:
		_disc(site, Vector3(5 + sin(i) * 2, 0.02, -8 + i * 2), 0.5, 0.05, Color("e6cba4"))

static func _camp(site: Node3D) -> void:
	for side in [-1.0, 1.0]:
		var center := Vector3(side * 10, 0, -4)
		for pitch in [-1.0, 1.0]:
			var roof := MeadowGeometry.box(site, center + Vector3(pitch * 0.9, 1.4, 0), Vector3(2.6, 0.15, 5), Color("c8ac78"))
			roof.rotation.z = -pitch * 0.75
		for end in [-1.0, 1.0]:
			MeadowGeometry.box(site, center + Vector3(0, 1.15, end * 2.35), Vector3(0.15, 2.3, 0.15), Color("715844"), true)
		MeadowGeometry.box(site, center + Vector3(0, 0.2, 0), Vector3(3.3, 0.3, 4), Color("957e6c"), true)
		MeadowGeometry.box(site, Vector3(side * 9, 0.45, 3), Vector3(4, 0.45, 1), Color("826b55"), true)
		MeadowGeometry.box(site, center + Vector3(side * 3.1, 0.45, 1), Vector3(1, 0.9, 1.2), Color("9e825f"), true)
	for i in 10:
		var angle := i * TAU / 10
		MeadowGeometry.rock(site, Vector3(cos(angle) * 1.4, 0.2, sin(angle) * 1.4), Vector3(0.4, 0.25, 0.4), Color("635861"))
	for side in [-1.0, 1.0]:
		var log := MeadowGeometry.box(site, Vector3(0, 0.2, 0), Vector3(1.7, 0.25, 0.3), Color("b2754c"))
		log.rotation.y = side * 0.6
	_disc(site, Vector3(0, 0.32, 0), 0.65, 0.06, Color("e59243"))
	MeadowGeometry.box(site, Vector3(0, 0.5, 8), Vector3(4, 1, 1.6), Color("8e7966"), true)

static func _arch(parent: Node3D, at: Vector3, height: float) -> void:
	for side in [-1.0, 1.0]:
		MeadowGeometry.box(parent, at + Vector3(side * 3.5, height * 0.5, 0), Vector3(1.5, height, 2.2), Color("48404b"), true)
		MeadowGeometry.box(parent, at + Vector3(side * 3.5, height + 0.2, 0), Vector3(1.9, 0.4, 2.6), Color("958173"))
	MeadowGeometry.box(parent, at + Vector3(0, height, 0), Vector3(8.5, 1.1, 2.3), Color("655260"), true)

static func _disc(parent: Node3D, at: Vector3, radius: float, height: float, color: Color, solid: bool = false) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 24
	mesh.material = MeadowGeometry.material(color)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	parent.add_child(instance)
	if solid: instance.create_convex_collision()
	return instance

static func _coastal_stacks(parent: Node3D) -> void:
	for i in 12:
		var angle := -0.6 + i * 0.11
		var at := VolcanicTerrain.CENTER + Vector2(cos(angle), sin(angle)) * VolcanicTerrain.LAND_RADIUS * 0.98
		for j in 4:
			var foot := VolcanicTerrain.point(at + Vector2(j * 1.7, j * 0.5))
			MeadowGeometry.box(parent, foot + Vector3.UP * (2.5 + j), Vector3(1.5, 5 + j * 2, 1.7), Color("494352"), true)

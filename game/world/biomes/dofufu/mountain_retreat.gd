class_name MountainRetreat
extends Node3D
## A discoverable hermit's hut, lived-in objects, sheltered paths and ruined lookout.

var terrain: DofufuTerrain
var hermit: MountainHermit
var view_focus: Node3D
var roofs: Array[MeshInstance3D] = []
var _materials := DofufuMountainMaterials.new()

func _ready() -> void:
	name = "HiddenMountainRetreat"
	_hut()
	_camp()
	_lookout()
	_waymarks()
	hermit = MountainHermit.new()
	hermit.position = terrain.point(-580, 127)
	add_child(hermit)
	# Outcrops screen the clearing from the main pass, leaving its apron open.
	for at in [Vector2(-559, 113), Vector2(-589, 117), Vector2(-590, 133)]:
		_boulder(terrain.point(at.x, at.y, 1.5), Vector3(3.5, 3, 2.8))
	StaticDecorationBatch.build(self)

func _hut() -> void:
	var center := terrain.point(DofufuMountainPaths.HUT.x, DofufuMountainPaths.HUT.y)
	# Floor is flush with the sampled clearing, with a genuinely open doorway.
	_box(center - Vector3.UP * 0.15, Vector3(7, 0.3, 6), 0)
	for side in [-1, 1]:
		_box(center + Vector3(side * 3.35, 1.8, 0), Vector3(0.3, 3.6, 6), 3, true)
		_box(center + Vector3(side * 2.2, 1.8, 2.85), Vector3(2.6, 3.6, 0.3), 3, true)
	_box(center + Vector3(0, 1.8, -2.85), Vector3(7, 3.6, 0.3), 3, true)
	for x in [-3.5, 3.5]:
		for z in [-3, 3]: _box(center + Vector3(x, 1.9, z), Vector3(0.3, 3.8, 0.3), 3, true)
	for side in [-1, 1]:
		var roof := _box(center + Vector3(0, 4.25, side * 1.8), Vector3(8.5, 0.35, 4.1), 3, true)
		roof.rotation.x = side * 0.40
		roofs.append(roof)
	_box(center + Vector3(0, 5.05, 0), Vector3(8.7, 0.3, 0.3), 3)
	# Lattice window, herb drying rail and a worktable visible through the door.
	for x in [-2.8, -2.3, -1.8]:
		_box(center + Vector3(x, 2.15, 3.05), Vector3(0.08, 1.2, 0.12), 3)
	_box(center + Vector3(-2.3, 2.15, 3.1), Vector3(1.4, 0.08, 0.12), 3)
	_box(center + Vector3(1.7, 1.0, -1.8), Vector3(2, 0.18, 1), 3, true)
	for x in [1.0, 2.4]: _box(center + Vector3(x, 0.45, -1.8), Vector3(0.18, 0.9, 0.7), 3, true)
	for i in 4:
		_herbs(center + Vector3(1 + i * 0.45, 1.75, 3.3), 0.5)
	_tea(center + Vector3(1.7, 1.12, -1.8))
	var lamp := MeadowGeometry.box(self, center + Vector3(1.1, 2.4, 3.3), Vector3(0.35, 0.5, 0.35), Color("edb76d"))
	var glow := lamp.mesh.material as StandardMaterial3D
	glow.emission_enabled = true
	glow.emission = Color("c28536")
	glow.emission_energy_multiplier = 0.7

func _camp() -> void:
	var center := terrain.point(-577, 133)
	for i in 9:
		var angle := i * TAU / 9
		_boulder(center + Vector3(cos(angle), 0.15, sin(angle)) * 0.8, Vector3(0.25, 0.2, 0.22))
	for i in 3:
		var log := _box(center + Vector3(0, 0.2 + i * 0.08, 0), Vector3(1.1, 0.18, 0.2), 3)
		log.rotation.y = i * PI / 3
	for at in [Vector2(-581, 132), Vector2(-573, 135)]:
		_box(terrain.point(at.x, at.y, 0.4), Vector3(1.4, 0.8, 0.6), 3, true)
	# Storage, a chopping block, tea table and a small herb garden.
	_box(terrain.point(-582, 121, 0.65), Vector3(1.3, 1.3, 1.2), 3, true)
	_box(terrain.point(-581, 123, 0.3), Vector3(1.1, 0.6, 0.9), 3, true)
	for x in [-580.0, -578.8, -577.6]:
		_box(terrain.point(x, 114, 0.2), Vector3(0.9, 0.4, 2.2), 3, true)
		for z in [113.5, 114.3]:
			_herbs(terrain.point(x, z, 0.42), 0.7)

func _herbs(at: Vector3, height: float) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for leaf in 9:
		var angle := leaf * 2.4
		var reach := Vector3(cos(angle) * 0.35, height * (0.5 + leaf * 0.05), sin(angle) * 0.35)
		var width := Vector3(-sin(angle), 0, cos(angle)) * 0.09
		for corner in [Vector3.ZERO, reach * 0.5 + width, reach, Vector3.ZERO, reach, reach * 0.5 - width]:
			surface.add_vertex(corner)
	surface.generate_normals()
	var material := MeadowGeometry.material(Color("587943"))
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.next_pass = null
	surface.set_material(material)
	var view := MeshInstance3D.new()
	view.mesh = surface.commit()
	view.position = at
	view.set_meta("static_ornament_mesh", true)
	add_child(view)

func _tea(at: Vector3) -> void:
	var pot := MeshInstance3D.new()
	var body := SphereMesh.new()
	body.radius = 0.24
	body.height = 0.4
	body.radial_segments = 12
	body.rings = 6
	body.material = MeadowGeometry.material(Color("7e928b"))
	pot.mesh = body
	pot.position = at + Vector3.UP * 0.2
	add_child(pot)
	var lid := MeadowGeometry.box(self, at + Vector3.UP * 0.43, Vector3(0.18, 0.06, 0.18), Color("5e736b"))
	lid.rotation.y = PI / 4
	var spout := MeadowGeometry.box(self, at + Vector3(0.28, 0.26, 0), Vector3(0.32, 0.12, 0.12), Color("7e928b"))
	spout.rotation.z = PI / 5
	for side in [-1, 1]:
		var cup := MeadowGeometry.box(self, at + Vector3(0, 0.1, side * 0.35), Vector3(0.2, 0.2, 0.2), Color("9cac9f"))
		MeadowGeometry.box(self, cup.position + Vector3.UP * 0.105, Vector3(0.15, 0.01, 0.15), Color("65512d"))

func _lookout() -> void:
	var center := terrain.point(DofufuMountainPaths.LOOKOUT.x, DofufuMountainPaths.LOOKOUT.y)
	for side in [-1, 1]:
		for end in [-1, 1]:
			_box(center + Vector3(side * 4, 1.3, end * 4), Vector3(0.8, 2.6, 0.8), 0, true)
	_box(center + Vector3(0, 0.25, -3), Vector3(6, 0.5, 0.7), 0, true)
	for i in 6:
		_boulder(center + Vector3(i - 3, 0.2, -4.2), Vector3(0.55, 0.4, 0.6))
	MeadowGeometry.signpost(self, center + Vector3(4.5, 0, 0), "OLD RIDGE LOOKOUT\nJade Lantern beyond the pass")

func _waymarks() -> void:
	for route in terrain.paths.routes:
		for index in range(1, route.size()):
			var at := route[index]
			var toward := (at - route[index - 1]).normalized()
			var side := Vector3(-toward.z, 0, toward.x) * 3.8
			var base := terrain.point(at.x + side.x, at.z + side.z)
			for tier in 3:
				_boulder(base + Vector3.UP * (0.15 + tier * 0.25), Vector3.ONE * (0.4 - tier * 0.08))

func _box(at: Vector3, size: Vector3, tile: int, solid: bool = false) -> MeshInstance3D:
	var view := MeadowGeometry.box(self, at, size, Color.WHITE, solid)
	view.material_override = _materials.surface(tile)
	return view

func _boulder(at: Vector3, size: Vector3) -> void:
	var view := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radial_segments = 10
	mesh.rings = 5
	view.mesh = mesh
	view.position = at
	view.scale = size
	view.material_override = _materials.surface(0)
	add_child(view)
	if size.y > 1: view.create_convex_collision()

func _process(_delta: float) -> void:
	if not is_instance_valid(view_focus): return
	var camera := get_viewport().get_camera_3d()
	var at := Vector2(view_focus.global_position.x, view_focus.global_position.z)
	var overhead := camera != null and camera.global_position.y > view_focus.global_position.y + 5
	var inside := absf(at.x - DofufuMountainPaths.HUT.x) < 4.2 and absf(at.y - DofufuMountainPaths.HUT.y) < 4
	for roof in roofs: roof.visible = not (inside and overhead)

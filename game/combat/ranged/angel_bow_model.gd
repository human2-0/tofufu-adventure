class_name AngelBowModel
extends Node3D
## Ivory recurve, gold laurel, plum grip, working string and nocked arrow.

const TEXTURE: Texture2D = preload("res://assets/weapons/angel_bow/laurel-ivory.png")
var draw: float = 0.0
var loaded: bool = true
var _strings: Array[MeshInstance3D] = []
var _arrow: Node3D
var _ember: MeshInstance3D
var _gold: StandardMaterial3D

func _ready() -> void:
	var ivory := material(Color.WHITE)
	ivory.albedo_texture = TEXTURE
	ivory.roughness = 0.65
	_gold = material(Color("f6be45"))
	_gold.metallic = 0.45
	for side: float in [-1.0, 1.0]:
		_limb(side, ivory)
		for index in 5:
			var y := side * (0.18 + index * 0.092)
			for edge: float in [-1.0, 1.0]:
				var leaf := MeshInstance3D.new()
				var shape := SphereMesh.new()
				shape.radius = 0.065
				shape.height = 0.13
				leaf.mesh = shape
				leaf.material_override = _gold
				leaf.position = Vector3(edge * 0.045, y, -0.13 - sin(absf(y) * 3.5) * 0.06)
				leaf.scale = Vector3(0.38, 1.0, 0.24)
				leaf.rotation.z = edge * side * 0.7
				add_child(leaf)
		segment(self, Vector3(0, side * 0.075, 0), Vector3(0, side * 0.105, 0), 0.058, _gold)
		_strings.append(segment(self, Vector3.ZERO, Vector3.UP, 0.005, material(Color("ffeac0"))))
	segment(self, Vector3(0, -0.075, 0), Vector3(0, 0.075, 0), 0.046, material(Color("4c3048")))
	_arrow = Node3D.new()
	add_child(_arrow)
	arrow(_arrow, false)
	_ember = MeshInstance3D.new()
	var glow := SphereMesh.new()
	glow.radius = 0.045
	glow.height = 0.09
	_ember.mesh = glow
	var fire := material(Color("ffc34d"))
	fire.emission_enabled = true
	fire.emission = Color("ff721b")
	fire.emission_energy_multiplier = 3.0
	_ember.material_override = fire
	add_child(_ember)
	present(0, true)

func present(amount: float, has_arrow: bool) -> void:
	draw = clampf(amount, 0, 1)
	loaded = has_arrow
	if _strings.is_empty(): return
	var nock := Vector3(0, 0, 0.12 + draw * 0.34)
	for index in 2:
		place_segment(_strings[index], Vector3(0, 0.84 if index == 0 else -0.84, 0.12), nock)
	_arrow.visible = has_arrow
	_arrow.position = nock
	_ember.visible = draw > 0.0
	_ember.position = nock + Vector3(0, 0, -0.7)
	_ember.scale = Vector3.ONE * (0.5 + draw)

static func material(color: Color) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.55
	return result

static func segment(parent: Node3D, start: Vector3, end: Vector3, radius: float, surface: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius * 0.94
	cylinder.bottom_radius = radius
	cylinder.height = 1.0
	cylinder.radial_segments = 8
	instance.mesh = cylinder
	instance.material_override = surface
	parent.add_child(instance)
	place_segment(instance, start, end)
	return instance

static func place_segment(mesh: MeshInstance3D, start: Vector3, end: Vector3) -> void:
	var offset := end - start
	var direction := offset.normalized()
	var side := direction.cross(Vector3.FORWARD).normalized()
	if side.is_zero_approx(): side = Vector3.RIGHT
	mesh.transform = Transform3D(Basis(side, direction * offset.length(), side.cross(direction)), (start + end) * 0.5)

func _limb(side: float, surface: Material) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_material(surface)
	tool.set_smooth_group(0)
	for ring in 18:
		for edge in 12:
			var corners: Array[Vector2] = [Vector2(ring, edge), Vector2(ring + 1, edge), Vector2(ring, edge + 1), Vector2(ring + 1, edge + 1)]
			var order: Array[int] = [0, 2, 1, 1, 2, 3]
			if side < 0: order.assign([0, 1, 2, 1, 3, 2])
			for index in order:
				var uv := Vector2(corners[index].y / 12.0, corners[index].x / 18.0)
				var t := uv.y
				var center := Vector3(0, side * (0.08 + t * 0.76), -sin(t * PI) * 0.25 + t * 0.12)
				var radial := Vector3(cos(uv.x * TAU), 0, sin(uv.x * TAU)) * lerpf(0.045, 0.018, t)
				tool.set_uv(uv)
				tool.add_vertex(center + radial)
	tool.generate_normals()
	var limb := MeshInstance3D.new()
	limb.mesh = tool.commit()
	add_child(limb)

static func arrow(parent: Node3D, fire: bool) -> void:
	segment(parent, Vector3.ZERO, Vector3(0, 0, -0.68), 0.009, material(Color("bb8d4f")))
	for side: float in [-1.0, 1.0]:
		var feather := MeshInstance3D.new()
		var vane := BoxMesh.new()
		vane.size = Vector3(0.005, 0.055, 0.13)
		feather.mesh = vane
		feather.material_override = material(Color("edd9ff"))
		feather.position = Vector3(0, side * 0.021, -0.07)
		parent.add_child(feather)
	var head := MeshInstance3D.new()
	var point := PrismMesh.new()
	point.size = Vector3(0.065, 0.12, 0.025)
	head.mesh = point
	head.rotation.x = -PI * 0.5
	head.position.z = -0.7
	var gold := material(Color("ffbd41") if fire else Color("ffe1a0"))
	gold.emission_enabled = true
	gold.emission = Color("ff6e18") if fire else Color("604218")
	gold.emission_energy_multiplier = 2.0 if fire else 0.25
	head.material_override = gold
	parent.add_child(head)

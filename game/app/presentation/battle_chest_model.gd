class_name BattleChestModel
extends Node3D
## Three readable silhouettes, textured wood and a hinged lid; no idle processing.
const WOOD: Texture2D = preload("res://assets/environment/royale_chests/painted_wood.png")
const COLORS: Array[Color] = [Color("bd956a"), Color("6ac5ef"), Color("ffd36d")]
const TITLES: Array[String] = ["Basic chest", "Rare chest", "Legendary chest"]
var tier: int = 0
var opened: bool = false
var lid: Node3D
var badge: Label3D
var seal: MeshInstance3D
var _tween: Tween

func _ready() -> void:
	var wood := StandardMaterial3D.new()
	wood.albedo_texture = WOOD
	wood.uv1_triplanar = true
	wood.uv1_scale = Vector3.ONE * 0.7
	wood.albedo_color = [Color.WHITE, Color("638fbd"), Color("6b477e")][tier]
	var metal := StandardMaterial3D.new()
	metal.albedo_color = COLORS[tier]
	metal.metallic = 0.4
	metal.roughness = 0.5
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color("243b3d")
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.5, 0.96, 1.1)
	collision.shape = shape
	collision.position.y = 0.48
	body.add_child(collision)
	_box(self, Vector3(0, 0.47, 0), Vector3(1.5, 0.94, 1.1), wood)
	_box(self, Vector3(0, 0.95, 0), Vector3(1.52, 0.06, 1.12), dark)
	lid = Node3D.new()
	lid.position = Vector3(0, 0.98, -0.55)
	add_child(lid)
	_box(lid, Vector3(0, 0.08, 0.55), Vector3(1.58, 0.18, 1.18), wood)
	for x in [-0.59, 0.59]:
		_box(self, Vector3(x, 0.49, 0.565), Vector3(0.13, 0.9, 0.06), metal)
		_box(lid, Vector3(x, 0.19, 0.55), Vector3(0.13, 0.06, 1.2), metal)
	_box(self, Vector3(0, 0.65, 0.59), Vector3(0.23, 0.3, 0.09), metal)
	if tier >= 1:
		_box(lid, Vector3(0, 0.24, 0.55), Vector3(1.30, 0.22, 0.92), wood)
		for x in [-0.78, 0.78]:
			_box(self, Vector3(x, 0.48, 0), Vector3(0.12, 1.02, 1.18), metal)
		seal = _box(self, Vector3(0, 0.65, 0.66), Vector3(0.14, 0.14, 0.05), metal)
		seal.rotation.z = PI * 0.25
	if tier == 2: _crown(metal)
	badge = Label3D.new()
	badge.position.y = 1.85 if tier == 2 else 1.55
	badge.font_size = 26
	badge.pixel_size = 0.009
	badge.modulate = COLORS[tier]
	badge.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	badge.visibility_range_end = 16
	add_child(badge)
	_update_title()

func _crown(metal: StandardMaterial3D) -> void:
	_box(lid, Vector3(0, 0.45, 0.55), Vector3(0.64, 0.1, 0.5), metal)
	for x in [-0.25, 0.0, 0.25]:
		var spike := CylinderMesh.new()
		spike.top_radius = 0
		spike.bottom_radius = 0.12
		spike.height = 0.38 if x == 0 else 0.26
		spike.radial_segments = 4
		_mesh(lid, Vector3(x, 0.62, 0.55), spike, metal)
	for side in [-1, 1]:
		var wing := _box(lid, Vector3(side * 0.91, 0.18, 0.55), Vector3(0.3, 0.12, 0.75), metal)
		wing.rotation.z = side * 0.45

func _box(parent: Node3D, at: Vector3, dimensions: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	return _mesh(parent, at, mesh, material)

func _mesh(parent: Node3D, at: Vector3, mesh: Mesh, material: Material) -> MeshInstance3D:
	var view := MeshInstance3D.new()
	view.mesh = mesh
	view.material_override = material
	view.position = at
	view.visibility_range_end = 65
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(view)
	return view

func present(value: bool, _unclaimed: bool, animate: bool) -> void:
	if animate and opened == value: return
	opened = value
	badge.visible = not opened
	if seal != null: seal.visible = not opened
	if is_instance_valid(_tween): _tween.kill()
	if not animate:
		lid.rotation.x = -1.2 if value else 0.0
		return
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(lid, "rotation:x", -1.2 if value else 0.0, 0.5)

func _update_title() -> void:
	badge.text = tr(TITLES[tier])

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready(): _update_title()

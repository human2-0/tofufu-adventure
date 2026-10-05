class_name PracticeDummy
extends StaticBody3D
## Stationary, reward-free combat target with hit feedback and automatic recovery.

var target: Damageable
var hit_count: int = 0
var last_damage: float = 0.0
var _reset_in: float = 0.0
var _figure: Node3D
var _label: Label3D

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var collider := CollisionShape3D.new()
	var bounds := CylinderShape3D.new()
	bounds.radius = 0.42
	bounds.height = 1.7
	collider.shape = bounds
	collider.position.y = 0.85
	add_child(collider)
	var head_collider := CollisionShape3D.new()
	var head_shape := SphereShape3D.new()
	head_shape.radius = 0.32
	head_collider.shape = head_shape
	head_collider.position.y = 1.85
	add_child(head_collider)
	target = Damageable.new()
	target.maximum = 200.0
	target.headshot_height = 1.56
	target.body = self
	target.position.y = 0.85
	add_child(target)
	_build_figure()
	target.hit.connect(_hit)
	target.depleted.connect(_depleted)
	_label = Label3D.new()
	_label.position.y = 2.6
	_label.font_size = 28
	_label.pixel_size = 0.008
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.modulate = Color("fff0bf")
	_label.no_depth_test = true
	_label.render_priority = 127
	add_child(_label)
	_show_status()

func _physics_process(delta: float) -> void:
	_figure.rotation.z = lerpf(_figure.rotation.z, 0.0, minf(1.0, delta * 9.0))
	if _reset_in <= 0.0:
		return
	_reset_in -= delta
	if _reset_in <= 0.0:
		target.restore()
		target.invulnerability = 0.0
		_show_status()

func _hit(amount: float, direction: Vector3) -> void:
	hit_count += 1
	last_damage = amount
	_figure.rotation.z = -0.22 if direction.x >= 0 else 0.22
	_reset_in = 4.0
	_show_status()

func _depleted() -> void:
	_reset_in = 1.5
	_label.text = "NICE HIT!\nResetting…"

func _show_status() -> void:
	_label.text = "PRACTICE · %d / 200\n%s" % [int(target.current), "Knife / fists / soy gun" if hit_count == 0 else "Last hit: %d" % int(last_damage)]

func _build_figure() -> void:
	_figure = Node3D.new()
	add_child(_figure)
	_box(Vector3(0, 0.1, 0), Vector3(1.1, 0.2, 0.8), Color("816548"))
	_box(Vector3(0, 0.85, 0), Vector3(0.16, 1.6, 0.16), Color("8a6949"))
	_box(Vector3(0, 1.2, 0), Vector3(1.7, 0.14, 0.14), Color("9f7950"))
	var torso := CylinderMesh.new()
	torso.top_radius = 0.4
	torso.bottom_radius = 0.32
	torso.height = 0.85
	torso.radial_segments = 12
	_mesh(torso, Vector3(0, 1.1, 0), Color("dab775"))
	var head := SphereMesh.new()
	head.radius = 0.32
	head.height = 0.58
	_mesh(head, Vector3(0, 1.85, 0), Color("efd190"))
	for side in [-1.0, 1.0]:
		_box(Vector3(side * 0.12, 1.87, 0.3), Vector3(0.05, 0.07, 0.025), Color("655143"))
	for y in [0.77, 1.42]:
		_box(Vector3(0, y, 0.38), Vector3(0.73, 0.07, 0.05), Color("876b50"))
	for i in 3:
		var target_disc := CylinderMesh.new()
		target_disc.top_radius = 0.27 - i * 0.085
		target_disc.bottom_radius = target_disc.top_radius
		target_disc.height = 0.025
		var ring := _mesh(target_disc, Vector3(0, 1.1, 0.405 + i * 0.02), Color("af6659") if i % 2 == 0 else Color("fff0be"))
		ring.rotation.x = PI * 0.5

func _box(at: Vector3, size: Vector3, color: Color) -> void:
	var box := BoxMesh.new()
	box.size = size
	_mesh(box, at, color)

func _mesh(mesh: PrimitiveMesh, at: Vector3, color: Color) -> MeshInstance3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	material.roughness = 1.0
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	_figure.add_child(instance)
	return instance

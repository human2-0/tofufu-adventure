class_name WorldItemDrop
extends CharacterBody3D
## A world-owned item with swept collisions and local-only focus presentation.

const RADIUS: float = 0.38
var drop_id: int
var item_id: String
var count: int = 1
var reserve: float = 100.0
var authoritative: bool = true
var label: Label3D
var ring: MeshInstance3D
var last_safe: Vector3

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	floor_snap_length = 0.15
	var collider := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = RADIUS
	collider.shape = shape
	add_child(collider)
	label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 30
	label.pixel_size = 0.006
	label.position.y = 0.6
	label.outline_size = 7
	add_child(label)
	ring = MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.32
	mesh.outer_radius = 0.39
	ring.mesh = mesh
	ring.position.y = -0.22
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("ffdc79")
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = material
	add_child(ring)
	set_focus(false, "")

func _physics_process(delta: float) -> void:
	if not authoritative: return
	velocity.y -= 18.0 * delta
	move_and_slide()
	velocity.x = move_toward(velocity.x, 0, 8 * delta)
	velocity.z = move_toward(velocity.z, 0, 8 * delta)
	if is_on_floor(): last_safe = global_position
	if global_position.y < -8:
		global_position = last_safe
		velocity = Vector3.ZERO

func set_focus(active: bool, prompt: String) -> void:
	if label == null: return
	label.text = prompt
	label.visible = active
	ring.visible = active

func capture() -> Array:
	var p := global_position
	return [drop_id, item_id, count, reserve, p.x, p.y, p.z]

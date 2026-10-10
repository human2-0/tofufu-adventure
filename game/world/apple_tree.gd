class_name AppleTree
extends StaticBody3D
## Harvestable 3D apple tree with falling fruit and timed regrowth.

signal apples_felled(count: int, at: Vector3)
signal fruit_regrew

const REGROW_SECONDS: float = 180.0
const APPLE_YIELD: int = 4

var apples_ready: bool = true
var regrow_remaining: float = 0.0
var apple_nodes: Array[Node3D] = []
var apple_home_positions: Array[Vector3] = []
var _fruit_fall_tweens: Array[Tween] = []
var prompt: Label3D
var ring: MeshInstance3D

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_build_trunk_collision()
	apple_nodes = AppleTreeVisuals.build(self)
	for apple in apple_nodes: apple_home_positions.append(apple.position)
	_build_prompt()
	_build_ring()
	present(false, "")

func _build_trunk_collision() -> void:
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 0.32
	cylinder.height = 2.2
	shape.shape = cylinder
	shape.position.y = 1.1
	add_child(shape)

func _build_prompt() -> void:
	prompt = Label3D.new()
	prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt.font_size = 28
	prompt.outline_size = 7
	prompt.pixel_size = 0.008
	prompt.position.y = 2.7
	prompt.no_depth_test = true
	prompt.ignore_occlusion_culling = true
	prompt.render_priority = 127
	add_child(prompt)

func _build_ring() -> void:
	ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 1.05
	torus.outer_radius = 1.15
	ring.mesh = torus
	ring.position.y = 0.06
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color("ff6b6b")
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = glow
	add_child(ring)

func can_harvest() -> bool:
	return apples_ready and regrow_remaining <= 0.0

func harvest() -> int:
	if not can_harvest(): return 0
	apples_ready = false
	regrow_remaining = REGROW_SECONDS
	_fall_apples(true)
	return APPLE_YIELD

func apply_world_state(regrow: float) -> void:
	var was_ready := apples_ready
	regrow_remaining = maxf(0.0, regrow)
	apples_ready = regrow_remaining <= 0.0
	if was_ready and not apples_ready: _fall_apples(false)
	elif not was_ready and apples_ready: _regrow_apples()

func _fall_apples(emit_drop: bool) -> void:
	for index in apple_nodes.size():
		var apple := apple_nodes[index]
		var landing := Vector3((index % 2) * 0.36 - 0.18, 0.14, 1.55 + (index / 2) * 0.36 - 0.18)
		var fall := create_tween().set_parallel()
		_fruit_fall_tweens.append(fall)
		fall.tween_property(apple, "position", landing, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		fall.tween_property(apple, "rotation", Vector3(0.8, index * 1.3, 1.1), 0.45)
		fall.chain().tween_callback(func() -> void: apple.visible = false)
	if emit_drop:
		var drop_at := to_global(Vector3(0, 0.0, 1.55))
		var drop_tween := create_tween()
		drop_tween.tween_interval(0.45)
		drop_tween.tween_callback(func() -> void: apples_felled.emit(APPLE_YIELD, drop_at))

func step(delta: float) -> void:
	if regrow_remaining <= 0.0: return
	regrow_remaining = maxf(0.0, regrow_remaining - delta)
	if regrow_remaining > 0.0: return
	apples_ready = true
	_regrow_apples()
	fruit_regrew.emit()

func _regrow_apples() -> void:
	for tween in _fruit_fall_tweens:
		if tween.is_running(): tween.kill()
	_fruit_fall_tweens.clear()
	for index in apple_nodes.size():
		var apple := apple_nodes[index]
		apple.position = apple_home_positions[index]
		apple.rotation = Vector3.ZERO
		apple.scale = Vector3.ONE * 0.35
		apple.visible = true
		create_tween().tween_property(apple, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _physics_process(delta: float) -> void:
	step(delta)

func react_to_hit(_amount: float, _direction: Vector3) -> void:
	var resting_scale := scale
	var tween := create_tween()
	tween.tween_property(self, "scale", resting_scale * Vector3(1.04, 0.97, 1.04), 0.06)
	tween.tween_property(self, "scale", resting_scale, 0.14)

func present(focused: bool, text: String) -> void:
	if ring != null: ring.visible = focused
	if prompt != null:
		prompt.visible = focused
		prompt.text = text

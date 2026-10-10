class_name FactoryEffectPool
extends Node3D
## Fixed four-slot, 64-particle pool. All effects stay local to their machine.

const SLOTS: int = 4
const PARTICLES: int = 16
var burst_count: int = 0
var last_kind: String = ""
var _batches: Array[MultiMeshInstance3D] = []
var _ages: Array[float] = []
var _durations: Array[float] = []
var _origins: Array[Vector3] = []
var _colors: Array[Color] = []
var _styles: Array[String] = []
var _next: int = 0

func _ready() -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.roughness = 1.0
	for slot in SLOTS:
		var batch := MultiMeshInstance3D.new()
		batch.multimesh = MultiMesh.new()
		batch.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		batch.multimesh.use_colors = true
		batch.multimesh.mesh = mesh
		batch.multimesh.instance_count = PARTICLES
		batch.material_override = material
		batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		batch.visible = false
		add_child(batch)
		_batches.append(batch)
		_ages.append(10.0)
		_durations.append(1.0)
		_origins.append(Vector3.ZERO)
		_colors.append(Color.WHITE)
		_styles.append("")

func burst(kind: String, at: Vector3) -> void:
	if _batches.is_empty(): return
	var slot: int = _next
	_next = (_next + 1) % SLOTS
	_origins[slot] = at
	_ages[slot] = 0.0
	_styles[slot] = kind
	_durations[slot] = 1.5 if kind in ["steam", "reject"] else 0.85
	_colors[slot] = Color("edf0dc") if kind in ["steam", "mist"] else Color("dfc993")
	if kind == "pour": _colors[slot] = Color("fbf4d6")
	if kind == "reject": _colors[slot] = Color("bcb1a0")
	_batches[slot].visible = true
	burst_count += 1
	last_kind = kind
	_draw(slot)

func clear() -> void:
	for slot in SLOTS:
		_ages[slot] = 10.0
		_batches[slot].visible = false

func _process(delta: float) -> void:
	for slot in SLOTS:
		if not _batches[slot].visible: continue
		_ages[slot] += delta
		if _ages[slot] >= _durations[slot]:
			_batches[slot].visible = false
			continue
		_draw(slot)

func _draw(slot: int) -> void:
	var age: float = _ages[slot]
	var progress: float = age / _durations[slot]
	var style: String = _styles[slot]
	var cloud: bool = style in ["steam", "mist", "reject", "dust"]
	for index in PARTICLES:
		var angle: float = index * 2.39996
		var spread: float = 0.2 + float(index % 5) * 0.12
		var drift := Vector3(cos(angle), 0, sin(angle)) * spread
		var at: Vector3 = _origins[slot] + drift * age
		var size: float = 0.06
		if cloud:
			at.y += age * (0.18 + float(index % 3) * 0.18)
			size = (0.13 + float(index % 3) * 0.045) * (1.0 + progress)
		else:
			at.y += (0.8 + float(index % 4) * 0.2) * age - 1.9 * age * age
			if style == "pour": at.y = _origins[slot].y - age * 0.7 + float(index % 4) * 0.06
		var shape := Vector3.ONE * size
		if style == "pour": shape = Vector3(size, size * 2.0, size)
		var color: Color = _colors[slot]
		color.a = (1.0 - progress) * (0.32 if cloud else 0.85)
		_batches[slot].multimesh.set_instance_transform(index, Transform3D(Basis.from_scale(shape), at))
		_batches[slot].multimesh.set_instance_color(index, color)

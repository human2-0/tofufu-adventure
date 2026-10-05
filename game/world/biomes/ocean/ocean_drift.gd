class_name OceanDrift
extends MultiMeshInstance3D
## Fixed-count suspended marine particles around the local underwater observer.

const CAPACITY: int = 128
var focus := Vector3.ZERO
var active: bool = false
var _clock: float = 0.0

func _ready() -> void:
	name = "MarineDrift"
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mote := SphereMesh.new()
	mote.radius = 0.018
	mote.height = 0.036
	mote.radial_segments = 4
	mote.rings = 2
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.62, 0.88, 0.85, 0.32)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mote.material = material
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mote
	multimesh.instance_count = CAPACITY

func _process(delta: float) -> void:
	_clock += delta
	visible = active
	if not active: return
	for i in CAPACITY:
		var offset := Vector3(sin(i * 73.15) * 12, sin(i * 38.2 + _clock * 0.05) * 3, cos(i * 19.72) * 12)
		offset.x += sin(_clock * 0.3 + i) * 0.4
		var at := focus + offset
		at.y = minf(at.y, OceanTerrain.WATER_LEVEL - 0.25)
		multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, to_local(at)))

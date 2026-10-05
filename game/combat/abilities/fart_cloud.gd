class_name FartCloud
extends Node3D
## Short-lived, authored-area damage left at the start of a super dash.

const LIFETIME: float = 0.9
const RADIUS: float = 1.45
const DAMAGE: float = 8.0

var targets: Array[Damageable] = []
var _remaining: float = LIFETIME
var _hit_targets: Array[Damageable] = []
var _puffs: Array[MeshInstance3D] = []

static func spawn(parent: Node, at: Vector3, damage_targets: Array[Damageable] = []) -> FartCloud:
	var cloud := FartCloud.new()
	var origin := at + Vector3.UP * 0.45
	cloud.position = (parent as Node3D).to_local(origin) if parent is Node3D else origin
	cloud.targets = damage_targets.duplicate()
	parent.add_child(cloud)
	return cloud

func _ready() -> void:
	for offset in [Vector3(-0.35, 0.05, 0), Vector3(0.28, 0.2, -0.12), Vector3(0.0, 0.48, 0.18)]:
		var puff := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.38
		sphere.height = 0.76
		puff.mesh = sphere
		puff.position = offset
		puff.material_override = _material()
		add_child(puff)
		_puffs.append(puff)
	_damage_targets()

func _physics_process(delta: float) -> void:
	_remaining -= delta
	_damage_targets()
	var progress := clampf(1.0 - _remaining / LIFETIME, 0.0, 1.0)
	for puff in _puffs:
		puff.scale = Vector3.ONE * lerpf(0.7, 1.75, progress)
		var material := puff.material_override as StandardMaterial3D
		material.albedo_color.a = lerpf(0.62, 0.0, progress)
	if _remaining <= 0.0: queue_free()

func _damage_targets() -> void:
	for target in targets:
		if not is_instance_valid(target) or target in _hit_targets or target.current <= 0.0:
			continue
		var offset := target.global_position - global_position
		offset.y = 0.0
		if offset.length_squared() > RADIUS * RADIUS:
			continue
		if target.damage(DAMAGE, offset.normalized(), Damageable.HitKind.SLIME):
			_hit_targets.append(target)
			CombatEffects.burst(self, target.global_position, str(int(DAMAGE)), Color("a4d968"))

func _material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.48, 0.73, 0.24, 0.62)
	return material

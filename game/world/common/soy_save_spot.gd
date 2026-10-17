class_name SoySaveSpot
extends Node3D
## Cosmetic personal state only: no healing, saving, teleporting or rewards here.

var title: String = "Soybean Save Spot"
var owned: bool = false
var base_body: StaticBody3D
var prompt: Label3D
var halo: MeshInstance3D
var motes: Array[MeshInstance3D] = []
var _pods: StandardMaterial3D
var _gold: StandardMaterial3D
var _age: float = 0.0
var _celebration: float = 0.0

func _ready() -> void:
	_pods = SoySaveSpotGeometry.material(Vector2(1, 0))
	_gold = SoySaveSpotGeometry.material(Vector2(1, 1), Color("b4bb8b"))
	SoySaveSpotGeometry.build(self, _pods, _gold)
	base_body = StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var base := CylinderShape3D.new()
	base.radius = 0.76
	base.height = 0.28
	collision.shape = base
	collision.position.y = 0.14
	base_body.add_child(collision)
	add_child(base_body)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.76
	ring.outer_radius = 0.83
	ring.rings = 24
	ring.ring_segments = 8
	halo = SoySaveSpotGeometry.mesh(self, ring, Vector3(0, 0.31, 0), Vector3(1, 0.35, 1), _gold)
	for i in 6:
		var sphere := SphereMesh.new()
		sphere.radial_segments = 8
		sphere.rings = 4
		motes.append(SoySaveSpotGeometry.mesh(self, sphere, Vector3.ZERO, Vector3.ONE * 0.055, _gold))
	prompt = Label3D.new()
	prompt.position.y = 3.0
	prompt.font_size = 30
	prompt.pixel_size = 0.009
	prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt.no_depth_test = false
	prompt.visibility_range_end = 22.0
	add_child(prompt)
	present(false, false, "")

func present(is_owned: bool, focused: bool, key: String) -> void:
	if is_owned and not owned: _celebration = 1.2
	owned = is_owned
	_pods.albedo_color = Color("ffe49a") if owned else Color.WHITE
	_pods.uv1_offset = Vector3(0.51, 0.51 if owned else 0.01, 0)
	_gold.albedo_color = Color.WHITE if owned else Color("a2ad7b")
	_gold.emission_enabled = owned
	_gold.emission = Color("ffd778")
	_gold.emission_energy_multiplier = 0.45
	halo.visible = owned
	for mote in motes: mote.visible = owned
	prompt.visible = focused
	prompt.text = title + "\n" + ("Owned · Soybean save spot" if owned else "[%s] Claim soybean save spot" % key)
	prompt.modulate = Color("ffe6a1") if owned else Color("e4f5cd")

func _process(delta: float) -> void:
	if not owned: return
	_age += delta
	_celebration = maxf(0.0, _celebration - delta)
	halo.scale = Vector3.ONE * (1.0 + sin(_age * 2.0) * 0.035 + _celebration * 0.15)
	for i in motes.size():
		var angle := _age * 0.5 + i * TAU / motes.size()
		motes[i].position = Vector3(cos(angle) * 0.85, 0.5 + fmod(_age * 0.3 + i * 0.3, 1.8), sin(angle) * 0.85)

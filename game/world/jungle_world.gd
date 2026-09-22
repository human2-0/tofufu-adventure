class_name JungleWorld
extends Node3D
## Scenery-only jungle extension, entered through the eastern level-eight pass.

const ENTRY_LEVEL: int = 8
const GATE_LAYER: int = 8
var farm: FarmTerrain

func _ready() -> void:
	name = "JungleWorld"
	JungleTerrain.build(self, farm)
	_entrance()
	_landmarks()
	_forest()
	_boundaries()

func point(x: float, z: float, lift: float = 0) -> Vector3:
	return Vector3(x, JungleTerrain.height_at(x, z, farm) + lift, z)

func _entrance() -> void:
	var arch := Node3D.new()
	add_child(arch)
	arch.position = Vector3(41, farm.height_at(41, 26), 26)
	arch.rotation.y = PI * 0.5
	JungleProps.arch(arch, Vector3.ZERO, 10, 7)
	MeadowGeometry.signpost(self, Vector3(35, farm.height_at(35, 22), 22), "JADEWILD JUNGLE · LV 8  >")
	var label := Label3D.new()
	label.text = "JADEWILD\nLEVEL 8 · WALK THROUGH"
	label.position = arch.position + Vector3(-1, 8.5, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 48
	label.pixel_size = 0.018
	label.modulate = Color("e3edaa")
	add_child(label)
	# A dedicated collision layer lets each character cross at their own level.
	var gate := MeadowGeometry.box(self, Vector3(41, 35, 26), Vector3(2, 100, 10), Color.WHITE, true)
	gate.name = "LevelEightGate"
	gate.visible = false
	(gate.get_child(0) as StaticBody3D).collision_layer = 1 << (GATE_LAYER - 1)

func _landmarks() -> void:
	# Broken sanctuary and its walkable, low steps anchor the inner clearing.
	for i in 4:
		MeadowGeometry.box(self, point(77, -1, i * 0.24), Vector3(10 - i * 1.4, 0.5, 8 - i), Color("81947b"), true)
	JungleProps.arch(self, point(77, -3, 0.8), 5, 5)
	for at in [Vector2(70, 2), Vector2(83, 3), Vector2(72, -7)]:
		MeadowGeometry.box(self, point(at.x, at.y, 1.2), Vector3(1.4, 2.4, 1.4), Color("78917a"), true)
		JungleProps.fern(self, point(at.x, at.y, 2.5), 1.5)
	# Turquoise plunge pool and stepped waterfall rock face, all decorative.
	MeadowGeometry.rock(self, point(89, -18, 0.1), Vector3(7, 0.18, 5), Color("58b6b0"))
	for i in 5:
		MeadowGeometry.rock(self, point(86 + i * 2.2, -25, 2.8), Vector3(2.8, 4.0 + sin(i), 2.4), Color("526f69"), true)
	var water := MeadowGeometry.box(self, Vector3(90, point(89, -18).y + 3.1, -22.2), Vector3(2.6, 6.2, 0.14), Color("9de5d6"))
	var material := ShaderMaterial.new()
	material.shader = preload("res://game/world/river.gdshader")
	water.material_override = material
	for i in 7:
		MeadowGeometry.rock(self, point(87 + i * 0.8, -21.6, 0.35), Vector3(0.7, 0.22, 0.55), Color("d0eee0"))
	# A fallen giant and buttress stones create another recognizable side trail.
	var log := MeadowGeometry.box(self, point(61, -12, 1.1), Vector3(8, 1.8, 2), Color("746044"), true)
	log.rotation.y = -0.35
	for i in 5: JungleProps.fern(self, point(58 + i * 1.3, -12, 2.1), 1.2)

func _forest() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8192
	for i in 85:
		var x := rng.randf_range(46, 99)
		var z := rng.randf_range(-29, 35)
		if JungleTerrain.trail_distance(x, z) < 3.5: continue
		if Vector2(x - 77, z + 2).length() < 12 or Vector2(x - 90, z + 20).length() < 13: continue
		JungleProps.palm(self, point(x, z), rng.randf_range(6, 12), rng.randf_range(0, TAU))
		JungleProps.fern(self, point(x + 1, z + 1), rng.randf_range(1.3, 2.5))
		if i % 3 == 0:
			MeadowGeometry.rock(self, point(x - 1, z, 0.3), Vector3(1.2, 0.8, 1), Color("68886c"), true)
		if i % 4 == 0:
			for petal in 4:
				MeadowGeometry.rock(self, point(x + cos(petal * PI / 2) * 0.3, z + 2 + sin(petal * PI / 2) * 0.3, 0.65), Vector3(0.4, 0.18, 0.4), Color("e79979"))
	for z in [18.0, 34.0]:
		JungleProps.palm(self, point(48, z), 13, z)

func _boundaries() -> void:
	for spec in [Vector4(102, 3, 1, 72), Vector4(72, -32, 61, 1), Vector4(72, 39, 61, 1), Vector4(42, -5.5, 1, 53), Vector4(42, 35, 1, 8)]:
		var wall := MeadowGeometry.box(self, Vector3(spec.x, 35, spec.y), Vector3(spec.z, 100, spec.w), Color.WHITE, true)
		wall.visible = false
	for i in 22:
		var x := 46 + i * 2.5
		for z in [-31.0, 38.0]:
			MeadowGeometry.rock(self, point(x, z, 1), Vector3(3, 3 + sin(i), 2.5), Color("517462"))

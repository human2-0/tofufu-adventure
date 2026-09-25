class_name JungleWorld
extends Node3D
## Scenery-only southern jungle beyond the desert's level-eight pass.

const ENTRY_LEVEL: int = 8
const GATE_LAYER: int = 8
var desert: DesertWorld

func _ready() -> void:
	name = "JungleWorld"
	JungleTerrain.build(self, desert)
	_entrance()
	_landmarks()
	_forest()
	_boundaries()

func point(x: float, z: float, lift: float = 0) -> Vector3:
	return Vector3(x, JungleTerrain.height_at(x, z, desert) + lift, z)

func _authored_point(x: float, z: float, lift: float = 0.0) -> Vector3:
	return point(x * 2.0, JungleTerrain.SOUTH_START + (z - 108.0) * 2.0, lift)

func _entrance() -> void:
	var arch := Node3D.new()
	add_child(arch)
	arch.position = _authored_point(0, 109)
	JungleProps.arch(arch, Vector3.ZERO, 10, 7)
	MeadowGeometry.signpost(self, _authored_point(-7, 104), "JADEWILD JUNGLE · LV 8  v")
	var label := Label3D.new()
	label.text = "JADEWILD\nLEVEL 8 · WALK THROUGH"
	label.position = arch.position + Vector3(-1, 8.5, 1)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 48
	label.pixel_size = 0.018
	label.modulate = Color("e3edaa")
	label.no_depth_test = true
	label.render_priority = 127
	add_child(label)
	# Retained as a future progression hook; open by default during world testing.
	var gate := MeadowGeometry.box(self, Vector3(0, 35, JungleTerrain.SOUTH_START), Vector3(20, 100, 2), Color.WHITE, true)
	gate.name = "LevelEightGate"
	gate.visible = false
	(gate.get_child(0) as StaticBody3D).collision_layer = 0

func _landmarks() -> void:
	# Broken sanctuary and its walkable, low steps anchor the inner clearing.
	for i in 4:
		MeadowGeometry.box(self, _authored_point(0, 143, i * 0.24), Vector3(20 - i * 2.8, 0.5, 16 - i * 2), Color("81947b"), true)
	JungleProps.arch(self, _authored_point(0, 141, 0.8), 10, 5)
	for at in [Vector2(-7, 146), Vector2(6, 147), Vector2(-5, 137)]:
		MeadowGeometry.box(self, _authored_point(at.x, at.y, 1.2), Vector3(2.8, 2.4, 2.8), Color("78917a"), true)
		JungleProps.fern(self, _authored_point(at.x, at.y, 2.5), 2.5)
	# Turquoise plunge pool and stepped waterfall rock face, all decorative.
	MeadowGeometry.rock(self, _authored_point(-20, 157, 0.1), Vector3(14, 0.18, 10), Color("58b6b0"))
	for i in 5:
		MeadowGeometry.rock(self, _authored_point(-24 + i * 2.2, 164, 2.8), Vector3(5.6, 4.0 + sin(i), 4.8), Color("526f69"), true)
	var water_at := _authored_point(-20, 157)
	var water := MeadowGeometry.box(self, Vector3(water_at.x, water_at.y + 3.1, water_at.z + 6.4), Vector3(5.2, 6.2, 0.14), Color("9de5d6"))
	var material := ShaderMaterial.new()
	material.shader = preload("res://game/world/river.gdshader")
	water.material_override = material
	for i in 7:
		MeadowGeometry.rock(self, _authored_point(-23 + i * 0.8, 160.6, 0.35), Vector3(1.4, 0.22, 1.1), Color("d0eee0"))
	# A fallen giant and buttress stones create another recognizable side trail.
	var log := MeadowGeometry.box(self, _authored_point(17, 122, 1.1), Vector3(16, 1.8, 4), Color("746044"), true)
	log.rotation.y = -0.35
	for i in 5: JungleProps.fern(self, _authored_point(14 + i * 1.3, 122, 2.1), 2.0)

func _forest() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8192
	for i in 85:
		var x := rng.randf_range(-74, 74)
		var z := rng.randf_range(224, 334)
		if JungleTerrain.trail_distance(x, z) < 3.5: continue
		if Vector2(x, z - 286).length() < 24 or Vector2(x + 40, z - 314).length() < 26: continue
		JungleProps.palm(self, point(x, z), rng.randf_range(6, 12), rng.randf_range(0, TAU))
		JungleProps.fern(self, point(x + 1, z + 1), rng.randf_range(1.3, 2.5))
		if i % 3 == 0:
			MeadowGeometry.rock(self, point(x - 1, z, 0.3), Vector3(1.2, 0.8, 1), Color("68886c"), true)
		if i % 4 == 0:
			for petal in 4:
				MeadowGeometry.rock(self, point(x + cos(petal * PI / 2) * 0.3, z + 2 + sin(petal * PI / 2) * 0.3, 0.65), Vector3(0.4, 0.18, 0.4), Color("e79979"))
	for x in [-68.0, 68.0]:
		JungleProps.palm(self, point(x, 232), 13, x)

func _boundaries() -> void:
	for spec in [Vector4(-81, 278, 1, 126), Vector4(81, 278, 1, 126), Vector4(0, 341, 162, 1)]:
		var wall := MeadowGeometry.box(self, Vector3(spec.x, 35, spec.y), Vector3(spec.z, 100, spec.w), Color.WHITE, true)
		wall.visible = false
	for i in 22:
		var z := 228 + i * 5.0
		for x in [-79.0, 79.0]:
			MeadowGeometry.rock(self, point(x, z, 1), Vector3(2.5, 3 + sin(i), 3), Color("517462"))

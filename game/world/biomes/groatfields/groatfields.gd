class_name Groatfields
extends Node3D
## Southern celestial ruins with open hunting lanes and physical cover.

const START: float = 340.0
const END: float = 480.0
const CAMPS: Array[Vector2] = [Vector2(-30, 375), Vector2(26, 395), Vector2(-28, 432), Vector2(28, 456)]
var jungle: JungleWorld

static func spawns() -> Array[Vector2]:
	var result: Array[Vector2] = []
	for center in CAMPS:
		for offset in [Vector2(-6, -3), Vector2(6, -3), Vector2(0, 7)]: result.append(center + offset)
	return result

func point(x: float, z: float, lift: float = 0) -> Vector3:
	var base := 2.0 + sin(x * 0.05) * 0.7 + cos(z * 0.045) * 0.5
	base = lerpf(base, 2.0, 1.0 - smoothstep(3, 8, absf(x)))
	var height := lerpf(jungle.point(x, START).y, base, smoothstep(START, START + 36, z))
	return Vector3(x, height + lift, z)

func _ready() -> void:
	name = "Groatfields"
	_build_ground()
	GroatfieldRuins.build(self)
	MeadowGeometry.signpost(self, point(-6, 348), "GROATFIELDS · TOFUFU ANGELS\nLEVEL 20 · CELESTIAL SET ADVISED", PI)
	for center in CAMPS:
		for side in [-1, 1]:
			var at := point(center.x + side * 12, center.y)
			MeadowGeometry.box(self, at + Vector3.UP * 1.1, Vector3(2.5, 2.2, 2.5), Color("aaa2c7"), true)
			MeadowGeometry.box(self, at + Vector3.UP * 2.3, Vector3(2.8, 0.3, 2.8), Color("efce83"))
		for i in 5:
			var at := point(center.x - 10 + i * 5, center.y + 13)
			MeadowGeometry.rock(self, at, Vector3(1.1, 0.5, 1.2), Color("d9c4a2"), true)
	for i in 32:
		var side := -1 if i % 2 == 0 else 1
		var at := point(side * (60 + i % 4 * 3), 350 + i * 3.7)
		MeadowGeometry.rock(self, at + Vector3.UP * 1.5, Vector3(3, 4, 3), Color("9a8cad"), true)
	for spec in [Vector4(-81, 410, 1, 140), Vector4(81, 410, 1, 140), Vector4(0, END, 162, 1)]:
		var wall := MeadowGeometry.box(self, Vector3(spec.x, 30, spec.y), Vector3(spec.z, 80, spec.w), Color.WHITE, true)
		wall.visible = false

	StaticDecorationBatch.build(self)

func _build_ground() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(int(START), int(END), 2):
		for x in range(-80, 80, 2):
			for offset in [Vector2(0, 0), Vector2(2, 0), Vector2(0, 2), Vector2(2, 0), Vector2(2, 2), Vector2(0, 2)]:
				var at: Vector2 = Vector2(x, z) + offset
				var color := Color("afa2ba").lerp(Color("d6bf82"), (sin(at.x * 0.13 + at.y * 0.08) + 1) * 0.25)
				color = color.lerp(Color("e8d6ad"), 1 - smoothstep(2, 4, absf(at.x)))
				color = BiomePalette.color_at(at, point(at.x, at.y).y, jungle.desert.farm.noise.seed).lerp(color, smoothstep(START, START + 42, at.y))
				surface.set_color(color.srgb_to_linear())
				surface.set_uv(at / 7.0)
				surface.add_vertex(point(at.x, at.y))
	surface.generate_normals()
	var ground := MeshInstance3D.new()
	ground.mesh = surface.commit()
	var material := StandardMaterial3D.new()
	material.albedo_texture = load("res://assets/environment/groatfields/ground.png")
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.95
	ground.material_override = material
	add_child(ground)
	ground.create_trimesh_collision()
	TerrainSupport.mark_permanent(ground)
	TerrainChunks.split_visual(ground)

class_name DofufuTerrain
extends RefCounted
## Seeded western highlands. Rendering, collision and placement use the same triangles.

const BOUNDS := Rect2(-980, -180, 870, 360)
const STEP: int = 2
const GATE := Vector2(-850, 0)
var noise := FastNoiseLite.new()
var farm: FarmTerrain
var paths: DofufuMountainPaths
var _heights: Dictionary[Vector2i, float] = {}
var _colors: Dictionary[Vector2i, Color] = {}

func _init(source: FarmTerrain) -> void:
	farm = source
	noise.seed = source.noise.seed + 94133
	noise.frequency = 0.009
	noise.fractal_octaves = 3
	paths = DofufuMountainPaths.new(_base_height)

static func contains(at: Vector2) -> bool:
	return at.x <= -110 and at.x >= -980 and absf(at.y) <= 180

static func trail_z(x: float) -> float:
	var d := clampf(-x - 110, 0, 740)
	return sin(d * TAU / 185) * 90 * smoothstep(0, 60, d) * (1 - smoothstep(680, 740, d))

static func trail_distance(at: Vector2) -> float:
	var slope := (trail_z(at.x + 0.25) - trail_z(at.x - 0.25)) * 2
	return absf(at.y - trail_z(at.x)) / sqrt(1 + slope * slope)

func trail_point(x: float) -> Vector3:
	return point(x, trail_z(x))

func point(x: float, z: float, lift: float = 0) -> Vector3:
	var at := Vector2(x, z)
	var cell := Vector2i(floori(x / STEP) * STEP, floori(z / STEP) * STEP)
	var uv := (at - Vector2(cell)) / STEP
	var a := _vertex(cell)
	var b := _vertex(cell + Vector2i(STEP, 0))
	var c := _vertex(cell + Vector2i(0, STEP))
	var h: float
	if uv.x + uv.y <= 1:
		h = a + (b - a) * uv.x + (c - a) * uv.y
	else:
		var d := _vertex(cell + Vector2i(STEP, STEP))
		h = d + (c - d) * (1 - uv.x) + (b - d) * (1 - uv.y)
	return Vector3(x, h + lift, z)

func _vertex(at: Vector2i) -> float:
	if not _heights.has(at): _heights[at] = _raw_height(at.x, at.y)
	return _heights[at]

func _color(at: Vector2i) -> Color:
	if not _colors.has(at):
		var main_mask := 1 - smoothstep(4, 6, trail_distance(Vector2(at)))
		_colors[at] = Color(maxf(main_mask, paths.path_mask(Vector2(at))), 0, 0)
	return _colors[at]

func _raw_height(x: float, z: float) -> float:
	return paths.height_at(Vector2(x, z), _base_height(x, z))

func _base_height(x: float, z: float) -> float:
	var distance := -x - 110
	var ridge := sin(clampf(distance / 740, 0, 1) * PI)
	var h := 11 + ridge * (46 + noise.get_noise_2d(x, z) * 24)
	h += ridge * sin(z * 0.024 + x * 0.009) * 9
	var path_height := 11 + ridge * ridge * 34
	h = lerpf(path_height, h, smoothstep(8, 28, trail_distance(Vector2(x, z))))
	h = lerpf(farm.height_at(-110, z), h, smoothstep(0, 24, distance))
	if x < -850: h = 11 + smoothstep(54, 95, absf(z)) * 13
	return h

func color_at(at: Vector2) -> Color:
	if at.x < -850 and absf(at.y) < 55: return Color("b9a88d")
	if trail_distance(at) < 5 or paths.distance_to(at) < 3: return Color("c3ae86")
	return Color("638365").lerp(Color("92908a"), smoothstep(24, 65, point(at.x, at.y).y))

func build(parent: Node3D) -> void:
	var material := ShaderMaterial.new()
	material.shader = preload("res://game/world/biomes/dofufu/mountain_ground.gdshader")
	material.set_shader_parameter("surfaces", DofufuMountainMaterials.ATLAS)
	# Bounded, separately culled terrain/collision tiles; each vertex is cached once.
	for x in range(-980, -110, 30):
		for z in range(-180, 180, 30):
			_build_tile(parent, x, z, mini(x + 30, -110), z + 30, material)

func _build_tile(parent: Node3D, x0: int, z0: int, x1: int, z1: int, material: Material) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(z0, z1, STEP):
		for x in range(x0, x1, STEP):
			for corner in [Vector2i(0, 0), Vector2i(STEP, 0), Vector2i(0, STEP), Vector2i(STEP, 0), Vector2i(STEP, STEP), Vector2i(0, STEP)]:
				var at: Vector2i = Vector2i(x, z) + corner
				surface.set_color(_color(at))
				surface.add_vertex(Vector3(at.x, _vertex(at), at.y))
	surface.generate_normals()
	surface.index()
	var ground := MeshInstance3D.new()
	ground.name = "Highland_%d_%d" % [x0, z0]
	ground.mesh = surface.commit()
	ground.material_override = material
	parent.add_child(ground)
	ground.create_trimesh_collision()
	TerrainSupport.mark_permanent(ground)

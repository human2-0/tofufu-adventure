class_name FarmTerrain
extends RefCounted
## Seeded rolling ground with authored clearings; mesh and collision share vertices.

var noise := FastNoiseLite.new()
const EXTENT: int = 42

func _init(world_seed: int = 1847) -> void:
	noise.seed = world_seed
	noise.frequency = 0.055
	noise.fractal_octaves = 3

func river_x(z: float) -> float:
	return 11.0 + sin((z - 4.0) * 0.12) * 2.2 * smoothstep(5.0, 14.0, absf(z - 4.0))

func height_at(x: float, z: float) -> float:
	var hills := 1.1 + noise.get_noise_2d(x, z) * 2.2
	hills += 3.0 * exp(-Vector2(x + 24, z + 24).length_squared() / 150.0)
	hills += 2.6 * exp(-Vector2(x - 29, z - 28).length_squared() / 180.0)
	# The nursery, harvest beds and village have graded, accessible foundations.
	var clearing := 1.0 - smoothstep(8.0, 15.0, Vector2(x, z).length())
	clearing = maxf(clearing, 1.0 - smoothstep(5.0, 11.0, Vector2(x + 12, z + 5).length()))
	clearing = maxf(clearing, 1.0 - smoothstep(10.0, 18.0, Vector2(x - 24, z - 2).length()))
	var h := hills * (1.0 - clearing)
	h = lerpf(h, 2.6, 1.0 - smoothstep(4.8, 8.0, Vector2(x + 22, z + 22).length()))
	h = lerpf(h, 0.75, 1.0 - smoothstep(5.0, 7.5, Vector2(x - 32, z - 14).length()))
	h = lerpf(h, 1.0, 1.0 - smoothstep(3.8, 5.8, Vector2(x - 31, z + 14).length()))
	h = lerpf(h, 0.0, 1.0 - smoothstep(4.2, 6.0, Vector2(x - 20, z + 8).length()))
	var stream := absf(x - river_x(z))
	h = lerpf(-0.85, h, smoothstep(2.1, 3.6, stream))
	# A gently graded approach to the main plank bridge.
	var approach := (1.0 - smoothstep(1.3, 3.5, absf(z - 4))) * (1.0 - smoothstep(6.0, 10.0, absf(x - 11)))
	return lerpf(h, minf(h, 0.0), approach)

func point(x: float, z: float, lift: float = 0.0) -> Vector3:
	return Vector3(x, height_at(x, z) + lift, z)

func path_distance(x: float, z: float) -> float:
	var east_lane := Vector2(maxf(0, absf(x - 5.0) - 25.0), z - (4.0 + sin(x * 0.23) * 0.8)).length()
	var nursery_lane := Vector2(x - (1.8 + sin(z * 0.16) * 2.0), maxf(0, absf(z - 3.0) - 18.0)).length()
	var bank_lane := absf(x - (-19.0 + sin(z * 0.13) * 2.0)) if z < 5.0 and z > -24.0 else 99.0
	var village_lane := absf(x - (23.0 + sin(z * 0.17) * 1.5)) if x > 15.0 and z > -15.0 and z < 20.0 else 99.0
	var mayor_lane := Vector2(maxf(0, absf(x - 27) - 4), z - (18 + sin(x * 0.3) * 0.3)).length()
	return minf(mayor_lane, minf(minf(east_lane, nursery_lane), minf(bank_lane, village_lane)))

func is_field(x: float, z: float) -> bool:
	return (x > -16.5 and x < -7.0 and z > -11.0 and z < -1.3) or (x > -6.5 and x < 5.2 and z > -9.5 and z < 1.2) or (x > -17 and x < -5 and z > 12 and z < 23)

func build(parent: Node3D) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(-EXTENT, EXTENT):
		for x in range(-EXTENT, EXTENT):
			for corner in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]:
				var at := point(x + corner.x, z + corner.y)
				surface.add_vertex(at)
	surface.generate_normals()
	var ground := MeshInstance3D.new()
	ground.name = "RollingGround"
	ground.mesh = surface.commit()
	var material := ShaderMaterial.new()
	material.shader = preload("res://game/world/farm_ground.gdshader")
	material.set_shader_parameter("combat_centers", PackedVector2Array(FarmCombatGrounds.CAMPS))
	ground.material_override = material
	parent.add_child(ground)
	ground.create_trimesh_collision()

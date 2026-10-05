class_name VolcanicTerrain
extends RefCounted
## Offshore continent and walkable seabed share the exact rendered collision surface.

const BOUNDS := Rect2(82, 188, 624, 404)
const CENTER := Vector2(450, 380)
const VOLCANO := CENTER
const LANDING := Vector2(235, 318)
const WATER_LEVEL: float = 1.2
const SEED: int = 93741
const LAND_RADIUS := Vector2(221, 174)
const VOLCANO_RADIUS: float = 100.0
const VOLCANO_HEIGHT: float = 136.0

static func contains(at: Vector2) -> bool:
	return BOUNDS.has_point(at)

static func coast_radius(at: Vector2) -> float:
	var local := (at - CENTER) / LAND_RADIUS
	var angle := local.angle()
	return local.length() + sin(angle * 5.0) * 0.035 + sin(angle * 9.0) * 0.018 + sin(angle * 3.0 + 0.7) * 0.028

static func height_at(x: float, z: float) -> float:
	var at := Vector2(x, z)
	var radius := coast_radius(at)
	if radius > 1.12: return -8.0
	var land := lerpf(-8.0, 4.0, 1.0 - smoothstep(0.86, 1.12, radius))
	var noise := WorldContours.noise(at / 18.0, SEED)
	land += noise * 3.8 * (1.0 - smoothstep(0.7, 0.91, radius))
	var cone := at.distance_to(VOLCANO)
	land += maxf(0.0, 1.0 - cone / VOLCANO_RADIUS) * VOLCANO_HEIGHT
	land -= (1.0 - smoothstep(10.0, 20.0, cone)) * (44.0 - cone * 1.36)
	land -= noise * 3.8 * (1.0 - smoothstep(20.0, 28.0, cone))
	var angle := (at - VOLCANO).angle()
	var gullies := sin(angle * 9.0) * 3.5 + cos(angle * 13.0) * 1.6
	land += gullies * sin(clampf(cone / VOLCANO_RADIUS, 0, 1) * PI) * smoothstep(20.0, 35.0, cone)
	# Broad foothills and a sheltered legacy landing, with room for later encounters.
	land += (1.0 - smoothstep(28.0, 65.0, at.distance_to(Vector2(573, 456)))) * 8.0
	land += (1.0 - smoothstep(20.0, 50.0, at.distance_to(Vector2(394, 247)))) * 5.0
	land = lerpf(2.2, land, smoothstep(7.0, 17.0, at.distance_to(LANDING)))
	land = _foundations(at, land)
	if radius > 0.84:
		land = maxf(land, lerpf(2.4, land, smoothstep(2.8, 6.0, VolcanicRoutes.distance(at))))
	if radius < 0.9 and cone > 20.0 and VolcanicLava.river_distance(at) < 2.8: land -= 0.8
	return land

static func _foundations(at: Vector2, land: float) -> float:
	for index in VolcanicLandmarks.SITES.size():
		var site := VolcanicLandmarks.SITES[index]
		var base: float = [4.0, 5.0, 11.0, 4.0, 3.8][index]
		var pad := 20.0 if index == 1 else (17.0 if index == 2 else 12.0)
		land = lerpf(base, land, smoothstep(pad, pad + 8.0, at.distance_to(site)))
	# Castle foundations and a graded beach-to-gate road.
	var castle := at - LavaCastle.CENTER
	var foundation := maxf(absf(castle.x) - 40.0, absf(castle.y) - 59.0)
	land = lerpf(4.0, land, smoothstep(0.0, 8.0, foundation))
	if at.x > 220.0 and at.x < 278.0:
		var road := absf(at.y - 330.0)
		var grade := lerpf(1.9, 4.0, smoothstep(221.0, 264.0, at.x))
		land = lerpf(grade, land, smoothstep(3.0, 7.0, road))
	return land

static func point(at: Vector2, lift: float = 0.0) -> Vector3:
	return Vector3(at.x, height_at(at.x, at.y) + lift, at.y)

static func color_at(at: Vector2, sampled_height: float = INF) -> Color:
	var height := height_at(at.x, at.y) if sampled_height == INF else sampled_height
	if height < WATER_LEVEL + 1.2: return Color("b5a38c")
	if VolcanicLava.river_distance(at) < 6.0: return Color("302932")
	var trail := VolcanicRoutes.distance(at)
	if trail < 3.0 and height > WATER_LEVEL + 0.4:
		return Color("b6a084").lerp(Color("6e5751"), smoothstep(1.8, 3.0, trail))
	if coast_radius(at) > 0.82:
		return Color("c3ad8c").lerp(Color("4c4952"), smoothstep(480.0, 540.0, at.x))
	if at.distance_to(VOLCANO) < 85.0:
		return Color("332e38").lerp(Color("87756b"), sin(height * 0.36) * 0.18 + 0.28)
	var noise := WorldContours.noise(at / 9.0, SEED)
	return Color("302f38").lerp(Color("6e5751"), (noise + 1.0) * 0.5)

static func build(parent: Node3D, grid: VolcanicGroundGrid) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(int(BOUNDS.position.y), int(BOUNDS.end.y), 2):
		for x in range(int(BOUNDS.position.x), int(BOUNDS.end.x), 2):
			for corner in [Vector2.ZERO, Vector2(2, 0), Vector2(0, 2), Vector2(2, 0), Vector2(2, 2), Vector2(0, 2)]:
				var at: Vector2 = Vector2(x, z) + corner
				var index := grid.index(at)
				surface.set_color(grid.colors[index])
				surface.add_vertex(Vector3(at.x, grid.heights[index], at.y))
	surface.generate_normals()
	surface.index()
	var ground := MeshInstance3D.new()
	ground.name = "VolcanicGround"
	ground.mesh = surface.commit()
	var material := ShaderMaterial.new()
	material.shader = preload("res://game/world/biomes/volcanic/volcanic_ground.gdshader")
	ground.material_override = material
	parent.add_child(ground)
	ground.create_trimesh_collision()
	TerrainChunks.split_visual(ground)

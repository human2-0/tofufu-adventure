class_name MapTerrainImage
extends RefCounted
## Cartography follows real heights, coastlines and the same noisy biome palette.

static var _textures: Dictionary[String, Texture2D] = {}

static func build(world: Meadow, bounds: Rect2, density: float) -> Texture2D:
	# Terrain/buildings are authored from the seed; personal fog/markers stay separate.
	var key := "%d:%s:%s" % [world.world_seed, bounds, density]
	if _textures.has(key): return _textures[key]
	var size := Vector2i((bounds.size * density).ceil())
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGB8)
	for y in size.y:
		for x in size.x:
			var at := bounds.position + Vector2(x, y) / density
			image.set_pixel(x, y, _color(world, at))
	for building: Node in world.get_children():
		if not building.has_meta("map_footprint"): continue
		var footprint: Vector2 = building.get_meta("map_footprint")
		var at: Vector3 = building.position
		var corner := (Vector2(at.x, at.z) - footprint * 0.5 - bounds.position) * density
		image.fill_rect(Rect2i(Vector2i(corner), Vector2i(footprint * density)), Color("916d60"))
	if _textures.size() >= 4: _textures.clear()
	var texture := ImageTexture.create_from_image(image)
	_textures[key] = texture
	return texture

static func _color(world: Meadow, at: Vector2) -> Color:
	if VolcanicTerrain.contains(at):
		var height := VolcanicTerrain.height_at(at.x, at.y)
		if height < VolcanicTerrain.WATER_LEVEL: return Color("246c87").lerp(Color("102f4c"), smoothstep(0, 8, -height))
		if VolcanicLava.molten(Vector3(at.x, height, at.y)): return Color("ef6a2c")
		if absf(at.x - LavaCastle.CENTER.x) < 28 and absf(at.y - LavaCastle.CENTER.y) < 28: return Color("a88167")
		for site in VolcanicLandmarks.SITES:
			if at.distance_squared_to(site) < 100: return Color("c3ac8b")
		return VolcanicTerrain.color_at(at, height)
	# Expanded atlas areas outside authored terrain are sea scenery or outer void.
	if at.x > 200: return Color("163b52") if at.y >= 56 else Color("233e49")
	if at.y > 340: return Color("233e49")
	var seed := world.terrain.noise.seed
	var height := world.ground_point(at.x, at.y).y
	var color := BiomePalette.color_at(at, height, seed)
	if at.y >= JungleTerrain.SOUTH_START and at.y <= JungleTerrain.SOUTH_END and at.x >= 53 and at.x <= JungleCoast.SEA_EDGE:
		color = JungleCoast.color_at(at, height, color)
		if height < JungleCoast.WATER_LEVEL: return Color("246c87").lerp(Color("102f4c"), smoothstep(0, 8, -height))
		return color
	if at.y <= -84 and at.y >= -220 and height < OceanTerrain.WATER_LEVEL:
		var depth := OceanTerrain.WATER_LEVEL - height
		color = Color("83c9be").lerp(Color("245f7b"), smoothstep(0, 7, depth))
	color = color.lerp(Color("233e49"), _outer_ridge(at, seed))
	if at.y > -65 and at.y < 65 and world.terrain.path_distance(at.x, at.y) < 1.1: color = Color("dfcb9b")
	if world.terrain.is_field(at.x, at.y): color = Color("9eae72")
	if at.x > 84 and at.x < 184 and at.y > -44 and at.y < 56:
		color = Color("899b92") if absf(at.y - 6) > 4 else Color("dfcb9b")
	if RiverCourse.bank_distance(at.x, at.y) < 0: color = Color("6faab5")
	if at.x > 7 and at.x < 15.4 and absf(at.y - 4) < 1.4: color = Color("b38c62")
	return color

static func _outer_ridge(at: Vector2, seed: int) -> float:
	# Shade inaccessible outer ridges, with the same seeded scallops as the ground.
	var width := lerpf(110.0, 140.0, smoothstep(84.0, 109.0, -at.y))
	width = lerpf(width, 80.0, smoothstep(57.0, 84.0, at.y))
	var side := -1.0 if at.x < 0 else 1.0
	var edge := WorldContours.edge_x(at.y, width, seed, side)
	var distance := absf(at.x) - edge
	var cap_offset := WorldContours.coast(at.x, seed) * 0.35
	if at.y < -330: distance = maxf(distance, -at.y - (359.0 + cap_offset))
	elif at.y > 310: distance = maxf(distance, at.y - (331.0 + cap_offset))
	return smoothstep(-4.0, 2.5, distance)

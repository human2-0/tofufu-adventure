class_name Meadow
extends Node3D
## Fufufarm composition: seeded terrain, countryside scenery and the Polish farmstead.

const TREE: PackedScene = preload("res://game/world/common/tree.tscn")
const APPLE_TREE_COUNT: int = 20
@export var world_seed: int = 1847
@export var ocean_access_open: bool = true
var weapon_merchant: Node3D
var quest_npc: Node3D
var seed_bank: Node3D
var tofu_factory: TofuFactory
var duel_arena: FarmDuelArena
var map_npcs: Dictionary[String, Node3D] = {}
var ocean: OceanWorld
var frost: FrostWorld
var desert: DesertWorld
var jungle: JungleWorld
var volcanic: VolcanicWorld
var cloud_realm: CloudRealm
var terrain: FarmTerrain
var rain_effects: RainGroundEffects
var grass_material: ShaderMaterial
var grass_imprint: GrassImprint
var interiors: Array[Node3D] = []
var produce: Array[MeadowProduce] = []
var apple_trees: Array[AppleTree] = []
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.seed = world_seed
	terrain = FarmTerrain.new(world_seed)
	terrain.build(self)
	_river_and_bridge()
	_farmstead()
	_village()
	duel_arena = FarmDuelArena.new()
	duel_arena.name = "DuelArena"
	add_child(duel_arena)
	duel_arena.build(ground_point)
	Gigalopolis.build(self)
	tofu_factory = TofuFactory.new()
	add_child(tofu_factory)
	map_npcs["Gigalopolis · Tofu Factory"] = tofu_factory.entrance_marker
	FarmCombatGrounds.build(self, terrain)
	_countryside()
	_place_apple_trees()
	grass_material = FarmFoliage.populate(self, terrain, _rng)
	grass_imprint = GrassImprint.new()
	grass_imprint.bind(grass_material)
	rain_effects = RainGroundEffects.new()
	rain_effects.terrain = terrain
	add_child(rain_effects)
	ocean = OceanWorld.new()
	ocean.farm = terrain
	ocean.access_open = ocean_access_open
	add_child(ocean)
	map_npcs["Tideglass Atoll"] = ocean.atoll_marker
	frost = FrostWorld.new()
	frost.ocean = ocean
	add_child(frost)
	desert = DesertWorld.new()
	desert.farm = terrain
	add_child(desert)
	jungle = JungleWorld.new()
	jungle.desert = desert
	add_child(jungle)
	volcanic = VolcanicWorld.new()
	add_child(volcanic)
	map_npcs["Embercrown · Tofufu Castle"] = volcanic.castle
	map_npcs["Tofufu King Lava · Royal Plaza"] = volcanic.castle.king
	for site: Node in volcanic.get_children():
		if site.has_meta("map_title"): map_npcs[str(site.get_meta("map_title"))] = site
	cloud_realm = CloudRealm.new()
	add_child(cloud_realm)
	map_npcs["Cloud Realm · Godfufu (above jungle)"] = cloud_realm.godfufu
	map_npcs["Nimbus · Cloud Royal Gear Shop"] = cloud_realm.court.merchant
	map_npcs["Tofufu Goddess · Cloud Court"] = cloud_realm.court.goddess
	RiverPlants.populate(self, ground_point)
	add_child(RiverWildlife.new())
	StaticDecorationBatch.build(self)

func ground_point(x: float, z: float, lift: float = 0.0) -> Vector3:
	if volcanic != null and VolcanicTerrain.contains(Vector2(x, z)): return volcanic.point(x, z, lift)
	if x > 84 and z > -44 and z < 56: return Vector3(x, lift, z)
	if z <= FrostTerrain.NORTH_START and frost != null: return frost.point(x, z, lift)
	if z <= OceanTerrain.NORTH_START and ocean != null: return ocean.point(x, z, lift)
	if z >= JungleTerrain.SOUTH_START and jungle != null: return jungle.point(x, z, lift)
	if z >= DesertTerrain.SOUTH_START and desert != null: return desert.point(x, z, lift)
	return terrain.point(x, z, lift)

func is_water(at: Vector3) -> bool:
	if at.y >= CloudTerrain.ALTITUDE - 2.0 and CloudTerrain.contains(Vector2(at.x, at.z)): return false
	if jungle != null and JungleCoast.is_water(at, jungle.desert): return true
	if volcanic != null and volcanic.is_water(at): return true
	if ocean != null and ocean.is_water(at): return true
	if desert != null and desert.is_water(at): return true
	return RiverCourse.contains(at)

func _river_and_bridge() -> void:
	add_child(RiverSurface.new())
	for i in 19:
		MeadowGeometry.box(self, Vector3(7.04 + i * 0.44, -0.055, 4), Vector3(0.42, 0.15, 2.8), Color("be9868"), true)
	for side in [-1.0, 1.0]:
		for x in [7.0, 9.0, 11.0, 13.0, 15.0]:
			MeadowGeometry.box(self, Vector3(x, 0.5, 4 + side * 1.4), Vector3(0.17, 1.0, 0.17), Color("8b6c4e"), true)
		MeadowGeometry.box(self, Vector3(11, 0.85, 4 + side * 1.4), Vector3(8.3, 0.12, 0.12), Color("d7b383"), true)
	for i in 70:
		var z := _rng.randf_range(-40, 40)
		if absf(z - 4) < 3.0:
			continue
		var x := terrain.river_x(z) + (-1.0 if i % 2 == 0 else 1.0) * _rng.randf_range(2.9, 3.5)
		MeadowGeometry.rock(self, ground_point(x, z), Vector3(0.4, 0.25, 0.3), Color("9eac89"), true)
	MeadowGeometry.signpost(self, ground_point(5.5, 6.5), "VILLAGE  >")

func _farmstead() -> void:
	MeadowGeometry.signpost(self, ground_point(-4.8, 1.7), "FUFUFARM · NURSERY")

func _village() -> void:
	MeadowVillage.build(self)

func _countryside() -> void:
	for i in 85:
		var x := _rng.randf_range(-81, 81)
		var z := _rng.randf_range(-81, 81)
		if z > 68 or z < -68: continue
		if terrain.path_distance(x, z) < 3.2 or terrain.is_field(x, z) or absf(x - terrain.river_x(z)) < 4.5:
			continue
		if FarmCombatGrounds.is_clearing(x, z):
			continue
		if Vector2(x, z).length() < 12 or MeadowVillage.BOUNDS.grow(3).has_point(Vector2(x, z)) or Vector2(x + 22, z + 22).length() < 7:
			continue
		var tree := TREE.instantiate() as Node3D
		tree.position = ground_point(x, z)
		tree.scale = Vector3.ONE * _rng.randf_range(0.85, 1.6)
		add_child(tree)
	# Uneven wooded hills hide the traversal edge and frame the farm valley.
	for i in 42:
		var angle := i * TAU / 42.0
		var radius := 94.0 + sin(angle * 3.0) * 6.0 + _rng.randf_range(-2, 6)
		var x := cos(angle) * radius
		var z := sin(angle) * radius
		if z > 70 or z < -70 or (x > 70 and absf(z - 6) < 12): continue
		var hill_height := _rng.randf_range(3.0, 6.5)
		for center in FarmCombatGrounds.CAMPS:
			if Vector2(x, z).distance_to(center) < 17.0:
				hill_height = 1.0
		MeadowGeometry.rock(self, ground_point(x, z, 0.5), Vector3(5, hill_height, 5), Color("88a17a").lerp(Color("b6be8d"), _rng.randf_range(0, 0.6)))
	# The east side continues into Gigalopolis and the north/south sides continue into
	# the biome chain. Keep only the true western map edge; the old x=80 walls blocked
	# the factory road and made walkable terrain look like invisible dead ends.
	var western_edge := MeadowGeometry.box(self, Vector3(-110, 6, 0), Vector3(0.8, 12, 168), Color.WHITE, true)
	western_edge.visible = false

func _place_apple_trees() -> void:
	var orchard_rng := RandomNumberGenerator.new()
	orchard_rng.seed = world_seed + 73091
	var locations: Array[Vector2] = []
	for attempt in 1200:
		if locations.size() >= APPLE_TREE_COUNT: break
		var at := Vector2(orchard_rng.randf_range(-76, 76), orchard_rng.randf_range(-64, 64))
		if at.length() < 16.0 or at.distance_to(Vector2(-22, -22)) < 9.0: continue
		if MeadowVillage.BOUNDS.grow(4).has_point(at) or terrain.is_field(at.x, at.y): continue
		if terrain.path_distance(at.x, at.y) < 5.0 or absf(at.x - terrain.river_x(at.y)) < 7.0: continue
		if FarmCombatGrounds.is_clearing(at.x, at.y): continue
		var crowded := false
		for placed in locations:
			if at.distance_to(placed) < 8.0:
				crowded = true
				break
		if crowded: continue
		locations.append(at)
	for at in locations:
		var tree := AppleTree.new()
		tree.position = ground_point(at.x, at.y)
		tree.rotation.y = orchard_rng.randf_range(0, TAU)
		tree.scale = Vector3.ONE * orchard_rng.randf_range(0.9, 1.15)
		add_child(tree)
		apple_trees.append(tree)

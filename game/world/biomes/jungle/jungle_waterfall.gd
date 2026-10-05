class_name JungleWaterfall
extends Node3D
## Walkable rainforest sanctuary; all water and wildlife remain cosmetic.

const CENTER := Vector2(-40, 314)
const WATER_Y: float = 1.65
var spray: WaterfallSpray
var wildlife: RainforestWildlife
var audio: RainforestAudio
var pool: MeshInstance3D
var jungle: JungleWorld

func _ready() -> void:
	name = "WaterfallSanctuary"
	position = Vector3(CENTER.x, WATER_Y, CENTER.y)
	# The normal follow camera approaches from +Z; keep the falling face visible.
	rotation.y = PI
	_build_water()
	_build_banks()
	RainforestGarden.build(self)
	spray = WaterfallSpray.new()
	add_child(spray)
	wildlife = RainforestWildlife.new()
	add_child(wildlife)
	audio = RainforestAudio.new()
	add_child(audio)

func present(delta: float, focus: Vector3, daylight: float, rain: bool, outdoor: bool) -> void:
	var nearby := global_position.distance_squared_to(focus) < 8100.0 and outdoor
	spray.active = nearby
	wildlife.observer = to_local(focus)
	wildlife.active = nearby
	wildlife.daylight = daylight
	wildlife.raining = rain
	audio.present(delta, nearby, daylight, rain, wildlife)

func ground_height(at: Vector3) -> float:
	var world_at := to_global(at)
	return to_local(jungle.point(world_at.x, world_at.z)).y

func _build_water() -> void:
	var material := ShaderMaterial.new()
	material.shader = preload("res://game/world/biomes/jungle/waterfall.gdshader")
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Radial tessellation gives the pool a softly waving, irregular shoreline.
	for ring in 12:
		for segment in 96:
			for corner in [Vector2(0,0), Vector2(1,0), Vector2(0,1), Vector2(1,0), Vector2(1,1), Vector2(0,1)]:
				var angle: float = (segment + corner.y) * TAU / 96.0
				var radius: float = (ring + corner.x) / 12.0
				var edge := 1.0 + sin(angle * 7.0) * 0.025
				surface.add_vertex(Vector3(cos(angle) * 14 * radius * edge, 0, sin(angle) * 10 * radius * edge))
	surface.generate_normals()
	pool = MeshInstance3D.new()
	pool.name = "PlungePool"
	pool.mesh = surface.commit()
	pool.material_override = material
	pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(pool)
	for layer in 3:
		var water := ShaderMaterial.new()
		water.shader = material.shader
		water.set_shader_parameter("cascade", true)
		var sheet := SurfaceTool.new()
		sheet.begin(Mesh.PRIMITIVE_TRIANGLES)
		for row in 32:
			for column in 16:
				for corner in [Vector2(0,0), Vector2(1,0), Vector2(0,1), Vector2(1,0), Vector2(1,1), Vector2(0,1)]:
					var v: float = (row + corner.y) / 32.0
					var u: float = (column + corner.x) / 16.0
					var width := 5.6 + pow(1.0 - v, 3.0) * 2.0
					sheet.add_vertex(Vector3((u - 0.5) * width, v * (10.5 + layer * 0.15), 6.2 + v * 1.4 + layer * 0.10 + sin(u * 19.0) * 0.07))
		sheet.generate_normals()
		var curtain := MeshInstance3D.new()
		curtain.name = "Cascade%d" % layer
		curtain.mesh = sheet.commit()
		curtain.material_override = water
		curtain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(curtain)
	var source := PlaneMesh.new()
	source.size = Vector2(5.6, 3.6)
	source.subdivide_width = 16
	source.subdivide_depth = 8
	var headwater := MeshInstance3D.new()
	headwater.mesh = source
	headwater.material_override = material
	headwater.position = Vector3(0, 10.5, 9.3)
	add_child(headwater)

func _build_banks() -> void:
	for i in 13:
		var x := -12.0 + i * 2.0
		var high := 6.4 + cos(x * 0.2) * 1.0
		RainforestGarden.wet_rock(self, Vector3(x, high - 2.0, 11.5 + sin(i * 1.7) * 0.45), Vector3(3.2, high, 3.4))
		MeadowGeometry.rock(self, Vector3(x, high * 1.7 - 2.1, 10.9), Vector3(3.0, 0.7, 2.5), Color("699267"))
		JungleProps.fern(self, Vector3(x, high * 1.7 - 1.5, 11.1), 1.8)
	# Dark wet ledges show through the fringes of the falling sheet.
	for side in [-1.0, 1.0]:
		MeadowGeometry.rock(self, Vector3(side * 4.0, 4.6, 8.3), Vector3(1.8, 4.8, 1.5), Color("355752"), true)
		for i in 6:
			var at := Vector3(side * (5.5 + i * 1.3), 0, 6.8 - i * 1.7)
			at.y = ground_height(at)
			MeadowGeometry.rock(self, at + Vector3.UP * 0.25, Vector3(1.1, 0.55, 0.9), Color("749577"))
			JungleProps.fern(self, at + Vector3(side * 1.5, 0.1, 0), 1.6)
	# Perches grow from the dry banks; frogs rest on wet stepping stones.
	var branches := SurfaceTool.new()
	branches.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 6:
		var side := -1.0 if i % 2 else 1.0
		var perch := Vector3(side * (10.0 + i), 5.5 + i * 0.55, 4.0 + i * 0.3)
		TreeBranchMesh.add_segment(branches, Vector3(side * 17, 4.0, 6), perch - Vector3.UP * 0.22, 0.20, 0.065)
		if i < 2:
			JungleProps.palm(self, Vector3(side * 17, 0.5, 6), 8.5, i * 1.2)
	branches.generate_normals()
	var boughs := MeshInstance3D.new()
	boughs.mesh = branches.commit()
	var bark := MeadowGeometry.material(Color.WHITE)
	bark.vertex_color_use_as_albedo = true
	boughs.material_override = bark
	add_child(boughs)
	for i in 5:
		MeadowGeometry.rock(self, Vector3(-6.5 - i * 1.2, -0.25, 4.5 - i * 1.7), Vector3(0.65, 0.33, 0.60), Color("648a78"))
	for i in 18:
		var angle := i * 2.39996
		var at := Vector3(cos(angle) * 16.5, 0, sin(angle) * 12.5)
		at.y = ground_height(at)
		if at.z > 7.5: continue
		JungleProps.fern(self, at, 1.1 + (i % 3) * 0.4)
		for petal in 3:
			MeadowGeometry.rock(self, at + Vector3(0.12 * petal, 0.7, 0), Vector3(0.16, 0.35, 0.16), Color("f7a468") if i % 2 else Color("df88b4"))

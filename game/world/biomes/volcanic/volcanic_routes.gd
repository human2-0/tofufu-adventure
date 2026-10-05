class_name VolcanicRoutes
extends RefCounted
## The ash circuit connects distinct future gameplay areas and bridges every lava cut.

const CIRCUIT: Array[Vector2] = [Vector2(632, 380), Vector2(628, 405), Vector2(620, 444), Vector2(578, 490), Vector2(516, 500), Vector2(450, 504), Vector2(380, 497), Vector2(336, 477), Vector2(300, 440), Vector2(270, 407), Vector2(262, 375), Vector2(261, 335), Vector2(271, 290), Vector2(293, 265), Vector2(399, 255), Vector2(450, 256), Vector2(510, 262), Vector2(562, 279), Vector2(602, 307), Vector2(632, 380)]
const BRANCHES: Array[Array] = [
	[Vector2(235, 318), Vector2(247, 330), Vector2(270, 330), Vector2(274, 400), Vector2(316, 400), Vector2(316, 380)],
	[Vector2(316, 400), Vector2(351, 462), Vector2(400, 490), Vector2(435, 515)],
	[Vector2(450, 256), Vector2(448, 234)],
	[Vector2(618, 332), Vector2(585, 324)],
	[Vector2(620, 444), Vector2(592, 456), Vector2(573, 456)],
	[Vector2(632, 380), Vector2(635, 395)]]

static func distance(at: Vector2) -> float:
	var best := INF
	for i in range(1, CIRCUIT.size()):
		best = minf(best, at.distance_to(Geometry2D.get_closest_point_to_segment(at, CIRCUIT[i - 1], CIRCUIT[i])))
	for route in BRANCHES:
		for i in range(1, route.size()):
			best = minf(best, at.distance_to(Geometry2D.get_closest_point_to_segment(at, route[i - 1], route[i])))
	return best

static func crossings() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var routes: Array[Array] = [CIRCUIT]
	routes.append_array(BRANCHES)
	for route in routes:
		for i in range(1, route.size()):
			for river in VolcanicLava.RIVERS:
				for j in range(1, river.size()):
					var hit: Variant = Geometry2D.segment_intersects_segment(route[i - 1], route[i], river[j - 1], river[j])
					if hit == null: continue
					result.append({"at": hit, "direction": (route[i] - route[i - 1]).normalized()})
	return result

static func build(parent: Node3D) -> void:
	for crossing in crossings(): _bridge(parent, crossing.at, crossing.direction)
	var titles: Array[String] = ["EMBERCROWN\nCASTLE → ASH CIRCUIT", "ROYAL ROAD\nKING LAVA → SOUTH GATE", "CINDER HARBOR\n← CASTLE   THERMAL GARDENS →", "SULFUR GARDENS\nASH CIRCUIT →", "OBSIDIAN SANCTUARY\n← SOUTH BEACH", "TIDEGLASS COVE\n← ASH CIRCUIT"]
	for i in BRANCHES.size():
		var at: Vector2 = BRANCHES[i][-1] + Vector2(7, 7)
		MeadowGeometry.signpost(parent, VolcanicTerrain.point(at), titles[i])
	var ring := CIRCUIT
	for i in range(0, ring.size() - 1, 2):
		var at := ring[i] + (ring[i] - VolcanicTerrain.CENTER).normalized() * 6.0
		var foot := VolcanicTerrain.point(at)
		MeadowGeometry.box(parent, foot + Vector3.UP * 0.6, Vector3(0.55, 1.2, 0.55), Color("574d51"))
		var cap := MeadowGeometry.box(parent, foot + Vector3.UP * 1.25, Vector3(0.7, 0.15, 0.7), Color("ffbb69"))
		var material := cap.mesh.material as StandardMaterial3D
		material.emission_enabled = true
		material.emission = Color("ff9146")
		material.emission_energy_multiplier = 1.5

static func _bridge(parent: Node3D, at: Vector2, direction: Vector2) -> void:
	var bridge := Node3D.new()
	bridge.name = "AshCircuitBridge"
	var height := -INF
	for i in range(-11, 12):
		height = maxf(height, VolcanicTerrain.point(at + direction * i).y)
	bridge.position = Vector3(at.x, height + 1.0, at.y)
	parent.add_child(bridge)
	bridge.look_at(bridge.position + Vector3(direction.x, 0, direction.y), Vector3.UP)
	MeadowGeometry.box(bridge, Vector3.ZERO, Vector3(7, 0.35, 22), Color("98877a"), true)
	for side in [-1.0, 1.0]:
		MeadowGeometry.box(bridge, Vector3(side * 3.35, 0.8, 0), Vector3(0.3, 1.6, 22), Color("574b50"), true)
		for z in [-7.0, 0.0, 7.0]:
			MeadowGeometry.box(bridge, Vector3(side * 3.2, -1.6, z), Vector3(0.9, 3, 0.9), Color("3d3540"))
	# Long ramps match the actual terrain at both approaches, without a jump lip.
	for side in [-1.0, 1.0]:
		var ground := VolcanicTerrain.point(at + direction * side * 23, -0.22)
		var deck: Vector3 = bridge.position + Vector3.UP * 0.025 + Vector3(direction.x, 0, direction.y) * side * 11
		var ramp := MeadowGeometry.box(parent, (ground + deck) * 0.5, Vector3(7, 0.3, ground.distance_to(deck) + 0.3), Color("8b7a6d"), true)
		ramp.name = "AshCircuitApproach"
		ramp.look_at(deck, Vector3.UP)

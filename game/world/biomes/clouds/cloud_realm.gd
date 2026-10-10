class_name CloudRealm
extends Node3D
## Permanent floating terrain above Jadewild, reached by flying a parrot.

var godfufu := Godfufu.new()
var court := CloudCourt.new()
var motes: Array[MeshInstance3D] = []
var elapsed: float = 0.0

func _ready() -> void:
	name = "CloudRealm"
	CloudTerrain.build(self)
	_cloud_banks()
	_cloud_garden()
	CloudKingdom.build(self)
	StaticDecorationBatch.build(self)
	add_child(CloudMist.new())
	add_child(court)
	godfufu.position = CloudTerrain.point(-8, 270)
	add_child(godfufu)
	MeadowGeometry.signpost(self, CloudTerrain.point(-12, 251), "CLOUD REALM · GODFUFU ↑")
	MeadowGeometry.signpost(self, CloudTerrain.point(-4, 245), "PARROT LANDING · RETURN FLIGHT")

func point(x: float, z: float, lift: float = 0.0) -> Vector3:
	return CloudTerrain.point(x, z, lift)

func _cloud_banks() -> void:
	for island in CloudTerrain.ISLANDS:
		var center := CloudTerrain.CENTER + Vector2(island.x, island.y)
		# The puffy skirts remain below the real floor, keeping landings readable.
		for i in 18:
			var angle := i * TAU / 18.0
			var at := center + Vector2(cos(angle), sin(angle)) * (island.z - 1.5)
			_puff(point(at.x, at.y, -3.0), Vector3(3.8, 2.6, 3.8), Color("eee8ff").lerp(Color("d3eaf9"), (sin(i * 1.7) + 1.0) * 0.5))
			for side in [-1, 1]:
				var lobe: Vector2 = at + Vector2(-sin(angle), cos(angle)) * side * 2.4
				_puff(point(lobe.x, lobe.y, -3.6), Vector3(2.6, 1.8, 2.6), Color("eeeafa"))
		_puff(point(center.x, center.y, -4.2), Vector3(island.z * 0.8, 4, island.z * 0.8), Color("b8bde9"))
	for i in 12:
		var at := CloudTerrain.CENTER + Vector2(cos(i * 2.1) * 47, sin(i * 2.1) * 38)
		_puff(point(at.x, at.y, -9 - i % 3 * 3), Vector3(4.0, 1.0, 2.5), Color("e9e6fc"))

func _cloud_garden() -> void:
	for at in [Vector2(-30, 277), Vector2(17, 272), Vector2(4, 297), Vector2(-18, 266)]:
		var base := point(at.x, at.y)
		var stem := MeadowGeometry.box(self, base + Vector3.UP * 1.4, Vector3(0.3, 2.8, 0.3), Color("bdaddc"), true)
		stem.rotation.z = 0.15
		for i in 5:
			_puff(base + Vector3(cos(i * 2.4), 3.0 + i * 0.25, sin(i * 2.4)) * Vector3(1.4, 1, 1.4), Vector3(1.7, 0.85, 1.5), Color("f9d5e5").lerp(Color("e4dcff"), i / 5.0))
	for i in 18:
		var at := CloudTerrain.CENTER + Vector2(cos(i * 2.4), sin(i * 2.4)) * (7.0 + i % 3 * 3.0)
		var mote := MeadowGeometry.box(self, point(at.x, at.y, 2.0 + i % 3), Vector3(0.15, 0.15, 0.15), Color("fff0b0"))
		mote.name = "CelestialMote_%d" % i
		mote.set_meta("idle_y", mote.position.y)
		motes.append(mote)
	var ring := TorusMesh.new()
	ring.inner_radius = 4.0
	ring.outer_radius = 4.15
	ring.material = MeadowGeometry.material(Color("f2cd83"))
	var halo := MeshInstance3D.new()
	halo.mesh = ring
	halo.position = point(-8, 270, 0.025)
	add_child(halo)

func _puff(at: Vector3, size: Vector3, color: Color) -> void:
	var mesh := SphereMesh.new()
	mesh.radial_segments = 16
	mesh.rings = 8
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.material = CloudMaterials.cloud(color.lightened(0.35))
	var puff := MeshInstance3D.new()
	puff.mesh = mesh
	puff.position = at
	puff.scale = size
	add_child(puff)

func _process(delta: float) -> void:
	elapsed += delta
	for i in motes.size():
		motes[i].position.y = float(motes[i].get_meta("idle_y")) + sin(elapsed * 1.3 + i) * 0.5
		motes[i].rotation = Vector3(elapsed * 0.4, elapsed * 0.6 + i, PI * 0.25)

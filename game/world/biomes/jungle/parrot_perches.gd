class_name ParrotPerches
extends Node3D
## Authored outdoor landing clearings and their colorful transport birds.

const TITLES: Array[String] = ["Jadewild Jungle", "Fufufarm Village", "Sunsand Desert", "Northern Shore", "Frostcrown Reach", "Gigalopolis", "Cloud Realm · Godfufu", "Embercrown Beach"]
const POINTS: Array[Vector2] = [Vector2(-8, 236), Vector2(20, 8), Vector2(0, 118), Vector2(0, -76), Vector2(0, -250), Vector2(96, 6), CloudTerrain.LANDING, VolcanicTerrain.LANDING]
var ground_point: Callable
var stations: Array[Node3D] = []
var birds: Array[ParrotArt] = []
var labels: Array[Label3D] = []

func _ready() -> void:
	name = "ParrotPerches"
	for i in POINTS.size():
		var station := Node3D.new()
		station.position = ground_point.call(POINTS[i].x, POINTS[i].y, 0.05)
		if POINTS[i] == CloudTerrain.LANDING: station.position = CloudTerrain.point(POINTS[i].x, POINTS[i].y, 0.05)
		add_child(station)
		stations.append(station)
		var pad := CylinderMesh.new()
		pad.top_radius = 2.3
		pad.bottom_radius = 2.3
		pad.height = 0.035
		pad.material = MeadowGeometry.material(Color("e4c783"))
		var marker := MeshInstance3D.new()
		marker.mesh = pad
		station.add_child(marker)
		var bird := ParrotArt.new()
		station.add_child(bird)
		birds.append(bird)
		var label := Label3D.new()
		label.text = "PARROT FLIGHTS\n" + TITLES[i]
		label.position.y = 2.55
		label.font_size = 32
		label.pixel_size = 0.014
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		if POINTS[i] == VolcanicTerrain.LANDING:
			label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
			label.double_sided = false
		label.modulate = Color("fff0c2")
		station.add_child(label)
		labels.append(label)
	MeadowGeometry.signpost(self, ground_point.call(-12, 239), "CLOUD REALM ↑ · PARROT ONLY\nRISE ABOVE THE JUNGLE", PI)

func nearest(at: Vector3) -> int:
	for i in stations.size():
		if at.distance_to(stations[i].global_position) <= 4.5: return i
	return -1

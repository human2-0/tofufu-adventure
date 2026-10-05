class_name LavaCastle
extends Node3D
## Three long maze decks culminate in the elevated royal plaza, with physical stairs.

const CENTER := Vector2(316, 334)
const BASE_HEIGHT: float = 4.4
var floors: Array[CastleMazeFloor] = []
var stairways: Array[Node3D] = []
var facade: Node3D
var plaza: Node3D
var king: LavaKing
var _view_state: int = -2

func _ready() -> void:
	name = "TofufuCastle"
	position = Vector3(CENTER.x, BASE_HEIGHT, CENTER.y)
	for deck in 3:
		var floor_node := CastleMazeFloor.new()
		floor_node.floor_index = deck
		floor_node.position.y = deck * 8.0
		add_child(floor_node)
		floors.append(floor_node)
		stairways.append(CastleStairways.build(self, deck))
	facade = CastleExterior.build(self)
	plaza = CastleRoyalPlaza.build(self)
	king = LavaKing.new()
	king.position = Vector3(0, 24.0, 15)
	add_child(king)
	_entry_bridge()

func _entry_bridge() -> void:
	CastleGeometry.solid(self, Vector3(0, -0.15, 36), Vector3(5.6, 0.3, 20), Color("9d8065"))
	CastleGeometry.solid(self, Vector3(0, -0.3, 47.5), Vector3(5.6, 0.2, 3.2), Color("9d8065"), atan2(0.4, 3.0))
	for side in [-1.0, 1.0]:
		CastleGeometry.solid(self, Vector3(side * 2.9, 0.75, 37), Vector3(0.35, 1.5, 18), Color("675155"))
	MeadowGeometry.signpost(self, Vector3(-5, 0, 47), "TOFUFU CASTLE\nTHREE MAZES → KING'S PLAZA")

func contains(at: Vector3) -> bool:
	var local := to_local(at)
	return absf(local.x) < 31.0 and absf(local.z) < 59.0 and local.y > -1.0 and local.y < 34.0

func present(at: Vector3, overhead: bool) -> void:
	var local := to_local(at)
	var inside := contains(at) and overhead
	var deck := clampi(floori((local.y + 0.1) / 8.0), 0, 3)
	var state := deck if inside else -1
	if state == _view_state: return
	_view_state = state
	facade.visible = not inside
	plaza.visible = not inside or deck == 3
	king.visible = not inside or deck == 3
	for i in floors.size():
		floors[i].visible = not inside or i <= deck
		floors[i].present(inside and i == deck)
		stairways[i].visible = not inside or i <= deck

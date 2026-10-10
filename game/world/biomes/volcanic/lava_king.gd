class_name LavaKing
extends Node3D
## Illustrated elderly tofu master; app composition supplies local visitor position.

var sprite := LavaKingArt.new()
var greeting: Label3D
var greeting_enabled: bool = true
var elapsed: float = 0.0

func _ready() -> void:
	name = "TofufuKingLava"
	add_child(sprite)
	CastleGeometry.solid(self, Vector3(0, 1.2, 0), Vector3(1.2, 2.4, 0.9), Color("4d3038")).visible = false
	greeting = CastleGeometry.title(self, Vector3(0, 5.4, 0.6), "You have found your way, young Fufu.\nEven fire must learn patience.\nWelcome to my royal plaza.", 26)
	greeting.visible = false

func _process(delta: float) -> void:
	elapsed += delta
	sprite.position.y = sin(elapsed * 1.4) * 0.045

class_name Godfufu
extends Node3D
## Tofu-block king of the clouds, with a gentle idle and local greeting.

const ART: Texture2D = preload("res://assets/characters/cloud_court/godfufu-directions.png")
var sprite := CloudResidentArt.new()
var greeting: Label3D
var elapsed: float = 0.0

func _ready() -> void:
	name = "Godfufu"
	sprite.asset = "godfufu"
	sprite.height = 2.65
	add_child(sprite)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.55
	capsule.height = 1.8
	collider.shape = capsule
	collider.position.y = 0.9
	body.add_child(collider)
	add_child(body)
	_label("GODFUFU\nKing of the Cloud Realm", Vector3(0, 3.2, 0), Color("fff0b4"), 32)
	greeting = _label("Welcome, little Fufu.\nMy guardians keep the paths safe.\nVisit Nimbus for equipment,\nthen rest in our blossom gardens.", Vector3(0, 4.5, 0), Color("fff9e8"), 25)
	greeting.visible = false
	MeadowGeometry.rock(self, Vector3(0, 0.025, 0), Vector3(0.9, 0.025, 0.65), Color("b4abd6"))

func _process(delta: float) -> void:
	elapsed += delta
	sprite.position.y = sin(elapsed * 1.6) * 0.07

func _label(text: String, at: Vector3, color: Color, font_size: int) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = color
	label.font_size = font_size
	label.pixel_size = 0.012
	add_child(label)
	return label

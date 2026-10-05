class_name Godfufu
extends Node3D
## Placeholder resident: a tofu-block sprite, gentle idle and a local greeting.

const ART: Texture2D = preload("res://assets/characters/godfufu/godfufu.png")
var sprite := Sprite3D.new()
var greeting: Label3D
var elapsed: float = 0.0

func _ready() -> void:
	name = "Godfufu"
	sprite.texture = ART
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.pixel_size = 3.5 / ART.get_height()
	sprite.position.y = 1.75
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
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
	_label("GODFUFU\nKeeper of the clouds", Vector3(0, 4.1, 0), Color("fff0b4"), 32)
	greeting = _label("Welcome, little Fufu.\nRest among the clouds.\nMy story is coming soon.", Vector3(0, 5.4, 0), Color("fff9e8"), 25)
	greeting.visible = false
	MeadowGeometry.rock(self, Vector3(0, 0.025, 0), Vector3(0.9, 0.025, 0.65), Color("b4abd6"))

func _process(delta: float) -> void:
	elapsed += delta
	sprite.position.y = 1.75 + sin(elapsed * 1.6) * 0.07

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

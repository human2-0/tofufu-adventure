class_name GigalopolisChest
extends Node3D
## Small textured supply chest; presentation never grants its contents.

var lid: Node3D
var prompt: Label3D
var opened: bool = false

func _ready() -> void:
	GigalopolisGeometry.box(self, Vector3(0, 0.45, 0), Vector3(1.5, 0.9, 1.1), "wood", true)
	lid = Node3D.new()
	lid.position = Vector3(0, 0.94, -0.55)
	add_child(lid)
	GigalopolisGeometry.box(lid, Vector3(0, 0, 0.55), Vector3(1.6, 0.18, 1.2), "wood")
	for x: float in [-0.58, 0.58]:
		GigalopolisGeometry.box(self, Vector3(x, 0.45, 0.57), Vector3(0.13, 0.82, 0.06), "metal")
		GigalopolisGeometry.box(lid, Vector3(x, 0.12, 0.55), Vector3(0.13, 0.06, 1.2), "metal")
	GigalopolisGeometry.box(self, Vector3(0, 0.65, 0.6), Vector3(0.25, 0.3, 0.07), "brass")
	prompt = Label3D.new()
	prompt.position.y = 1.85
	prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt.font_size = 30
	prompt.pixel_size = 0.007
	prompt.outline_size = 6
	prompt.no_depth_test = false
	prompt.visible = false
	add_child(prompt)

func present(value: bool, focused: bool, key: String = "E") -> void:
	if value != opened:
		opened = value
		lid.rotation.x = -1.15 if value else 0.0
	prompt.visible = focused and not value
	if prompt.visible:
		prompt.text = "[%s] %s" % [key, tr("Open supply chest")]

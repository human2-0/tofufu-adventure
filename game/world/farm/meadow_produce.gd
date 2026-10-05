class_name MeadowProduce
extends StaticBody3D
## Renewable food/mushroom presentation. App supplies the authoritative yield callback.

const REGROW_SECONDS: float = 120.0
var item_id: String = "potato"
var regrow_remaining: float = 0.0
var dispense: Callable
var _visual: Node3D

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.65, 0.8, 0.65)
	collider.shape = shape
	collider.position.y = 0.4
	add_child(collider)
	_visual = Node3D.new()
	add_child(_visual)
	if item_id == "forest_mushroom":
		MeadowGeometry.box(_visual, Vector3(0, 0.2, 0), Vector3(0.12, 0.4, 0.12), Color("e7d8b1"))
		MeadowGeometry.rock(_visual, Vector3(0, 0.42, 0), Vector3(0.3, 0.13, 0.3), Color("946442"))
	else:
		MeadowGeometry.rock(_visual, Vector3(0, 0.45, 0), Vector3(0.4, 0.32, 0.35), Color("6c9950"))
		var color: Color = {"potato": Color("bba16d"), "cucumber": Color("36794b"), "red_berries": Color("bf3c49"), "beetroot": Color("873958")}[item_id]
		for i in 3:
			MeadowGeometry.rock(_visual, Vector3(-0.22 + i * 0.22, 0.18 if item_id == "potato" else 0.5, 0.22), Vector3(0.18, 0.1, 0.08) if item_id == "cucumber" else Vector3.ONE * 0.12, color)

func harvest() -> void:
	if regrow_remaining > 0 or not dispense.is_valid() or not bool(dispense.call()): return
	regrow_remaining = REGROW_SECONDS
	present()

func present() -> void:
	_visual.visible = regrow_remaining <= 0
	collision_layer = 1 if regrow_remaining <= 0 else 0

func _physics_process(delta: float) -> void:
	if regrow_remaining <= 0: return
	regrow_remaining = maxf(0, regrow_remaining - delta)
	if regrow_remaining == 0: present()

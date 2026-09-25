class_name FactoryStationDisplay
extends Node3D
## Cosmetic production feedback driven only by authoritative station progress.

var stage: int = 0
var _products: Array[Node3D] = []
var _blade: MeshInstance3D
var _wheel: MeshInstance3D
var _stream: MeshInstance3D
var _last_units: int = 0
var _running: bool = false
var _clock: float = 0.0

func _ready() -> void:
	for i in 3:
		var product := Node3D.new()
		product.position = Vector3((i-1)*0.65,1.48,0)
		add_child(product)
		var color := Color("c6bb83") if stage < 2 else Color("fff2d7")
		if stage == 5:
			MeadowGeometry.box(product, Vector3(0,-0.04,0), Vector3(0.57,0.12,0.75), Color("bb9c6e"))
		MeadowGeometry.box(product, Vector3.ZERO, Vector3(0.46,0.27,0.55), color)
		_products.append(product)
	if stage == 4:
		_blade = MeadowGeometry.box(self, Vector3(0,2.25,0), Vector3(2.1,0.45,0.08), Color("d9e6de"))
	if stage == 1 or stage == 2:
		_wheel = MeadowGeometry.box(self, Vector3(0,1,0.78), Vector3(0.7,0.12,0.12), Color("e9bb68"))
		MeadowGeometry.box(_wheel, Vector3.ZERO, Vector3(0.12,0.7,0.12), Color("e9bb68"))
	if stage == 2 or stage == 3:
		_stream = MeadowGeometry.box(self, Vector3(0,1.95,0), Vector3(0.13,0.9,0.13), Color("fff2d7"))
		MeadowGeometry.box(self, Vector3(0,2.45,0), Vector3(0.35,0.15,0.45), Color("9aad9f"))

func present(units: int, remaining: float, finished: bool) -> void:
	_running = remaining > 0
	for i in _products.size(): _products[i].visible = finished or i < units
	if _stream != null: _stream.visible = _running
	if units > _last_units and _blade != null:
		var tween := create_tween()
		tween.tween_property(_blade, "position:y", 1.55, 0.18)
		tween.tween_property(_blade, "position:y", 2.25, 0.4)
	_last_units = units

func _process(delta: float) -> void:
	if not _running: return
	_clock += delta
	if _wheel != null: _wheel.rotation.z += delta * 4
	if _stream != null: _stream.scale.x = 0.8 + sin(_clock * 15) * 0.2

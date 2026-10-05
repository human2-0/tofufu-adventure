class_name FactoryBatchLine
extends Node3D
## One finite cosmetic batch follows the real mill outlet and tank inlet.

const PATH: Array[Vector3] = [Vector3(0, 0.65, -5.8), Vector3(0, 3.2, -5.8), Vector3(25.8, 3.2, -5.8), Vector3(25.8, 3.2, -3), Vector3(25.8, 1.55, -3)]
const TRANSFORM_SECONDS: float = 3.0
const FLOW_SPEED: float = 6.0
const PULSE_SECONDS: float = 2.8
var delivered: bool = false
var _milk: Array[MeshInstance3D] = []
var _droplets: Array[MeshInstance3D] = []
var _flow: bool = false
var _clock: float = 0.0
var _soaked: Node3D
var _pulp: Node3D
var _drum: Node3D

func _ready() -> void:
	for index in PATH.size() - 1: _segment(PATH[index], PATH[index + 1], index)
	for index in 8:
		var bead := MeadowGeometry.box(self, Vector3.ZERO, Vector3.ONE * 0.14, Color("f8f2da"))
		_droplets.append(bead)
	_soaked = get_parent().get_node("SoakedBeans")
	_pulp = get_parent().get_node("FilteredPulp")
	_drum = get_parent().get_node("intake_tofu/StaticVisual/GrindingDrum")
	present(false)

func present(produced: bool) -> void:
	if produced == _flow: return
	_flow = produced
	_clock = 0.0
	delivered = false
	_update()

func _process(delta: float) -> void:
	if not _flow: return
	_clock = minf(_clock + delta, TRANSFORM_SECONDS + PULSE_SECONDS + _path_length() / FLOW_SPEED)
	_update()

func _update() -> void:
	if _soaked != null:
		_soaked.visible = _flow and _clock < 1.0
		_pulp.visible = _flow and _clock >= 2.0 and _clock < 3.5
		if _flow and _clock >= 1.0 and _clock < 2.0: _drum.rotation.z = _clock * 9.0
	var length: float = _path_length()
	var head: float = (_clock - TRANSFORM_SECONDS) * FLOW_SPEED
	var tail: float = head - PULSE_SECONDS * FLOW_SPEED
	delivered = _flow and head >= length
	var offset: float = 0.0
	for index in _milk.size():
		var section: float = PATH[index].distance_to(PATH[index + 1])
		_milk[index].visible = _flow and head > offset and tail < offset + section
		offset += section
	for index in _droplets.size():
		var travel: float = head - index * PULSE_SECONDS * FLOW_SPEED / 8.0
		_droplets[index].visible = _flow and travel >= 0.0 and travel <= length
		if _droplets[index].visible: _droplets[index].position = _point(travel)

func _segment(from: Vector3, to: Vector3, index: int) -> void:
	var distance: float = from.distance_to(to)
	var center: Vector3 = (from + to) * 0.5
	var pipe := MeadowGeometry.box(self, center, Vector3(0.28, 0.28, distance), Color("607976"))
	pipe.quaternion = Quaternion(Vector3.BACK, (to - from).normalized())
	var glass := MeadowGeometry.box(pipe, Vector3.ZERO, Vector3(0.3, 0.16, distance * 0.86), Color("b8d4ca"))
	glass.position.y = 0.14
	var core := MeadowGeometry.box(pipe, Vector3(0, 0.25, 0), Vector3(0.12, 0.08, distance * 0.84), Color("f8f2da"))
	core.name = "MilkCore%d" % index
	core.visible = false
	_milk.append(core)
	MeadowGeometry.box(self, from, Vector3.ONE * 0.36, Color("c8a86b"))

func _path_length() -> float:
	var total: float = 0.0
	for index in PATH.size() - 1: total += PATH[index].distance_to(PATH[index + 1])
	return total

func _point(distance: float) -> Vector3:
	for index in PATH.size() - 1:
		var length: float = PATH[index].distance_to(PATH[index + 1])
		if distance <= length: return PATH[index].lerp(PATH[index + 1], distance / length)
		distance -= length
	return PATH.back()

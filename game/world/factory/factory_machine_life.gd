class_name FactoryMachineLife
extends Node3D
## Guarded visual machinery and secondary lines run without moving collision.

var room: int = 0
var _props: Node3D
var _clock: float = 0.0
var _gears: Array[Node3D] = []
var _cargo: Array[Node3D] = []
var _working: bool = false
var _paddle: Node3D
var _vent: FactoryEffectPool
var _vent_clock: float = 0.0

func _ready() -> void:
	_props = get_parent() as Node3D
	if room == 0:
		for index in 3:
			var at := Vector3(-6 + index * 6, 1.12, -6.0)
			_gears.append(_gear(at))
		for side in [-1.0, 1.0]:
			for index in 4:
				var chunk := _painted_box(self, Vector3(side * 6.0, 1.05, -7.0), Vector3(0.42, 0.13, 0.22), Color("dcd0a1"), "cream")
				chunk.set_meta("line_side", side)
				chunk.set_meta("line_offset", index * 0.55)
				_cargo.append(chunk)
	if room == 1:
		_paddle = Node3D.new()
		_paddle.position = Vector3(5, 1.7, -3)
		add_child(_paddle)
		_painted_box(_paddle, Vector3(0, 0.06, 0), Vector3(0.9, 0.06, 0.08), Color("97ada2"))
		_painted_box(_paddle, Vector3(0, 0.15, 0), Vector3(0.07, 0.3, 0.07), Color("97ada2"))
	if room in [0, 1, 2]:
		_vent = FactoryEffectPool.new()
		_vent.name = "VentPuffs"
		add_child(_vent)
	if room == 4:
		for index in 6: _gears.append(_gear(Vector3(-6.0 + index * 2.4, 0.5, -8.1)))

func present(snapshot: Dictionary, motion: Dictionary) -> void:
	_working = false
	if room == 0: _working = not (snapshot.get("sorting", {}) as Dictionary).get("assignments", {}).is_empty()
	if room == 1:
		var data: Dictionary = snapshot.get("lab", {})
		_working = bool(data.get("opening_cleared", false)) and not bool(data.get("complete", false))
		_paddle.visible = _working
	if room == 2: _working = int(motion.get("active_sample", -1)) >= 0

func _process(delta: float) -> void:
	_clock += delta
	for index in _gears.size():
		_gears[index].rotation.z = _clock * (1.2 if index % 2 == 0 else -1.4)
	for chunk in _cargo:
		chunk.position.z = -6.45 - fmod(_clock * 0.45 + float(chunk.get_meta("line_offset")), 2.2)
		chunk.rotation.x = sin(_clock * 2.0 + chunk.position.z) * 0.025
	if _paddle != null and _working: _paddle.rotation.y = _clock * 0.65
	if _vent == null: return
	_vent_clock += delta
	if _vent_clock < 2.8: return
	_vent_clock = 0.0
	if room == 0: _vent.burst("mist", Vector3(-6.8, 0.8, -5.9))
	if _working and room == 1: _vent.burst("steam", Vector3(5.8, 1.7, -3))
	if _working and room == 2: _vent.burst("steam", Vector3(5.8, 1.1, -4.5))

func _gear(at: Vector3) -> Node3D:
	var gear := Node3D.new()
	gear.position = at
	add_child(gear)
	_painted_box(gear, Vector3.ZERO, Vector3(0.5, 0.5, 0.12), Color("65827b"))
	for index in 8:
		var angle: float = index * TAU / 8.0
		var tooth := _painted_box(gear, Vector3(cos(angle), sin(angle), 0) * 0.31, Vector3(0.18, 0.12, 0.13), Color("bac3ad"))
		tooth.rotation.z = angle
	_painted_box(gear, Vector3(0, 0, 0.1), Vector3(0.12, 0.12, 0.14), Color("d9b878"))
	return gear

func _painted_box(parent: Node3D, at: Vector3, size: Vector3, color: Color, surface: String = "iron") -> MeshInstance3D:
	var visual := MeadowGeometry.box(parent, at, size, color)
	FactorySurfaceMaterials.paint_local(visual, surface)
	visual.set_meta("factory_procedural_surface", true)
	return visual

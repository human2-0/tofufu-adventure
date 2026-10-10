class_name FactoryInteractionEffects
extends Node3D
## Machine-local puffs and prop squash respond to replicated accepted state edges.

var room: int = 0
var events := FactoryInteractionEvents.new()
var pool: FactoryEffectPool
var life: FactoryMachineLife
var _props: Node3D
var _settles: Dictionary = {}
var _pour_pose: Node3D
var _pour_stream: MeshInstance3D
var _pour_source: Node3D
var _pour_left: float = 0.0

func _ready() -> void:
	_props = get_parent() as Node3D
	events.room = room
	pool = FactoryEffectPool.new()
	pool.name = "InteractionPuffs"
	add_child(pool)
	life = FactoryMachineLife.new()
	life.name = "WorkingMachinery"
	life.room = room
	_props.add_child(life)
	if room == 1: _build_pour()

func present(snapshot: Dictionary, motion: Dictionary) -> void:
	if is_baseline(snapshot):
		pool.clear()
		_stop_pour()
		for id: String in _settles:
			var prop: Node3D = _props.get_node_or_null(id)
			if prop != null: prop.scale = Vector3.ONE
		_settles.clear()
	life.present(snapshot, motion)
	for event: Dictionary in events.collect(snapshot):
		var prop: Node3D = _props.get_node_or_null(event.target)
		if prop == null: continue
		pool.burst(event.kind, to_local(prop.global_position) + event.offset)
		if room == 0 and str(event.target).begins_with("sack_"): _settles[event.target] = 0.42
		if event.kind == "pour" and event.has("source"): _start_pour(str(event.source))

func is_baseline(snapshot: Dictionary) -> bool:
	return events.needs_baseline(snapshot)

func _process(delta: float) -> void:
	if _pour_left > 0.0:
		_pour_left = maxf(0.0, _pour_left - delta)
		_pour_pose.rotation.z = -1.7 + sin(_pour_left * 9.0) * 0.07
		_pour_stream.scale.x = 0.8 + sin(_pour_left * 25.0) * 0.2
		if _pour_left == 0.0: _stop_pour()
	for id: String in _settles.keys():
		var left: float = maxf(float(_settles[id]) - delta, 0.0)
		_settles[id] = left
		var bounce: float = sin(left / 0.42 * TAU) * left / 0.42 * 0.09
		var prop: Node3D = _props.get_node(id)
		var scale: float = float(prop.get_meta("factory_carried_scale", 1.0))
		prop.scale = Vector3(1.0 + bounce * 0.5, 1.0 - bounce, 1.0 + bounce * 0.5) * scale
		if left == 0.0:
			prop.scale = Vector3.ONE * scale
			_settles.erase(id)

func _build_pour() -> void:
	_pour_pose = Node3D.new()
	_pour_pose.name = "PouringBottle"
	_pour_pose.position = Vector3(4.2, 2.0, -3)
	add_child(_pour_pose)
	MeadowGeometry.rock(_pour_pose, Vector3.ZERO, Vector3(0.15, 0.3, 0.15), Color("b8d4ca"))
	MeadowGeometry.box(_pour_pose, Vector3(0, 0.31, 0), Vector3(0.15, 0.08, 0.15), Color("dbc89d"))
	_pour_stream = MeadowGeometry.box(self, Vector3(4.5, 1.87, -3), Vector3(0.065, 0.48, 0.065), Color("f8f2da"))
	(_pour_stream.mesh.surface_get_material(0) as StandardMaterial3D).next_pass = null
	_pour_pose.visible = false
	_pour_stream.visible = false

func _start_pour(source: String) -> void:
	_stop_pour()
	_pour_source = _props.get_node_or_null(source)
	if _pour_source != null: _pour_source.visible = false
	_pour_left = 0.9
	_pour_pose.visible = true
	_pour_stream.visible = true

func _stop_pour() -> void:
	if _pour_pose == null: return
	_pour_left = 0.0
	_pour_pose.visible = false
	_pour_stream.visible = false
	if _pour_source != null: _pour_source.visible = true
	_pour_source = null

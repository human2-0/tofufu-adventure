class_name TofuFactory
extends Node3D
## Closed district exterior; cutaway interior has two decks and a switchback route.

const EAST_ENTRANCE := Vector3(144, 0.2, 6)
const HALL_START := Vector3(292, 0.2, -180)
const HALL_ARRIVAL := Vector3(296, 0.2, -180)
const HALL_EXIT := Vector3(292, 4.2, -206)
const CENTERS: Array[Vector3] = [Vector3(300,0,-180), Vector3(322,0,-180), Vector3(344,0,-180), Vector3(344,4,-206), Vector3(322,4,-206), Vector3(300,4,-206)]
const STATION_LABELS: Array[String] = ["RECEIVING / WASH", "SOAK & RINSE", "SOY MILK MILL", "COAGULATION", "PRESS & CHOP", "PACK & DISPATCH"]
const INSTRUCTIONS: Array[String] = ["Carry 3 marked soy sacks to the wash hopper", "Open the rinse valve", "Carry 3 soaked sacks to the mill", "Add nigari coagulant · beware the Dofu!", "Cut 3 pressed tofu slabs", "Pack 3 blocks for dispatch"]
var entrance_marker: Node3D
var gates: Array[MeshInstance3D] = []
var interior_built: bool = false
var _process_labels: Array[Label3D] = []
var _bags: Array[Node3D] = []
var _cargo: Array[Node3D] = []
var _displays: Array[FactoryStationDisplay] = []
var _shell: Node3D

func _ready() -> void:
	GigalopolisFactoryExterior.build(self)
	entrance_marker = Node3D.new()
	entrance_marker.position = EAST_ENTRANCE
	add_child(entrance_marker)

static func contains(at: Vector3) -> bool:
	return at.x > 288 and at.x < 360 and at.z > -220 and at.z < -167

static func station(index: int) -> Vector3:
	return CENTERS[index] + Vector3(0, 0, -5)

static func bag(index: int, stage: int) -> Vector3:
	return CENTERS[stage] + Vector3(-5 + index * 5, 0, 5)

func entrance_reached(actor: Node3D) -> bool:
	return actor.global_position.distance_to(EAST_ENTRANCE) < 1.6

func exit_reached(actor: Node3D) -> bool:
	return actor.global_position.distance_to(HALL_EXIT) < 1.7

func entrance_inside_reached(actor: Node3D) -> bool:
	return actor.global_position.distance_to(HALL_START) < 1.6

func ensure_interior() -> void:
	if interior_built: return
	interior_built = true
	for i in CENTERS.size():
		var at := CENTERS[i]
		MeadowGeometry.box(self, at + Vector3(0,-0.3,0), Vector3(22,0.6,20), Color("a4aaa0"), true)
		for z in [-10.0, 10.0]: MeadowGeometry.box(self, at + Vector3(0,2,z), Vector3(22,4,0.35), Color("607e78"), true)
		# Tall rear walls, overhead pipe runs and steel trusses frame a camera cutaway.
		for z in [-9.0, 9.0]: MeadowGeometry.box(self, at + Vector3(0,3.6,z), Vector3(22,0.22,0.22), Color("dfbd73"))
		for x in [-9.0, 9.0]: MeadowGeometry.box(self, at + Vector3(x,1.4,-8), Vector3(0.3,2.8,0.3), Color("475c58"), true)
		var machines := Node3D.new()
		machines.position = at
		add_child(machines)
		FactoryMachines.build(machines, [0,2,3,4,5,6][i])
		FactoryProductionVisuals.build(machines, i)
		MeadowGeometry.box(self, station(i) + Vector3(0,0.65,0), Vector3(2.4,1.3,1.3), Color("437e76"), true)
		_label(at + Vector3(0,3.4,0), "%02d · %s" % [i+1, STATION_LABELS[i]], 34)
		var display := FactoryStationDisplay.new()
		display.stage = i
		display.position = station(i)
		add_child(display)
		_displays.append(display)
		_process_labels.append(_label(station(i) + Vector3(0,3.5,0), INSTRUCTIONS[i] + "\n[E] INTERACT", 25))
		if i == 0 or i == 2:
			for j in 3:
				var sack := Node3D.new()
				sack.position = bag(j, i)
				add_child(sack)
				MeadowGeometry.rock(sack, Vector3(0,0.5,0), Vector3(0.65,0.7,0.5), Color("c5b77c"))
				MeadowGeometry.box(sack, Vector3(0,0.6,0.48), Vector3(0.8,0.3,0.04), Color("5b8970"))
				var sack_label := _label(bag(j,i) + Vector3(0,1.5,0), "SOY %d · [E] CARRY" % (j+1), 22)
				sack_label.reparent(sack)
				_bags.append(sack)
	# Door partitions force the route east across intake, up the ramp, then west.
	for i in [0,1,3,4]:
		var at := CENTERS[i] + Vector3(11 if i < 3 else -11,0,0)
		for z in [-6.5,6.5]: MeadowGeometry.box(self, at + Vector3(0,2,z), Vector3(0.4,4,7), Color("58766e"), true)
		var door := MeadowGeometry.box(self, at + Vector3(0,2,0), Vector3(0.4,4,6), Color("b48a57"), true)
		gates.append(door)
	for landing in [Vector3(356,-0.3,-178), Vector3(356,3.7,-208)]:
		MeadowGeometry.box(self, landing, Vector3(6,0.6,6), Color("9b9d8c"), true)
	MeadowGeometry.box(self, Vector3(359,4,-193), Vector3(0.4,8,46), Color("58766e"), true)
	# The roof remains physical; its render is cut away for the overhead camera.
	_shell = Node3D.new()
	add_child(_shell)
	MeadowGeometry.box(_shell, Vector3(324,10,-193), Vector3(72,0.4,48), Color("3b5957"), true)
	for z in [-216.0,-170.0]: MeadowGeometry.box(_shell, Vector3(324,7,z), Vector3(70,6,0.4), Color("607e78"), true)
	for x in [289.0,359.0]: MeadowGeometry.box(_shell, Vector3(x,7,-193), Vector3(0.4,6,46), Color("607e78"), true)
	_shell.visible = false
	# Ramp rises four metres over a 26 metre run; broad enough for party combat.
	var ramp := MeadowGeometry.box(self, Vector3(356,1.95,-193), Vector3(6,0.5,26.37), Color("9b9d8c"), true)
	ramp.rotation.x = atan2(4.4,26.0)
	for x in [353.2,358.8]:
		var rail := MeadowGeometry.box(self, Vector3(x,3.2,-193), Vector3(0.2,1,26.31), Color("dfbd73"), true)
		rail.rotation.x = ramp.rotation.x
	var ramp_gate := MeadowGeometry.box(self, Vector3(354,2,-178), Vector3(0.35,4,20), Color("b48a57"), true)
	gates.insert(2,ramp_gate)
	for i in [0,5]: MeadowGeometry.box(self, CENTERS[i] + Vector3(-11,2,0), Vector3(0.4,4,20), Color("58766e"), true)
	_label(HALL_START + Vector3.UP*2, "EXIT · GIGALOPOLIS", 25)
	_label(HALL_EXIT + Vector3.UP*2, "DISPATCH EXIT · COMPLETE TO UNLOCK", 25)

func open_gate(index: int) -> void:
	if index < 0 or index >= gates.size(): return
	gates[index].visible = false
	(gates[index].get_child(0) as StaticBody3D).collision_layer = 0

func reset_gates(stage: int) -> void:
	ensure_interior()
	for i in mini(stage, _displays.size()):
		_displays[i].present(3,0,true)
		_process_labels[i].text = "PRODUCTION COMPLETE"
	for i in gates.size():
		gates[i].visible = i >= stage
		(gates[i].get_child(0) as StaticBody3D).collision_layer = 1 if i >= stage else 0

func process_finished(index: int) -> void:
	_process_labels[index].text = "PRODUCTION COMPLETE"
	_displays[index].present(3,0,true)
	open_gate(index)

func show_processing(index: int, remaining: float) -> void:
	_displays[index].present(3,remaining,false)
	_process_labels[index].text = "%s · %.0f s" % [STATION_LABELS[index], ceilf(remaining)]

func show_objective(stage: int, units: int, secured: bool, carrying: bool) -> void:
	if not interior_built or stage >= 6: return
	_displays[stage].present(units,0,false)
	_process_labels[stage].text = ("CLEAR THE ROOM" if not secured else INSTRUCTIONS[stage] + " · %d/3" % units) + "\n[E] " + ("DROP INTO HOPPER" if carrying else "INTERACT")
	for i in _bags.size():
		var bag_stage := 0 if i < 3 else 2
		var label := _bags[i].get_child(2) as Label3D
		if label != null:
			label.text = "SOY %d · %s" % [i % 3 + 1, "[E] CARRY" if i % 3 == units and stage == bag_stage else "QUEUED"]
		_bags[i].visible = bag_stage > stage or (bag_stage == stage and i % 3 >= units + (1 if carrying else 0))

func _label(at: Vector3, value: String, size: int) -> Label3D:
	var label := Label3D.new()
	label.text = value
	label.font_size = size
	label.pixel_size = 0.01
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("fff0c3")
	label.position = at
	add_child(label)
	return label

func show_cargo(points: Array) -> void:
	while _cargo.size() > points.size(): _cargo.pop_back().queue_free()
	for i in points.size():
		if i >= _cargo.size():
			var sack := Node3D.new()
			add_child(sack)
			MeadowGeometry.rock(sack, Vector3.ZERO, Vector3(0.45,0.55,0.35), Color("c5b77c"))
			MeadowGeometry.box(sack, Vector3(0,0,0.34), Vector3(0.5,0.2,0.03), Color("5b8970"))
			_cargo.append(sack)
		var point: Array = points[i]
		_cargo[i].position = Vector3(point[0],point[1],point[2]) + Vector3(0,1.4,0.5)

func set_cutaway(cutaway: bool) -> void:
	if _shell != null: _shell.visible = not cutaway

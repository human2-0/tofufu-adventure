class_name FactoryPuzzleProps
extends RefCounted
## Fixed machine silhouettes and inspectable prop locations for the six-room route.

static func build(parent: Node3D, stage: int) -> void:
	match stage:
		0: _sorting(parent)
		1: _laboratory(parent)
		2: _presses(parent)
		3: _cutter(parent)
		4: _packer(parent)
		5: _arena(parent)
	var view := FactoryProductionVisuals.new()
	view.name = "ProductionVisuals"
	view.room = stage
	parent.add_child(view)

static func _sorting(parent: Node3D) -> void:
	var intakes: Array[String] = ["chilledintake", "tofumill", "oilintake"]
	var sacks: Array[String] = ["edamamesack", "maturesack", "highfatsack"]
	for index in 3:
		var x := -6.0 + index * 6.0
		_scene(parent, intakes[index], Vector3(x, 0, -5), FactoryLayout.INTAKE_IDS[index])
		var sack := _scene(parent, sacks[index], Vector3(x, 0, 5), FactoryLayout.SACK_IDS[index])
		(sack.get_node("Body") as StaticBody3D).collision_layer = 0
	MeadowGeometry.box(parent, Vector3(0, 0.65, -1), Vector3(3, 1.3, 3), Color("7c9690"), true)
	MeadowGeometry.box(parent, Vector3(0, 1.5, -1), Vector3(2.4, 0.1, 2.4), Color("e9e1c5"))
	_label(parent, Vector3(0, 2.2, -1), "WASH → GRIND → FILTER")
	var soaked := MeadowGeometry.box(parent, Vector3(0, 1.55, -1), Vector3(1.6, 0.16, 1.6), Color("d2bd89"))
	soaked.name = "SoakedBeans"
	soaked.visible = false
	var pulp := MeadowGeometry.box(parent, Vector3(0.48, 1.43, -5.61), Vector3(0.6, 0.08, 0.55), Color("c7b080"))
	pulp.name = "FilteredPulp"
	pulp.visible = false
	var line := FactoryBatchLine.new()
	line.name = "BatchLine"
	parent.add_child(line)
	MeadowGeometry.box(parent, Vector3(24.8, 2.7, -3), Vector3(1.6, 0.8, 1.2), Color("607976"))
	_label(parent, Vector3(24.8, 3.35, -3), "UPSTREAM BUFFER")
	# Sealed secondary lines show their output, with no traversable continuation.
	for x in [-6.0, 6.0]:
		MeadowGeometry.box(parent, Vector3(x, 0.8, -7.2), Vector3(1.5, 0.15, 2.2), Color("684e3d"))
		MeadowGeometry.box(parent, Vector3(x, 1.6, -9.4), Vector3(2.0, 3.2, 0.5), Color("607976"), true)
		for index in 4:
			MeadowGeometry.box(parent, Vector3(x, 1.0, -6.5 - index * 0.5), Vector3(0.7, 0.22, 0.25), Color("81a36d") if x < 0 else Color("f0e9d2"))

static func _laboratory(parent: Node3D) -> void:
	for index in 20:
		var x := -8.0 + index % 10 * 1.8
		var z := -7.0 if index < 10 else 7.0
		MeadowGeometry.box(parent, Vector3(x, 0.55, z), Vector3(1.2, 1.1, 0.65), Color("9b7656"), true)
		var bottle := _scene(parent, "bottle_%02d" % index, Vector3(x, 1.1, z), "container_%02d" % index)
		(bottle.get_node("Body") as StaticBody3D).collision_layer = 0
		var label: Label3D = bottle.get_node("ContentLabel")
		bottle.rotation.y = PI if index >= 10 else 0.0
		label.pixel_size = 0.003
		label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		label.position.y = 0.65
		label.text = FactoryLayout.CHEMICAL_IDS[index].replace("_", " ").capitalize()
	_scene(parent, "lab_terminal", Vector3(-6, 0, -2))
	_scene(parent, "coagulation_tank", Vector3(5, 0, -3))
	# The return rack hides the floor note; either end stays capsule-safe.
	MeadowGeometry.box(parent, Vector3(-4, 0.8, 5.4), Vector3(3.4, 1.6, 0.55), Color("827f69"), true)
	MeadowGeometry.box(parent, Vector3(-4, 0.08, 7.0), Vector3(1.4, 0.16, 1.2), Color("9b9d8c"), true)
	_scene(parent, "shift_note", Vector3(-4, 0.16, 7.5))

static func _presses(parent: Node3D) -> void:
	_scene(parent, "traditional_press", Vector3(-6, 0, -5))
	_scene(parent, "modern_press", Vector3(5, 0, -5))
	for index in 3:
		var stone := _scene(parent, "press_stone", Vector3(-7 + index * 2.5, 0, 6), "stone_%d" % (index + 1))
		(stone.get_node("Body") as StaticBody3D).collision_layer = 0

static func _cutter(parent: Node3D) -> void:
	_scene(parent, "cutter", Vector3(0, 0, -7))
	_label(parent, Vector3(0, 3, -7), "FIVE GUIDES · SIX SLABS")
	MeadowGeometry.box(parent, Vector3(0, 0.2, 3), Vector3(10, 0.4, 1.5), Color("607976"), true)

static func _packer(parent: Node3D) -> void:
	MeadowGeometry.box(parent, Vector3(0, 0.65, -7), Vector3(16, 1.3, 3), Color("6c897e"), true)
	for index in 6:
		var x := -6.0 + index * 2.4
		MeadowGeometry.box(parent, Vector3(x, 1.34, -7), Vector3(1.5, 0.08, 1.5), Color("dbc89d"))
		_label(parent, Vector3(x, 1.9, -7), "SLOT %d" % (index + 1))
		var dock := Node3D.new()
		dock.name = "package_%d" % index
		dock.position = Vector3(x, 1.35, -7)
		parent.add_child(dock)
		var contents := MeadowGeometry.box(dock, Vector3(0, 0.14, 0), Vector3(0.6, 0.28, 1.15), Color("f8f2da"))
		contents.name = "Contents"
		contents.visible = false
		var seal := MeadowGeometry.box(dock, Vector3(0, 0.3, 0), Vector3(0.8, 0.04, 1.3), Color("b8d4ca"))
		seal.name = "Seal"
		seal.visible = false

static func _arena(parent: Node3D) -> void:
	for x in [-7.0, 7.0]:
		for z in [-7.0, 7.0]:
			MeadowGeometry.box(parent, Vector3(x, 0.6, z), Vector3(1.2, 1.2, 1.2), Color("536d68"), true)
	_label(parent, Vector3(0, 3, 0), "DOFUFU · REFINERY GATE")

static func _label(parent: Node3D, at: Vector3, title: String) -> void:
	var label := Label3D.new()
	label.double_sided = false
	label.text = title
	label.font_size = 25
	label.pixel_size = 0.008
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.position = at
	parent.add_child(label)

static func _scene(parent: Node3D, scene_name: String, at: Vector3, object_id: String = "") -> Node3D:
	var packed: PackedScene = load("res://game/world/factory/props/%s.tscn" % scene_name)
	var instance: Node3D = packed.instantiate()
	instance.name = scene_name if object_id.is_empty() else object_id
	parent.add_child(instance)
	instance.position = at
	return instance

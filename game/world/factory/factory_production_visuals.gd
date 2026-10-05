class_name FactoryProductionVisuals
extends Node3D
## Read-only presentation of authority snapshots; no outcome or identity decisions.

var room: int = 0
var _props: Node3D
var _rest: Dictionary = {}
var _last_shelf: Array = []
var _slabs: Array[MeshInstance3D] = []
var _previous_carried: Dictionary = {}
var _rejections: Dictionary = {}
var _whey: Array[MeshInstance3D] = []
var _draining: bool = false
var _clock: float = 0.0
var _batch_line: FactoryBatchLine
var _lab_rejected: bool = false
var _refill: float = 2.0
var _drain: Node3D
var _cut_revision: int = -1
var _cut_cycle: float = 0.0
var _seal_cycles: Dictionary = {}
var _previous_seals: Array = []
var _audio: FactoryMachineAudio

func _ready() -> void:
	_props = get_parent() as Node3D
	add_to_group("factory_production_visuals")
	_audio = FactoryMachineAudio.new()
	_audio.room = room
	_props.add_child(_audio)
	for child in _props.get_children():
		if child is Node3D and child != self: _rest[child.name] = child.position
	if room == 1:
		_drain = MeadowGeometry.box(_props, Vector3(5, 0.2, -1.5), Vector3(0.16, 0.08, 1.0), Color("dfd6b5"))
		_drain.visible = false
	if room == 2:
		for index in 4:
			var drop := MeadowGeometry.box(_props, Vector3(-6, 0.3, -3.8), Vector3(0.08, 0.06, 0.08), Color("dfd6b5"))
			drop.visible = false
			_whey.append(drop)
	if room == 3:
		for index in 6:
			var slab := MeadowGeometry.box(_props, Vector3(-4 + index * 1.6, 0.48, 3), Vector3(0.6, 0.28, 1.15), Color("f8f2da"))
			slab.name = "slab_%d" % index
			slab.visible = false
			_slabs.append(slab)

static func present_factory(factory: Node3D, snapshot: Dictionary, actors: Dictionary = {}, motion: Dictionary = {}) -> void:
	if not factory.is_inside_tree(): return
	for view: Node in factory.get_tree().get_nodes_in_group("factory_production_visuals"):
		if factory.is_ancestor_of(view): (view as FactoryProductionVisuals).present(snapshot, actors, motion)

func present(snapshot: Dictionary, actors: Dictionary, motion: Dictionary) -> void:
	_audio.present(snapshot, motion)
	match room:
		0: _sorting(snapshot.get("sorting", {}), actors)
		1: _laboratory(snapshot, actors)
		2: _pressing(snapshot.get("press", {}), motion)
		3: _cutting(snapshot, actors, motion)
		4: _packing(snapshot.get("pack", {}))

func _sorting(data: Dictionary, actors: Dictionary) -> void:
	var assigned: Dictionary = data.get("assignments", {})
	var carried: Dictionary = data.get("carried_by", {})
	for id: String in FactoryLayout.SACK_IDS:
		var sack: Node3D = _props.get_node(id)
		sack.visible = not assigned.has(id)
		_pose(sack, int(carried.get(id, 0)), actors)
		if bool(data.get("combat_locked", false)) and _previous_carried.has(id) and not carried.has(id) and not assigned.has(id):
			_rejections[id] = 0.65
	_previous_carried = carried.duplicate()
	var line: FactoryBatchLine = _props.get_node("BatchLine")
	line.present(assigned.has("sack_mature"))

func _laboratory(snapshot: Dictionary, actors: Dictionary) -> void:
	var data: Dictionary = snapshot.get("lab", {})
	var shelf: Array = data.get("shelf_order", [])
	if shelf.size() == 20 and shelf != _last_shelf:
		_last_shelf = shelf.duplicate()
		for index in 20:
			var bottle: Node3D = _props.get_node("container_%02d" % index)
			var label: Label3D = bottle.get_node("ContentLabel")
			label.text = _chemical_name(str(shelf[index]))
			bottle.set_meta("content_id", shelf[index])
	for index in 20:
		var id: String = "container_%02d" % index
		var bottle: Node3D = _props.get_node(id)
		var carrier: int = int(data.get("carrier_id", 0)) if data.get("carried_bottle", "") == id else 0
		_pose(bottle, carrier, actors)
	var tank: Node3D = _props.get_node("coagulation_tank")
	if _batch_line == null:
		for view: Node in get_tree().get_nodes_in_group("factory_production_visuals"):
			if (view as FactoryProductionVisuals).room == 0 and view.get_parent().get_parent() == _props.get_parent():
				_batch_line = view.get_parent().get_node("BatchLine")
	var rejected: bool = bool(data.get("combat_locked", false)) and not bool(data.get("curd_encounter", false))
	if _lab_rejected and not rejected: _refill = 0.0
	_lab_rejected = rejected
	_drain.visible = rejected or _refill < 2.0
	var milk: Node3D = tank.get_node("MovingParts/MilkLevel")
	milk.visible = _batch_line != null and _batch_line.delivered and not bool(data.get("complete", false))
	milk.position.y = 1.08 if rejected else lerpf(1.08, 1.59, minf(_refill / 2.0, 1.0))
	(tank.get_node("MovingParts/CurdPreview") as Node3D).visible = bool(data.get("curd_encounter", false)) or bool(data.get("complete", false))

func _pressing(data: Dictionary, motion: Dictionary) -> void:
	var stones: Array = data.get("stones", [])
	var traditional: Node3D = _props.get_node("traditional_press")
	for index in 3:
		var id: String = "stone_%d" % (index + 1)
		var stone: Node3D = _props.get_node(id)
		stone.position = _rest[id]
		if stones.has(id): stone.position = traditional.position + (traditional.get_node("stone_socket_%d" % (stones.find(id) + 1)) as Node3D).position
	var elapsed: float = maxf(0.0, float(motion.get("elapsed", 0.0)))
	var sample: int = int(motion.get("active_sample", -1))
	var plate: Node3D = traditional.get_node("MovingParts/CompressionPlate")
	plate.position.y = 1.05 - minf(elapsed / 5.0, 1.0) * 0.18 if sample in [0, 1] else 1.05
	_draining = sample in [0, 1] and elapsed > 0.0
	for drop in _whey: drop.visible = _draining
	var modern: Node3D = _props.get_node("modern_press")
	var gauge: float = clampf(float(motion.get("gauge", 0.0)), 0.0, 100.0)
	(modern.get_node("MovingParts/MovingPlate") as Node3D).position.y = 1.47 - gauge / 100.0 * 0.48
	(modern.get_node("MovingParts/GaugeNeedle") as Node3D).rotation.z = deg_to_rad(110.0 - gauge * 2.2)

func _cutting(snapshot: Dictionary, actors: Dictionary, motion: Dictionary) -> void:
	var cut: Dictionary = snapshot.get("cut", {})
	var pack: Dictionary = snapshot.get("pack", {})
	var complete: bool = bool(cut.get("completed", false))
	var cutter: Node3D = _props.get_node("cutter")
	(cutter.get_node("MovingParts/QuestBlock") as Node3D).visible = not complete and not str(cut.get("block_id", "")).is_empty()
	var guides: Array = motion.get("cut_guides", [])
	var length: float = float(cut.get("length", 0.0))
	if guides.size() == 5 and length > 0.0:
		for index in 5:
			var guide: Node3D = cutter.get_node("MovingParts/Guide%d" % (index + 1))
			guide.position.x = clampf(float(guides[index]) / length, 0.0, 1.0) * 3.6 - 1.8
	var widths: Array = cut.get("widths", [])
	var slots: Array = pack.get("slab_slots", [])
	var owners: Array = pack.get("owners", [])
	var failed: bool = bool(cut.get("rejected", false))
	var revision: int = int(cut.get("revision", 0))
	if revision != _cut_revision and (complete or failed): _cut_cycle = 0.6
	_cut_revision = revision
	var cursor: float = -1.8
	for index in _slabs.size():
		var slab: MeshInstance3D = _slabs[index]
		slab.visible = failed or (complete and (slots.size() != 6 or int(slots[index]) < 0))
		if widths.size() == 6: slab.scale.x = float(widths[index])
		slab.position = Vector3(-4 + index * 1.6, 0.48, 3)
		if failed and widths.size() == 6:
			slab.position = Vector3(cursor + float(widths[index]) * 0.3, 1.48, -7)
			cursor += float(widths[index]) * 0.6
		elif owners.size() == 6: _carry(slab, int(owners[index]), actors)

func _packing(data: Dictionary) -> void:
	var slots: Array = data.get("slot_slabs", [])
	var sealed: Array = data.get("sealed", [])
	for index in 6:
		var dock: Node3D = _props.get_node("package_%d" % index)
		(dock.get_node("Contents") as Node3D).visible = slots.size() == 6 and int(slots[index]) >= 0
		(dock.get_node("Seal") as Node3D).visible = sealed.size() == 6 and bool(sealed[index])
		if sealed.size() == 6 and bool(sealed[index]) and (_previous_seals.size() != 6 or not bool(_previous_seals[index])): _seal_cycles[index] = 0.6
	_previous_seals = sealed.duplicate()

func _pose(prop: Node3D, actor: int, actors: Dictionary) -> void:
	prop.position = _rest[prop.name]
	_carry(prop, actor, actors)

func _carry(prop: Node3D, actor: int, actors: Dictionary) -> void:
	var at: Variant = actors.get(actor, actors.get(str(actor)))
	if actor > 0 and at is Vector3: prop.global_position = at + Vector3(0, 0.7, 0.6)

func _chemical_name(id: String) -> String:
	var title: String = id.replace("_", " ").capitalize()
	var split: int = title.find(" ")
	if split >= 0: title = title.substr(0, split) + "\n" + title.substr(split + 1)
	return title

func _process(delta: float) -> void:
	_clock += delta
	_refill = minf(_refill + delta, 2.0)
	if _cut_cycle > 0.0:
		_cut_cycle = maxf(0.0, _cut_cycle - delta)
		(_props.get_node("cutter/MovingParts/Blade") as Node3D).position.y = 2.12 - sin(_cut_cycle / 0.6 * PI) * 0.5
	for slot: int in _seal_cycles.keys():
		var left: float = maxf(0.0, float(_seal_cycles[slot]) - delta)
		(_props.get_node("package_%d/Seal" % slot) as Node3D).scale.z = 1.0 - left / 0.6 * 0.95
		_seal_cycles[slot] = left
		if left == 0.0: _seal_cycles.erase(slot)
	for id: String in _rejections.keys():
		var remaining: float = maxf(0.0, float(_rejections[id]) - delta)
		var sack: Node3D = _props.get_node(id)
		sack.rotation.z = sin(remaining * 24.0) * remaining * 0.25
		_rejections[id] = remaining
		if remaining == 0.0: _rejections.erase(id)
	if not _draining: return
	for index in _whey.size():
		var phase: float = fmod(_clock * 1.5 + index * 0.25, 1.0)
		_whey[index].position = Vector3(-6, 0.23 - phase * 0.18, -3.9 + phase * 0.65)

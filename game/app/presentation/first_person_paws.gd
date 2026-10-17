class_name FirstPersonPaws
extends Node3D
## Two camera-space paw gloves follow the existing punch hands and sleeves.

var view: FirstPersonWeapon
var paws: Array[BengalPawVisual] = []
var rakes: Array[Sprite3D] = []
var _finisher_sequence: int = 0
var _finisher: float = 0.0

func pose_hands() -> void:
	for hand in view._hands: hand.layers = 0 if view.combat.claws.selected else 1
	if not view.combat.claws.selected: return
	var claws := view.combat.claws
	var loaded := clampf(claws.charge / BengalClaws.CHARGE_SECONDS, 0, 1)
	var striking := (view.combat.equipment.punch_sequence + 1) % 2
	var special := claws.dashing or claws.sequence > _finisher_sequence or _finisher > 0.0
	for index in 2:
		var hand := view._hands[index]
		var side := 1.0 if index == 0 else -1.0
		var stroke := sin(clampf(view.combat.equipment._punch_time / BengalClaws.CADENCE, 0, 1) * PI) if index == striking else 0.0
		if special: stroke = sin(clampf(_finisher / 0.42, 0, 1) * PI)
		hand.position += Vector3(-side * stroke * 0.19, loaded * 0.11 + stroke * 0.10, loaded * 0.08 - stroke * 0.48)
		if claws.dashing: hand.position += Vector3(-side * 0.12, 0.08, -0.30)

func _ready() -> void:
	for index in 2:
		var paw := BengalPawVisual.new()
		paw.flip_h = index == 1
		add_child(paw)
		paws.append(paw)
		var rake := Sprite3D.new()
		rake.texture = BengalRiftVFX.RIFT
		rake.shaded = false
		rake.pixel_size = 0.24 / rake.texture.get_width()
		rake.position = Vector3(0, 0.08, 0.02)
		paw.add_child(rake)
		rakes.append(rake)

func _process(delta: float) -> void:
	_finisher = maxf(0.0, _finisher - delta)
	if view.combat.claws.sequence > _finisher_sequence: _finisher = 0.42
	_finisher_sequence = view.combat.claws.sequence
	visible = view.combat.claws.selected and view.visible
	if not visible: return
	var loaded := clampf(view.combat.claws.charge / BengalClaws.CHARGE_SECONDS, 0, 1)
	for index in 2:
		var wrist := view._hands[index].global_position
		var start := Vector3(0.55 if index == 0 else -0.55, -0.70, -0.7)
		var up := Vector3(wrist.x - start.x, wrist.y - start.y, 0).normalized()
		var plane := Basis(Vector3(up.y, -up.x, 0), up, Vector3.BACK)
		paws[index].wear(wrist + Vector3.BACK * 0.08, plane, 0.33)
		rakes[index].visible = view.combat.claws.busy() or _finisher > 0.0
		var power := 1.0 if view.combat.claws.dashing or _finisher > 0.0 else loaded
		rakes[index].scale = Vector3.ONE * (0.2 + power * 0.8)
		rakes[index].rotation.z = (-0.55 if index == 0 else 0.55) * (1.0 - _finisher / 0.42)
		rakes[index].modulate = Color(0.8, 0.85, 1, 0.3 + power * 0.6)

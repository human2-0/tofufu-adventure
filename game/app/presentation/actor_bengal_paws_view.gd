class_name ActorBengalPawsView
extends Node3D
## Follows the rendered wrists for both authority and replica actors.

var combat: PlayerCombat
var sprite: FufuVisuals
var paws: Array[BengalPawVisual] = []
var wrist := Vector3.ZERO
var plane := Basis.IDENTITY
var right_in_front: bool = true
var _finisher_sequence: int = 0
var _finisher: float = 0.0

func _ready() -> void:
	for index in 2:
		var paw := BengalPawVisual.new()
		paw.flip_h = index == 1
		add_child(paw)
		paws.append(paw)
	sprite.hand_presented.connect(_hand)

func _hand(hand: Vector3, view_plane: Basis, _outward: float, front: bool) -> void:
	wrist = hand
	plane = view_plane
	right_in_front = front

func _process(delta: float) -> void:
	_finisher = maxf(0.0, _finisher - delta)
	if combat.claws.sequence > _finisher_sequence: _finisher = 0.5
	_finisher_sequence = combat.claws.sequence
	visible = combat.claws.selected
	if not visible: return
	var across := plane.x * (wrist - sprite.global_position).dot(plane.x)
	var stroke := sin(clampf(combat.equipment._punch_time / BengalClaws.CADENCE, 0, 1) * PI)
	var aim := combat.equipment.facing
	var loaded := clampf(combat.claws.charge / BengalClaws.CHARGE_SECONDS, 0, 1)
	var both_front := int(sprite.current_facing) in [1, 2, 3]
	var striking := (combat.equipment.punch_sequence + 1) % 2
	var double_cut := combat.claws.dashing or _finisher > 0.0
	if double_cut: stroke = sin(clampf(_finisher / 0.5, 0, 1) * PI)
	for index in 2:
		var cut := stroke if index == striking or double_cut else 0.0
		var reach := 0.55 if combat.claws.dashing else cut * 0.32 - loaded * 0.14
		var push := Vector3(aim.x, 0, aim.y) * reach + Vector3.UP * loaded * 0.14
		var front := right_in_front if index == 0 else not right_in_front
		var depth := 0.04 if front or both_front else -0.04
		var cuff := wrist - across * (2 * index) + push - plane.y * 0.065 + plane.z * depth
		var side := -1.0 if index == 0 else 1.0
		paws[index].wear(cuff, plane.rotated(plane.z, side * (0.3 + cut * 0.5)))

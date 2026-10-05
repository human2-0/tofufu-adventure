class_name SoyPlantVisual
extends Node3D
## Visible seed, cotyledons, trifoliate canopy, axillary flowers and mature pods.

enum Stage { SEED, SPROUT, VEGETATION, FLOWERING, MATURE }
var stage: Stage = Stage.MATURE
var _stages: Array[Node3D] = []
var _clock: float = 0.0

func _ready() -> void:
	for phase in 5:
		var shape := Node3D.new()
		shape.name = ["Seed", "Sprout", "Vegetation", "Flowering", "MaturePods"][phase]
		add_child(shape)
		_stages.append(shape)
		_build(shape, phase)
	present(1.0)

func present(growth: float) -> void:
	# Avoid rounding down exact stage boundaries after timer subtraction.
	var progressed := growth + 0.000001
	stage = Stage.MATURE if progressed >= 1.0 else (Stage.SEED if progressed < 0.1 else (
		Stage.SPROUT if progressed < 0.27 else (Stage.VEGETATION if progressed < 0.6 else Stage.FLOWERING)))
	for index in _stages.size():
		_stages[index].visible = index == stage
	# The canopy fills out within its stage while its botanical silhouette stays readable.
	var fill := clampf((growth - 0.27) / 0.33, 0.0, 1.0)
	if stage == Stage.VEGETATION: _stages[stage].scale = Vector3.ONE * lerpf(0.65, 1.0, fill)

func _process(delta: float) -> void:
	_clock += delta
	if stage != Stage.SEED:
		_stages[stage].rotation.z = sin(_clock * 1.7 + get_parent().position.x) * 0.025
		_stages[stage].rotation.x = sin(_clock * 1.2 + get_parent().position.z) * 0.016

func _build(parent: Node3D, phase: int) -> void:
	var art := SoyPlantGeometry.new()
	if phase == Stage.SEED:
		art.oval(Vector3(0, 0.032, 0), Vector3(0.095, 0.045, 0.075), Color("d3ba81"))
		art.segment(Vector3(0.05, 0.06, 0), Vector3(0.025, 0.15, 0), 0.016, Color("729849"))
		art.leaf(Vector3(0.025, 0.14, 0), Vector3(-0.07, 0.18, 0.025), 0.035, Color("a4be68"))
	elif phase == Stage.SPROUT:
		art.segment(Vector3.ZERO, Vector3(0, 0.35, 0), 0.021, Color("79994c"))
		for side in [-1.0, 1.0]:
			art.oval(Vector3(side * 0.065, 0.17, 0), Vector3(0.075, 0.035, 0.05), Color("a8bc66"))
			art.leaf(Vector3(0, 0.32, 0), Vector3(side * 0.24, 0.38, 0.06), 0.09, Color("83ad50"))
	else:
		_canopy(art, phase)
	art.bake(parent)

func _canopy(art: SoyPlantGeometry, phase: int) -> void:
	var stem := Color("668743")
	var previous := Vector3.ZERO
	for index in 6:
		var joint := Vector3(sin(index * 0.8) * 0.035, 0.22 + index * 0.195, 0)
		art.segment(previous, joint, 0.027 - index * 0.0025, stem)
		previous = joint
		if index == 0: continue
		var angle := index * 2.4
		var radial := Vector3(cos(angle), 0, sin(angle))
		var spread := 0.28 if index < 4 else 0.19
		var branch := joint + radial * spread + Vector3.UP * 0.11
		art.segment(joint, branch, 0.012, stem)
		var color := Color("578c3e") if index % 2 == 0 else Color("70a34a")
		# Soy's compound leaves have a terminal leaflet and two lateral leaflets.
		for side in [-1.0, 0.0, 1.0]:
			var direction := radial.rotated(Vector3.UP, side * 1.05)
			var tip := branch + direction * (0.32 if side == 0 else 0.26) + Vector3.UP * 0.035
			art.leaf(branch, tip, 0.105 if side == 0 else 0.09, color)
		if phase == Stage.FLOWERING:
			for flower in 3:
				art.flower(joint + radial * (0.06 + flower * 0.032) + Vector3.UP * (flower * 0.024), radial)
		if phase == Stage.MATURE:
			for pod in 2:
				art.pod(joint + radial * (0.10 + pod * 0.10) + Vector3.UP * (0.02 + pod * 0.06), radial)
	art.leaf(previous, previous + Vector3(0.08, 0.17, 0.025), 0.055, Color("83ad50"))

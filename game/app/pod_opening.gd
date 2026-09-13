class_name PodOpening
extends Node
## App-level composition: quest rules, held actor, plant, camera and display.

signal completed
var player: Player
var camera: CameraFollow
var rules := PodEscapeRules.new()
var plant: SoybeanPlant
var display: PodQuestHUD
var active: bool = true
var _wide_offset: Vector3
@export var close_camera_offset: Vector3 = Vector3(0, 3.6, 6.2)
var _escape_start: Vector3

func _ready() -> void:
	plant = SoybeanPlant.new()
	add_child(plant)
	display = PodQuestHUD.new()
	add_child(display)
	_wide_offset = camera.offset
	player.set_physics_process(false)
	player.get_node("GroundShadow").visible = false
	player.position = plant.seat.global_position
	camera.offset = close_camera_offset
	camera.global_position = player.global_position + camera.offset
	camera._update_camera_orientation()
	_present(0.0)

func _physics_process(delta: float) -> void:
	if not active:
		return
	var command := player.command_source.sample(player.global_position)
	var previous := rules.stage
	rules.step(delta, command.move.x, command.jump_held)
	if rules.stage != previous:
		if rules.stage == PodEscapeRules.Stage.SPLIT:
			camera.shake(0.16)
		elif rules.stage == PodEscapeRules.Stage.REVEAL:
			_escape_start = player.global_position
		elif rules.stage == PodEscapeRules.Stage.COMPLETE:
			_finish()
			return
	_present(delta)

func _present(delta: float) -> void:
	var falling := rules.stage == PodEscapeRules.Stage.FALL
	var landed := rules.stage >= PodEscapeRules.Stage.SPLIT
	var revealing := rules.stage == PodEscapeRules.Stage.REVEAL
	var fall := clampf(pow(rules.elapsed / 0.9, 2.0), 0, 1) if falling else (1.0 if landed else 0.0)
	var opening := smoothstep(0.0, 0.8, rules.elapsed) if revealing else 0.0
	var sway := sin(rules.beat * TAU) * (0.06 + rules.pushes * 0.045)
	plant.present(sway, fall, opening)
	if revealing:
		var travel := smoothstep(0.0, 1.25, rules.elapsed)
		player.global_position = _escape_start.lerp(Vector3(0, 0.05, 1.8), travel)
		player.position.y += sin(travel * PI) * 1.0
		camera.offset = close_camera_offset.lerp(_wide_offset, smoothstep(0.4, 3.0, rules.elapsed))
	else:
		player.global_position = plant.seat.global_position
	var pose := PlayerCommand.new()
	pose.aim = Vector2.DOWN
	player.visuals.present(pose, Vector3.ZERO, true, false, delta, clampf(rules.charge / 0.82, 0, 1))
	display.set_reveal(smoothstep(0.4, 3.0, rules.elapsed) if revealing else 0.0)
	_show_display()

func _show_display() -> void:
	var title := "Rock the nursery"
	var instruction := "Tap %s in the gold zone" % ("RIGHT / D / →" if rules.direction > 0 else "LEFT / A / ←")
	var progress := "01 / ESCAPE THE SOYBEAN POD     •     %d / 4 PUSHES" % rules.pushes
	var value := rules.cue_value()
	var low := 0.38
	var high := 0.62
	var meter := true
	match rules.stage:
		PodEscapeRules.Stage.SNAP, PodEscapeRules.Stage.SPLIT:
			title = "Break the stem" if rules.stage == PodEscapeRules.Stage.SNAP else "Split the seam"
			instruction = "Hold SPACE / Jump; release in the gold zone"
			progress = "02 / TAKE THE LEAP" if rules.stage == PodEscapeRules.Stage.SNAP else "03 / YOUR FIRST TASTE OF FREEDOM"
			value = rules.charge / 1.2
			low = PodEscapeRules.CHARGE_MIN / 1.2
			high = PodEscapeRules.CHARGE_MAX / 1.2
		PodEscapeRules.Stage.FALL:
			title = "Down we go!"
			instruction = "The nursery soil is waiting below."
			meter = false
		PodEscapeRules.Stage.REVEAL:
			title = "Small bean. Big world."
			instruction = "Quest complete / Welcome to Fufufarm"
			progress = "THE ADVENTURE BEGINS"
			meter = false
	display.show_step(title, instruction, rules.feedback, progress, value, low, high, meter)

func _finish() -> void:
	active = false
	camera.offset = _wide_offset
	player.velocity = Vector3.ZERO
	player.visuals.jump_animation.reset()
	player.get_node("GroundShadow").visible = true
	player.set_physics_process(true)
	display.queue_free()
	completed.emit()

func capture_state() -> Dictionary:
	return {"active": active, "stage": int(rules.stage), "elapsed": rules.elapsed, "beat": rules.beat,
		"pushes": rules.pushes, "direction": rules.direction, "charge": rules.charge,
		"last_direction": rules._last_direction, "held": rules._held,
		"escape_start": [_escape_start.x, _escape_start.y, _escape_start.z], "feedback": rules.feedback}

func apply_state(state: Dictionary) -> void:
	if not state.active:
		if active: _finish()
		plant.present(0, 1, 1)
		return
	rules.stage = int(state.stage) as PodEscapeRules.Stage
	for field in ["elapsed", "beat", "charge"]: rules.set(field, state[field])
	rules.pushes = int(state.pushes)
	rules.direction = int(state.direction)
	rules._last_direction = int(state.last_direction)
	rules._held = state.held
	rules.feedback = state.feedback
	_escape_start = Vector3(state.escape_start[0], state.escape_start[1], state.escape_start[2])
	_present(0.0)

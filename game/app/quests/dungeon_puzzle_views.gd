class_name DungeonPuzzleViews
extends Node
## Local presentation bridge. Host command handling remains outside this node.

signal command_requested(command: TofuPuzzleCommand)
signal view_closed

const INTERACTION_RANGE := 2.8
const CLOSE_OFFSET := Vector3(0.0, 1.6, 2.3)

var dungeon: TofuDungeon
var actor: Player
var camera: CameraFollow
var attempt: TofuDungeonAttempt
var health: Damageable
var terminal: DungeonTerminalView
var note: DungeonNoteView
var cutter: DungeonCutterView
var press_view: DungeonPressView
var _anchor: Node3D
var _active_view: String = ""
var _sequence: int = 0
var _old_target: Node3D
var _old_offset: Vector3
var _old_fov: float
var _old_first_person: bool
var _old_shoulder: bool
var _old_input_enabled: bool
var _old_mouse_mode: Input.MouseMode

func _ready() -> void:
	terminal = DungeonTerminalView.new()
	note = DungeonNoteView.new()
	cutter = DungeonCutterView.new()
	press_view = DungeonPressView.new()
	add_child(terminal)
	add_child(note)
	add_child(cutter)
	add_child(press_view)
	terminal.password_submitted.connect(_password)
	cutter.cuts_committed.connect(_cuts)
	press_view.action_requested.connect(_press_action)
	terminal.closed.connect(_view_dismissed)
	note.closed.connect(_view_dismissed)
	cutter.closed.connect(_view_dismissed)
	press_view.closed.connect(_view_dismissed)
	set_physics_process(false)

func configure(quest: TofuDungeon, local_actor: Player, view_camera: CameraFollow, puzzle: TofuDungeonAttempt, actor_health: Damageable) -> void:
	if health != null:
		if health.hit.is_connected(_on_hit): health.hit.disconnect(_on_hit)
		if health.depleted.is_connected(close): health.depleted.disconnect(close)
	dungeon = quest
	actor = local_actor
	camera = view_camera
	attempt = puzzle
	health = actor_health
	if health != null:
		health.hit.connect(_on_hit)
		health.depleted.connect(close)

func open_terminal(at: Node3D) -> bool:
	if not _can_open(at, TofuPuzzleContract.Stage.LAB): return false
	_begin("terminal", at)
	terminal.open()
	var command := _command(TofuPuzzleCommand.Action.OPEN_TERMINAL, TofuLabRules.TERMINAL_ID, "", attempt.lab.revision)
	command_requested.emit(command)
	return true

func open_note(at: Node3D) -> bool:
	if not _can_open(at, TofuPuzzleContract.Stage.LAB): return false
	_begin("note", at)
	note.open()
	var command := _command(TofuPuzzleCommand.Action.INSPECT, TofuLabRules.NOTE_ID, "", attempt.lab.revision)
	command_requested.emit(command)
	return true

func open_cutter(at: Node3D) -> bool:
	if not _can_open(at, TofuPuzzleContract.Stage.CUT): return false
	if attempt.cut.block_id.is_empty() or attempt.cut.length <= 0.0: return false
	_begin("cutter", at)
	cutter.open()
	return true

func open_press(at: Node3D, modern: bool) -> bool:
	if not _can_open(at, TofuPuzzleContract.Stage.PRESS): return false
	_begin("press", at)
	press_view.open(modern)
	return true

func close() -> void:
	if _active_view.is_empty(): return
	match _active_view:
		"terminal": terminal.close()
		"note": note.close()
		"cutter": cutter.close()
		"press": press_view.close()

func show_terminal_feedback(message: String, formula_text: String = "") -> void:
	if not formula_text.is_empty(): terminal.show_formula(formula_text)
	else: terminal.show_feedback(message)

func show_cutter_feedback(message: String) -> void:
	cutter.show_feedback(message)

func show_press_feedback(message: String) -> void:
	press_view.present(attempt.press.stones.size(), 0.0, 0.0, message)

func set_sequence_floor(last_accepted_sequence: int) -> void:
	_sequence = maxi(_sequence, last_accepted_sequence)

func _can_open(at: Node3D, required_stage: TofuPuzzleContract.Stage) -> bool:
	if not _active_view.is_empty() or dungeon == null or actor == null or camera == null or attempt == null or health == null: return false
	if not is_instance_valid(at) or not is_instance_valid(actor) or not is_instance_valid(camera): return false
	if health.current <= 0.0 or not dungeon.actor_in_run(actor): return false
	if attempt.stage != required_stage or attempt.phase != TofuPuzzleContract.Phase.READY: return false
	return actor.global_position.distance_to(at.global_position) <= INTERACTION_RANGE and dungeon.puzzle_runtime._visible(actor, at.global_position)

func _begin(kind: String, at: Node3D) -> void:
	DungeonTrialLifecycle.cancel_local_controls(dungeon)
	_active_view = kind
	_anchor = at
	_old_target = camera.target
	_old_offset = camera.offset
	_old_fov = camera.fov
	_old_first_person = camera.first_person
	_old_shoulder = camera.shoulder
	_old_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if actor.command_source is LocalPlayerInput:
		_old_input_enabled = actor.command_source.enabled
		actor.command_source.enabled = false
	camera.target = at
	camera.offset = CLOSE_OFFSET
	camera.first_person = false
	camera.shoulder = false
	camera.fov = 45.0
	set_physics_process(true)

func _view_dismissed() -> void:
	if _active_view.is_empty(): return
	_active_view = ""
	_anchor = null
	set_physics_process(false)
	if is_instance_valid(camera):
		camera.target = _old_target if is_instance_valid(_old_target) else actor
		camera.offset = _old_offset
		camera.fov = _old_fov
		camera.first_person = _old_first_person
		camera.shoulder = _old_shoulder
	if is_instance_valid(actor) and actor.command_source is LocalPlayerInput:
		actor.command_source.enabled = _old_input_enabled
	Input.mouse_mode = _old_mouse_mode
	view_closed.emit()

func _physics_process(_delta: float) -> void:
	DungeonPuzzleViewLifecycle.step(self)

func _on_hit(_amount: float, _direction: Vector3) -> void:
	close()

func _password(raw_text: String) -> void:
	if _active_view != "terminal" or attempt == null: return
	var command := _command(TofuPuzzleCommand.Action.SUBMIT_PASSWORD, TofuLabRules.TERMINAL_ID, "", attempt.lab.revision)
	command.text = raw_text
	command_requested.emit(command)

func _cuts(positions: PackedFloat32Array) -> void:
	if _active_view != "cutter" or attempt == null: return
	var command := _command(TofuPuzzleCommand.Action.COMMIT_CUTS, "cutter", attempt.cut.block_id, attempt.cut.revision)
	for position: float in positions:
		command.cuts.append(position * attempt.cut.length)
	command_requested.emit(command)

func _press_action(action_name: String, object_id: String) -> void:
	if _active_view != "press" or attempt == null: return
	var command: TofuPuzzleCommand = DungeonPressAdapter.command(self, action_name, object_id)
	if command != null: command_requested.emit(command)

func _command(action: TofuPuzzleCommand.Action, target_id: String, object_id: String, revision: int) -> TofuPuzzleCommand:
	_sequence += 1
	var result := TofuPuzzleCommand.new()
	result.action = action
	result.target_id = target_id
	result.object_id = object_id
	result.run_id = attempt.run_id
	result.attempt_id = attempt.attempt_id
	result.sequence = _sequence
	result.expected_revision = revision
	return result

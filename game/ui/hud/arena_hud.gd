class_name ArenaHUD
extends Control
## Centered arena display, loadout consent and deliberate two-click surrender.

signal action_requested(action: String, ranged: String, melee: String)
var scorecard: ArenaScorecard
var setup: ArenaLoadoutPanel
var leave_button: Button
var _confirm_until: float = 0.0
var _phase: String = "idle"
var _match: int = -1
var _participant: bool = false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	scorecard = ArenaScorecard.new()
	add_child(scorecard)
	scorecard.set_anchors_preset(Control.PRESET_CENTER_TOP)
	scorecard.offset_left = -260
	scorecard.offset_right = 260
	scorecard.offset_top = 12
	scorecard.offset_bottom = 120
	leave_button = MenuStyle.button(self, "SURRENDER", _leave)
	leave_button.set_anchors_preset(Control.PRESET_CENTER_TOP)
	leave_button.offset_left = 76
	leave_button.offset_right = 260
	leave_button.offset_top = 128
	leave_button.offset_bottom = 164
	MenuStyle.fit_button(leave_button, true)
	setup = ArenaLoadoutPanel.new()
	add_child(setup)
	setup.set_anchors_preset(Control.PRESET_CENTER)
	setup.offset_left = -250
	setup.offset_right = 250
	setup.offset_top = -184
	setup.offset_bottom = 244
	setup.accepted.connect(func(ranged: String, melee: String) -> void: action_requested.emit("accept", ranged, melee))
	hide()

func present(data: Dictionary) -> void:
	_phase = str(data.get("phase", "idle"))
	visible = _phase != "idle"
	if not visible: return
	_participant = bool(data.get("participant", false))
	var match_id := int(data.get("match", 0))
	if match_id != _match:
		_match = match_id
		_confirm_until = 0.0
	var fighter_names: Array[String] = []
	fighter_names.assign(data.get("names", ["Fufu", "Fufu"]))
	var points: Array[int] = []
	points.assign(data.get("scores", [0, 0]))
	scorecard.present(fighter_names, points, str(data.get("status", "")), int(data.get("winner_index", -1)))
	setup.visible = _phase == "loadout" and _participant
	if setup.visible: setup.present(_match, data.get("choice", {}), str(data.get("readiness", "")))
	leave_button.visible = _participant and _phase in ["loadout", "entry", "fight", "round"]
	_refresh_leave()

func _process(_delta: float) -> void:
	if _confirm_until > 0.0 and Time.get_ticks_msec() * 0.001 > _confirm_until:
		_confirm_until = 0.0
		_refresh_leave()

func _refresh_leave() -> void:
	var early := _phase in ["loadout", "entry"]
	leave_button.text = "CONFIRM SURRENDER" if _confirm_until > 0.0 else ("LEAVE SETUP" if early else "SURRENDER [F8]")

func _leave() -> void:
	if _phase in ["fight", "round"] and _confirm_until == 0.0:
		_confirm_until = Time.get_ticks_msec() * 0.001 + 3.0
		_refresh_leave()
		return
	_confirm_until = 0.0
	action_requested.emit("leave", "soy_gun", "")
	leave_button.release_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not _participant or _phase not in ["fight", "round"]: return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F8:
		_leave()
		get_viewport().set_input_as_handled()

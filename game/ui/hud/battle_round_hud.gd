class_name BattleRoundHUD
extends Control
## Small objective medallions and brief combat confirmation; detailed recap is optional.
signal results_requested
var results_button: Button
var progress: Array = []
var _hit: float = 0
var damage_flash: BattleDamageFlash
var _kill: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	results_button = MenuStyle.button(self, "Match results", results_requested.emit)
	results_button.hide()
	resized.connect(_fit)
	_fit()

func _fit() -> void:
	results_button.position = Vector2(12, size.y - (170 if size.x < 900 else 186))
	results_button.size = Vector2(150, 32)

func display_objectives(values: Array) -> void:
	progress = values
	queue_redraw()

func feedback(hit: bool, hurt: bool, kill: bool) -> void:
	if hit: _hit = 0.28; _kill = kill
	if hurt: damage_flash.hurt()
	queue_redraw()

func _process(delta: float) -> void:
	if _hit <= 0: return
	_hit = maxf(0, _hit - delta)
	queue_redraw()

func _draw() -> void:
	for i in mini(3, progress.size()):
		var at := Vector2(size.x * 0.38 - 42 + i * 34, size.y - 35)
		var ratio := clampf(float(progress[i]) / [3, 100, 90][i], 0, 1)
		draw_circle(at, 14, BattleHUDIcons.INK)
		draw_arc(at, 14, -PI / 2, -PI / 2 + TAU * ratio, 24, Color("8eebc2") if ratio >= 1 else Color("edbd66"), 2, true)
		BattleHUDIcons.icon(self, [BattleHUDIcons.CHEST, BattleHUDIcons.KO, BattleHUDIcons.CLOCK][i], at - Vector2.ONE * 9, 18)
	if _hit > 0:
		var at := size * 0.5 if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else get_local_mouse_position()
		var color := Color("f4c75d") if _kill else Color.WHITE
		color.a = _hit / 0.28
		for direction: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			draw_line(at + direction * 8, at + direction * 15, color, 2, true)

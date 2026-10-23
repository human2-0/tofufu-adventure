class_name BattleXPProgress
extends VBoxContainer
## Cosmetic total-XP animation crosses level thresholds without banking rewards.
var level_label: Label
var gain_label: Label
var fraction: Label
var celebration: Label
var bar: ProgressBar
var _stamp: String = ""
var _start_level: int = 1
var _tween: Tween
var shown_xp: float = 0:
	set(value):
		shown_xp = value
		if is_node_ready(): _render()

func _ready() -> void:
	add_theme_constant_override("separation", 4)
	var row := HBoxContainer.new()
	add_child(row)
	level_label = MenuStyle.label(row, "", 22, MenuStyle.MINT)
	level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gain_label = MenuStyle.label(row, "", 22, MenuStyle.SOY_GOLD)
	gain_label.custom_minimum_size.x = 100
	gain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	bar = ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size.y = 18
	var background := MenuStyle.panel(Color("0e2929"), 5)
	var fill := MenuStyle.panel(MenuStyle.LEAF, 5)
	background.set_content_margin_all(0)
	fill.set_content_margin_all(0)
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	add_child(bar)
	fraction = MenuStyle.label(self, "", 13, MenuStyle.MUTED)
	celebration = MenuStyle.label(self, "", 14, MenuStyle.SOY_GOLD)
	for label in [level_label, gain_label, fraction, celebration]:
		label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	for label in [fraction, celebration]: label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func display(before: int, earned: int) -> void:
	var stamp := "%s:%d:%d" % [TranslationServer.get_locale(), before, earned]
	if stamp == _stamp: return
	_stamp = stamp
	if is_instance_valid(_tween): _tween.kill()
	_start_level = _level(before)
	shown_xp = before
	gain_label.text = "+%d XP" % earned
	_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "shown_xp", float(mini(100000000, before + earned)), 1.8)

func _level(total: int) -> int:
	return 1 + floori(sqrt(float(total) / 100.0))

func _render() -> void:
	var total := roundi(shown_xp)
	var level := _level(total)
	var lower := (level - 1) * (level - 1) * 100
	var needed := level * level * 100 - lower
	level_label.text = tr("ROYALE LEVEL %d") % level
	bar.max_value = needed
	bar.value = total - lower
	fraction.text = tr("%d / %d XP to level %d") % [total - lower, needed, level + 1]
	celebration.text = tr("LEVEL UP! %d → %d") % [_start_level, level] if level > _start_level else tr("Cosmetic career · Match equipment resets")

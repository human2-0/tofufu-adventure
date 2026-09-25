class_name HUD
extends CanvasLayer
## Minimalist kawaii HUD: edge-aligned translucent panels, skill slot, and delayed jump bar.

var dash_bar: ProgressBar
var dash_status: Label
var _dash_slot: DashSlot
var _jump_meter: JumpMeter
var _jump_bar: ProgressBar
signal stat_point_allocated(skill_name: String)

var _jump_text: Label
var _jump_val: float = 0.0

var _health_bar: ProgressBar
var _health_text: Label
var _charge_bar: ProgressBar
var _charge_text: Label
var _equipment: Label
var _session: Label
var _clock: Label
var _character: CharacterStats
var _stats: Label
var _notice: Label
var _help: PanelContainer
var _popup: KawaiiPopup
var _soy_hit: SoyHitFlash
var _smear: SnailSmear
var _healing_label: Label

var _notice_time: float = 0.0
var _sites: int = 0
var _beans: int = 0
var _mobs: int = 0
var _props: int = 0
var _experience: int = 0
var _knife_selected: bool = true
var _staff_selected: bool = false
var _tornado_active: bool = false
var _tornado_cooldown: float = 0.0
var _guarding: bool = false
var _fist_hit_rate: float = 2.9
var _fist_damage: int = 12
var _knife_charge: float = 0.0
var _combo_count: int = 0
var _combo_critical_chance: float = 0.0
var _prev_level: int = 1
var _prev_skills: Dictionary = {}

func _ready() -> void:
	var canvas := Control.new()
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(canvas)
	_smear = SnailSmear.new()
	canvas.add_child(_smear)
	_soy_hit = SoyHitFlash.new()
	canvas.add_child(_soy_hit)

	var heading := HUDElements.make_panel(canvas, Vector2(16, 16), Vector2(210, 58), Vector2(0, 0))
	HUDElements.make_label(heading, "TOFUFU / FUFUFARM", 13, Color("f5dfac"))
	_session = HUDElements.make_label(heading, "Chapter 01 · Tab for guide", 11, Color("baccc0"))
	_clock = HUDElements.make_label(heading, "", 11, Color("b8d7dd"))

	var ledger := HUDElements.make_panel(canvas, Vector2(-232, 16), Vector2(216, 235), Vector2(1, 0))
	_stats = HUDElements.make_label(ledger, "", 10, Color("d8e3d2"))
	_character = CharacterStats.new()
	_character.stat_point_allocated.connect(func(k: String) -> void: stat_point_allocated.emit(k))
	ledger.add_child(_character)

	var health := HUDElements.make_panel(canvas, Vector2(16, -96), Vector2(210, 82), Vector2(0, 1))
	_health_text = HUDElements.make_label(health, "FUFU / 100 HP", 12, Color("dbe8c1"))
	_health_bar = HUDElements.make_bar(health, Color("a3cc86"), 170, 7)
	_equipment = HUDElements.make_label(health, "[1] KNIFE   2 FISTS   3 GUN", 11, Color("aee6d0"))
	_healing_label = HUDElements.make_label(health, "", 10, Color("c8efa0"))
	_healing_label.visible = false

	var charge := HUDElements.make_panel(canvas, Vector2(-206, -58), Vector2(190, 42), Vector2(1, 1))
	_charge_text = HUDElements.make_label(charge, "HOLD LMB / CHARGE", 11, Color("f5dfac"))
	_charge_bar = HUDElements.make_bar(charge, Color("efc477"), 170, 6)

	_setup_center(canvas)
	show_progress(0, 0, 0)

func _setup_center(canvas: Control) -> void:
	_jump_meter = JumpMeter.new()
	canvas.add_child(_jump_meter)
	_jump_meter.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_jump_meter.offset_left = -85
	_jump_meter.offset_right = 85
	_jump_meter.offset_top = -98
	_jump_meter.offset_bottom = -72
	_jump_bar = _jump_meter.jump_bar
	_jump_text = _jump_meter.jump_text

	_dash_slot = DashSlot.new()
	canvas.add_child(_dash_slot)
	_dash_slot.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_dash_slot.offset_left = -26
	_dash_slot.offset_right = 26
	_dash_slot.offset_top = -68
	_dash_slot.offset_bottom = -16
	dash_bar = _dash_slot.dash_bar
	dash_status = _dash_slot.dash_status

	_popup = KawaiiPopup.new()
	canvas.add_child(_popup)
	_popup.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_popup.offset_left = -150
	_popup.offset_right = 150
	_popup.offset_top = 40
	_popup.offset_bottom = 110

	var help_box := HUDElements.make_panel(canvas, Vector2(-180, 110), Vector2(360, 220), Vector2(0.5, 0))
	_help = help_box.get_parent() as PanelContainer
	HUDElements.make_label(help_box, "FUFU ADVENTURE GUIDE", 13, Color("f5dfac"))
	HUDElements.make_label(help_box, "WASD: Walk • Mouse: Aim • Space: Leap • Shift: Dash / hold 0.66s for Super Dash • LMB: Tap combo / hold power\nRMB: Knife guard / Staff tornado spin. Staff Lv1 Power 5; Knife Lv2 Power 10.\nSuper Dash lasts twice as long, passes through actors and leaves a light-damage fart cloud.\nMelee: attack mid-air for a diving slash. Hit, then fast tap to stab; hold the next combo hit to launch foes.\nAccurate hits briefly raise critical chance. 1/2: Combat slots • I / B: Inventory & EQ • 3–6: Support slots\nQ: Drop held weapon • E: Pick up highlighted item • Tab: Guide • C: Camera • Enter: Chat • V: Voice", 10, Color("d1ddd0"))
	_help.visible = false

	_notice = Label.new()
	_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notice.add_theme_font_size_override("font_size", 13)
	_notice.add_theme_color_override("font_color", Color("fff0c2"))
	canvas.add_child(_notice)
	_notice.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_notice.offset_left = -250
	_notice.offset_right = 250
	_notice.offset_top = 118
	_notice.offset_bottom = 146

func _process(delta: float) -> void:
	_notice_time = maxf(0.0, _notice_time - delta)
	_notice.modulate.a = minf(1.0, _notice_time)
	if _jump_meter != null: _jump_meter.update_charge(_jump_val, delta)

func show_health(current: float, maximum: float) -> void:
	_health_bar.value = current / maximum * 100.0
	_health_text.text = "FUFU / %d HP" % int(current)

func show_snail_hit() -> void:
	_smear.splash()

func show_dash_cooldown(current: float, total: float) -> void:
	_dash_slot.set_cooldown(current, total)

func show_punch_cadence(remaining: float, total: float, damage: int, hit_rate: float) -> void:
	_fist_damage = damage
	_fist_hit_rate = hit_rate
	if not _knife_selected and not _staff_selected:
		var progress := 1.0 if total <= 0.0 else clampf(1.0 - remaining / total, 0.0, 1.0)
		_charge_bar.value = progress * 100.0
		_charge_text.text = ("PUNCHING · %d DMG" if remaining > 0.001 else "LMB / PUNCH · %d DMG") % damage

func show_charge(value: float) -> void:
	_knife_charge = value
	if _knife_selected:
		_present_knife_rhythm()
	elif _staff_selected:
		_present_staff_rhythm()
	else:
		_charge_text.text = "LMB / PUNCH · %d DMG" % _fist_damage

func show_combo(count: int, critical_chance: float) -> void:
	_combo_count = count
	_combo_critical_chance = critical_chance
	if _knife_selected:
		_present_knife_rhythm()
	elif _staff_selected:
		_present_staff_rhythm()

func show_staff_state(selected: bool, tornado: bool, cooldown: float) -> void:
	_staff_selected = selected
	_tornado_active = tornado
	_tornado_cooldown = cooldown
	if selected: _present_staff_rhythm()

func _present_staff_rhythm() -> void:
	_charge_bar.value = _knife_charge * 100.0
	if _tornado_active:
		_charge_text.text = "TORNADO / 360° SWING"
	elif _knife_charge >= 1.0:
		_charge_text.text = "STAFF LOADED / RELEASE"
	elif _knife_charge > 0.0:
		_charge_text.text = "STAFF CHARGING %d%%" % roundi(_knife_charge * 100.0)
	elif _tornado_cooldown > 0.05:
		_charge_text.text = "STAFF / SPIN %.1fs" % _tornado_cooldown
	elif _combo_count > 0:
		_charge_text.text = "STAFF COMBO x%d / RMB SPIN" % _combo_count
	else:
		_charge_text.text = "STAFF / LMB COMBO · RMB SPIN"

func _present_knife_rhythm() -> void:
	_charge_bar.value = _knife_charge * 100.0
	if _guarding:
		_charge_text.text = "GUARDING / AIM AT FOE"
	elif _combo_count > 0 and _knife_charge >= 1.0:
		_charge_text.text = "COMBO LAUNCHER! / RELEASE"
	elif _knife_charge >= 1.0:
		_charge_text.text = "POWER SLASH! / RELEASE"
	elif _combo_count > 0:
		var hint := "RELEASE STAB" if _knife_charge > 0.0 else "TAP LMB FOR STAB"
		_charge_text.text = "COMBO x%d · %d%% CRIT / %s" % [_combo_count, roundi(_combo_critical_chance * 100.0), hint]
	else:
		_charge_text.text = "HOLD LMB / CHARGE"

func show_jump_charge(value: float) -> void: _jump_val = value

func show_time(hour: float, daylight: float) -> void:
	_clock.text = "%02d:%02d · %s" % [int(hour), int(fmod(hour, 1.0) * 60), "Daylight" if daylight > 0.5 else "Fireflies"]

func show_progress(beans: int, mobs: int, props: int) -> void:
	_beans = beans
	_mobs = mobs
	_props = props
	_stats.text = "%d beans · %d snails · %d broken\n%d of 4 places · %d EXP" % [beans, mobs, props, _sites, _experience]

func show_discovery(title: String, count: int) -> void:
	_sites = count
	show_progress(_beans, _mobs, _props)
	announce("Discovered / " + title)

func announce(text: String) -> void:
	_notice.text = text
	_notice_time = 4.0

func toggle_help() -> void: _help.visible = not _help.visible

func show_equipment(owned: bool, selected: bool, guarding: bool) -> void:
	_knife_selected = owned and selected
	_guarding = guarding
	var knife := "KNIFE" if owned else "EMPTY"
	var fists_str := "2 FISTS (%d DMG)" % _fist_damage
	_equipment.text = ("[1 %s]  %s" % [knife, fists_str]) if selected else ("1 %s  [%s]" % [knife, fists_str])
	if guarding: _equipment.text = "[1 KNIFE: GUARD]"
	if _knife_selected: _present_knife_rhythm()

func show_experience(total: int) -> void:
	_experience = total
	show_progress(_beans, _mobs, _props)

func show_session(text: String) -> void:
	_session.text = text

func show_character(data: Dictionary) -> void:
	_character.present(data)
	var new_lvl: int = int(data.get("level", 1))
	if _prev_skills.is_empty():
		_prev_level = new_lvl
		for k: String in data.skills: _prev_skills[k] = int(data.skills[k].level)
		return
	if new_lvl > _prev_level: _popup.celebrate_level(new_lvl)
	_prev_level = new_lvl
	for k: String in data.skills:
		var skl_lvl: int = int(data.skills[k].level)
		if skl_lvl > int(_prev_skills.get(k, skl_lvl)): _popup.celebrate_skill(k, skl_lvl)
		_prev_skills[k] = skl_lvl

func show_gun(selected: bool, precise: bool) -> void:
	if selected:
		_equipment.text = "1 KNIFE  2 FISTS  [3 GUN]  4 JET"
		_charge_bar.value = 100 if precise else 25
		_charge_text.text = "AIM · 20 / HEAD 40" if precise else "HIP FIRE · HOLD RMB TO AIM"
	elif "3 GUN" not in _equipment.text:
		_equipment.text += "  3 GUN  4 JET"

func show_damage_hit(kind: int) -> void:
	if kind == 1: show_snail_hit()
	elif kind == 2: _soy_hit.splash()

func show_sotjet(selected: bool, reservoir: float) -> void:
	if not selected: return
	_equipment.text = "[4] SOTJET · SOYMILK"
	_charge_bar.value = reservoir * 100.0
	_charge_text.text = "MILK %d%% · RELEASE TO REFILL" % roundi(reservoir * 100.0)

func show_healing_slot(item_name: String, count: int, cd: float = 0.0) -> void:
	if _healing_label == null: return
	if count > 0:
		_healing_label.text = ("[3] %s x%d (%.1fs cd)" % [item_name, count, cd]) if cd > 0.05 else ("[3] %s x%d" % [item_name, count])
		_healing_label.modulate = Color("ffb0a0") if cd > 0.05 else Color("c8efa0")
		_healing_label.visible = true
	else:
		_healing_label.visible = false

func show_loadout(first: String, second: String, selected: int) -> void:
	_equipment.text = ("[1 %s]  2 %s" if selected == 1 else "1 %s  [2 %s]") % [first, second]

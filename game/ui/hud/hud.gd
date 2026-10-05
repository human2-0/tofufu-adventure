class_name HUD
extends CanvasLayer
## Minimalist kawaii HUD: edge-aligned translucent panels, skill slot, and delayed jump bar.

var dash_bar: ProgressBar
var dash_status: Label
var _dash_slot: DashSlot
var _jump_meter: JumpMeter
var _jump_bar: ProgressBar
var _run_meter: RunMeter
var _sp_available: float = 100.0
signal stat_point_allocated(skill_name: String)

var _jump_text: Label
var _jump_val: float = 0.0

var _stamina_bar: ProgressBar
var _stamina_text: Label
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
var _ledger: PanelContainer
var _help_before_inventory: bool = false
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
	HUDLayout.ready(self)

func _process(delta: float) -> void:
	_notice_time = maxf(0.0, _notice_time - delta)
	_notice.modulate.a = minf(1.0, _notice_time)
	if _jump_meter != null: _jump_meter.update_charge(_jump_val, delta)

func show_health(current: float, maximum: float) -> void:
	_health_bar.value = current / maximum * 100.0
	_health_text.text = "%d / %d HP" % [ceili(current), ceili(maximum)]

func show_stamina(current: float, maximum: float, combat_seconds: float) -> void:
	_sp_available = current
	_stamina_bar.value = current / maximum * 100.0
	_stamina_text.text = "%d / %d SP · %s" % [ceili(current), ceili(maximum), "COMBAT %ds" % ceili(combat_seconds) if combat_seconds > 0.0 else "REST"]

func show_run_stamina(current: float, maximum: float, exhausted: bool) -> void:
	_run_meter.present(current, maximum, exhausted)

func show_snail_hit() -> void:
	_smear.splash()

func show_dash_cooldown(current: float, total: float) -> void:
	_dash_slot.set_cooldown(current, total)

func show_punch_cadence(remaining: float, total: float, damage: int, hit_rate: float) -> void:
	HUDCombatView.show_punch_cadence(self, remaining, total, damage, hit_rate)

func show_charge(value: float) -> void:
	HUDCombatView.show_charge(self, value)

func show_combo(count: int, critical_chance: float) -> void:
	HUDCombatView.show_combo(self, count, critical_chance)

func show_staff_state(selected: bool, tornado: bool, cooldown: float) -> void:
	HUDCombatView.show_staff_state(self, selected, tornado, cooldown)

func show_nori_state(selected: bool, plunging: bool, cooldown: float) -> void:
	HUDCombatView.show_nori_state(self, selected, plunging, cooldown)

func show_pod_state(selected: bool, cooldown: float) -> void:
	HUDCombatView.show_pod_state(self, selected, cooldown)

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

func set_inventory_open(active: bool) -> void:
	_ledger.visible = not active
	_notice.visible = not active
	if active:
		_help_before_inventory = _help.visible
		_help.hide()
	else:
		_help.visible = _help_before_inventory

func toggle_help() -> void: _help.visible = not _help.visible

func show_equipment(owned: bool, selected: bool, guarding: bool) -> void:
	HUDCombatView.show_equipment(self, owned, selected, guarding)

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
	HUDCombatView.show_gun(self, selected, precise)

func show_gun_status(magazine: int, reload_seconds: float, charge_seconds: float, visible: bool) -> void:
	if visible: HUDCombatView.show_gun_status(self, magazine, reload_seconds, charge_seconds)

func show_damage_hit(kind: int) -> void:
	if kind == 1: show_snail_hit()
	elif kind == 2: _soy_hit.splash()

func show_sotjet(selected: bool, reservoir: float) -> void:
	HUDCombatView.show_sotjet(self, selected, reservoir)

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

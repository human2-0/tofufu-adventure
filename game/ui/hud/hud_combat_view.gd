class_name HUDCombatView
extends RefCounted
## Formats combat readouts without deciding gameplay outcomes.

static func show_punch_cadence(hud: HUD, remaining: float, total: float, damage: int, hit_rate: float) -> void:
	hud._fist_damage = damage
	hud._fist_hit_rate = hit_rate
	if not hud._knife_selected and not hud._staff_selected:
		var progress := 1.0 if total <= 0.0 else clampf(1.0 - remaining / total, 0.0, 1.0)
		hud._charge_bar.value = progress * 100.0
		hud._charge_text.text = ("PUNCHING · %d DMG" if remaining > 0.001 else "LMB / PUNCH · %d DMG") % damage

static func show_charge(hud: HUD, value: float) -> void:
	hud._knife_charge = value
	if hud._knife_selected:
		present_knife_rhythm(hud)
	elif hud._staff_selected:
		present_staff_rhythm(hud)
	else:
		hud._charge_text.text = "LMB / PUNCH · %d DMG" % hud._fist_damage

static func show_combo(hud: HUD, count: int, critical_chance: float) -> void:
	hud._combo_count = count
	hud._combo_critical_chance = critical_chance
	if hud._knife_selected:
		present_knife_rhythm(hud)
	elif hud._staff_selected:
		present_staff_rhythm(hud)

static func show_staff_state(hud: HUD, selected: bool, tornado: bool, cooldown: float) -> void:
	hud._staff_selected = selected
	hud._tornado_active = tornado
	hud._tornado_cooldown = cooldown
	if selected: present_staff_rhythm(hud)

static func show_nori_state(hud: HUD, selected: bool, plunging: bool, cooldown: float) -> void:
	if not selected: return
	present_knife_rhythm(hud)
	hud._charge_text.text += " · NORI +10% SPEED · "
	hud._charge_text.text += "MOVE TO AIM / RELEASE RMB TO DIVE" if plunging else ("PLUNGE %.1fs" % cooldown if cooldown > 0.05 else "RMB PLUNGE 75 SP / 3× HIT")

static func show_pod_state(hud: HUD, selected: bool, cooldown: float) -> void:
	if not selected: return
	present_knife_rhythm(hud)
	hud._charge_text.text += " · PODBURST %.1fs" % cooldown if cooldown > 0.05 else " · RMB CRESCENT 25 SP"

static func present_staff_rhythm(hud: HUD) -> void:
	hud._charge_bar.value = hud._knife_charge * 100.0
	if hud._tornado_active:
		hud._charge_text.text = "TORNADO / 360° SWING"
	elif hud._knife_charge >= 1.0:
		hud._charge_text.text = "STAFF LOADED / RELEASE"
	elif hud._knife_charge > 0.0:
		hud._charge_text.text = "STAFF CHARGING %d%%" % roundi(hud._knife_charge * 100.0)
	elif hud._tornado_cooldown > 0.05:
		hud._charge_text.text = "STAFF / SPIN %.1fs" % hud._tornado_cooldown
	elif hud._combo_count > 0:
		hud._charge_text.text = "STAFF COMBO x%d / RMB SPIN" % hud._combo_count
	else:
		hud._charge_text.text = "STAFF / LMB · RMB SPIN 25 SP"

static func present_knife_rhythm(hud: HUD) -> void:
	hud._charge_bar.value = hud._knife_charge * 100.0
	if hud._guarding:
		hud._charge_text.text = "GUARDING / AIM AT FOE"
	elif hud._combo_count > 0 and hud._knife_charge >= 1.0:
		hud._charge_text.text = "LAUNCHER · 25 SP / RELEASE" if hud._sp_available >= 25.0 else "NEED 25 SP / RELEASE TO CANCEL"
	elif hud._knife_charge >= 1.0:
		hud._charge_text.text = "POWER SLASH · 25 SP / RELEASE" if hud._sp_available >= 25.0 else "NEED 25 SP / RELEASE TO CANCEL"
	elif hud._combo_count > 0:
		var hint := "RELEASE STAB" if hud._knife_charge > 0.0 else "TAP LMB FOR STAB"
		hud._charge_text.text = "COMBO x%d · %d%% CRIT / %s" % [hud._combo_count, roundi(hud._combo_critical_chance * 100.0), hint]
	else:
		hud._charge_text.text = "HOLD LMB / CHARGE"

static func show_equipment(hud: HUD, owned: bool, selected: bool, guarding: bool) -> void:
	hud._knife_selected = owned and selected
	hud._guarding = guarding
	var knife := "KNIFE" if owned else "EMPTY"
	var fists_str := "2 FISTS (%d DMG)" % hud._fist_damage
	hud._equipment.text = ("[1 %s]  %s" % [knife, fists_str]) if selected else ("1 %s  [%s]" % [knife, fists_str])
	if guarding: hud._equipment.text = "[1 KNIFE: GUARD]"
	if hud._knife_selected: present_knife_rhythm(hud)

static func show_gun(hud: HUD, selected: bool, precise: bool) -> void:
	if selected:
		hud._equipment.text = "1 KNIFE  2 FISTS  [3 GUN]  4 JET"
		hud._charge_bar.value = 100 if precise else 25
		hud._charge_text.text = "GUN · 9 SHOTS · HOLD LMB 2s / RICOCHET"
	elif "3 GUN" not in hud._equipment.text:
		hud._equipment.text += "  3 GUN  4 JET"

static func show_gun_status(hud: HUD, magazine: int, reload_seconds: float, charge_seconds: float) -> void:
	if reload_seconds > 0.0:
		hud._charge_bar.value = clampf(1.0 - reload_seconds / 2.0, 0.0, 1.0) * 100.0
		hud._charge_text.text = "RELOADING · %.1fs · %d / 9" % [reload_seconds, magazine]
		return
	var charge := clampf(charge_seconds / 2.0, 0.0, 1.0)
	hud._charge_bar.value = charge * 100.0 if charge > 0 else 100.0
	hud._charge_text.text = "GUN · %d / 9 · RICOCHET READY" % magazine if charge >= 1.0 else "GUN · %d / 9 · HOLD LMB 2s / RICOCHET" % magazine

static func show_sotjet(hud: HUD, selected: bool, reservoir: float) -> void:
	if not selected: return
	hud._equipment.text = "[4] SOTJET · SOYMILK"
	hud._charge_bar.value = reservoir * 100.0
	hud._charge_text.text = "MILK %d%% · RELEASE TO REFILL" % roundi(reservoir * 100.0)

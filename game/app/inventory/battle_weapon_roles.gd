class_name BattleWeaponRoles
extends RefCounted
## Match-specific advantages shown beside the original adventure controls.
const TEXT := {
	"knife": "Common · Fast, dependable melee combos and projectile reflection with guard.",
	"soy_gun": "Common · Reliable automatic fire: 18 body damage, nine shots, 90m range. Reload and headshots keep it competitive.",
	"edamame_sword": "Rare · Heavy hits, slower swings. Podburst pushes nearby enemies away.",
	"nori_katana": "Rare · Fast, long-reaching combos and a powerful aerial plunge.",
	"sproutwood_staff": "Rare · Strong, deliberate sweeps. Tornado controls nearby enemies.",
	"bengal_paws": "Rare · Quick, stronger fists. Mobility, cheaper dashes and Super Claw close the distance.",
	"sotjet": "Rare · Sustained pressure without magazine reloads; limited reach and a milk tank reward close combat.",
	"angel_bow": "Rare · Arrow damage +12%. Long-range precision and flame bursts; two-second reload between arrows.",
	"celestial_sword": "Legendary · Powerful, quick sword combos. Guard reflects incoming shots.",
	"celestial_staff": "Legendary · Heavy hits and faster sweeps than the rare staff, with tornado control.",
	"soy_raygun": "Legendary · Shot damage +22%, projectile speed and range +15%, fire rate -6%. Nine-shot magazine and reload still apply.",
}

static func text(id: String) -> String:
	var role: String = TEXT.get(id, "")
	if role.is_empty(): return ""
	var result := TranslationServer.translate(role)
	var kind := BattleBalance.ITEMS.find(id)
	if not BattleBalance.MELEE_POWER.has(kind): return result
	var paws := kind == 6
	var tuning := CombatTuning.new()
	var damage := (BengalClaws.DAMAGE if paws else tuning.light_damage) * float(BattleBalance.MELEE_POWER[kind])
	var duration := (BengalClaws.CADENCE if paws else tuning.swing_seconds) / float(BattleBalance.MELEE_RATE[kind])
	return result + "\n" + TranslationServer.translate("Base hit %.1f · Attack %.2fs") % [damage, duration]

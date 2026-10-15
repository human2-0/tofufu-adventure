class_name CharacterSheet
extends Control
## Character hub presents supplied values and emits allocation/navigation intents.

signal bag_requested
signal close_requested
signal stat_point_allocated(skill: String)
var bag_button: Button
var portrait: TextureRect
var heading: Label
var condition: Label
var experience: ProgressBar
var gear: Label
var points: Label
var stat_rows: Array[Dictionary] = []
var milestones: Array[Dictionary] = []
var skills: Dictionary = {}
var _last: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	CharacterSheetLayout.build(self)
	hide()

func present(data: Dictionary) -> void:
	_last = data
	portrait.texture = data.get("portrait")
	heading.text = tr("MY TOFUFU") + " · " + tr("Level %d") % data.level + "\n" + tr(str(data.title))
	condition.text = tr(str(data.condition))
	experience.value = data.level_percent
	experience.tooltip_text = tr("Maximum level") if data.level == 99 else tr("%d EXP to next level") % data.remaining
	gear.text = tr(str(data.gear))
	points.text = tr_n("%d point to invest", "%d points to invest", int(data.stat_points)) % data.stat_points
	for index in mini(stat_rows.size(), data.rows.size()):
		var row: Dictionary = data.rows[index]
		var view: Dictionary = stat_rows[index]
		view.title.text = tr(str(row.title))
		view.value.text = _num(row.total) + " " + tr(str(row.unit))
		view.bar.present(row)
		view.detail.text = tr("Base %s  ·  Training +%s  ·  Gear %s") % [_num(row.base), _num(row.training), ("+" if row.gear >= 0 else "") + _num(row.gear)]
	for index in mini(milestones.size(), data.journey.size()):
		var milestone: Dictionary = data.journey[index]
		var view: Dictionary = milestones[index]
		view.title.text = tr(str(milestone.name)) + "  " + str(milestone.rank) + "/5"
		view.bar.value = milestone.percent
		view.progress.text = tr("Mastered · Permanent bonus") if milestone.rank == 5 else "%d / %d %s" % [milestone.total, milestone.goal, tr(["metres", "confirmed hits", "HP restored"][index])]
	for key: String in skills:
		var info: Dictionary = data.skills[key]
		var view: Dictionary = skills[key]
		view.label.text = tr(view.title) + " " + str(info.level)
		view.bar.value = info.percent
		view.button.disabled = data.stat_points <= 0 or info.level >= 99 or key == "magic"

static func _num(value: float) -> String:
	return String.num(value, 2)

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and not _last.is_empty(): present(_last)

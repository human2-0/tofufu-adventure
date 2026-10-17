class_name CharacterSheet
extends Control
## Display-only character pages share mouse/controller explanations and intents. Helpers use the annotated signals/state.

@warning_ignore("unused_signal") signal bag_requested
@warning_ignore("unused_signal") signal close_requested
@warning_ignore("unused_signal") signal stat_point_allocated(skill: String)
var bag_button: Button
var portrait: TextureRect
var heading: Label
var condition: Label
var experience: ProgressBar
var experience_label: Label
var gear: Label
var points: Label
var footer: Label
var inspector_title: Label
var inspector_value: Label
var inspector_description: Label
var inspector_bar: CharacterStatBar
var inspector_sources: Array[Label] = []
var vitals: Array[Dictionary] = []
var stat_rows: Array[Dictionary] = []
var milestones: Array[Dictionary] = []
var skills: Dictionary = {}
var page_buttons: Array[Button] = []
var pages: Array[Control] = []
var selected_stat: int = 2
var _last: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	CharacterSheetLayout.build(self)
	hide()

func present(data: Dictionary) -> void:
	_last = data
	portrait.texture = data.get("portrait")
	heading.text = tr("MY TOFUFU") + " · " + tr("Level %d") % data.level + " · " + tr(str(data.title))
	condition.text = tr(str(data.condition))
	experience.value = data.level_percent
	experience_label.text = tr("Maximum level") if data.level == 99 else tr("Level progress · %d%% · %d EXP to next level") % [data.level_percent, data.remaining]
	gear.text = tr(str(data.gear).split("\n")[0])
	gear.tooltip_text = tr(str(data.gear))
	points.text = tr_n("%d point to invest", "%d points to invest", int(data.stat_points)) % data.stat_points
	footer.text = tr("%s · Inventory    %s · Player info    Esc / Pad B / ○ · Close    D-pad · Focus    A / ✕ · Choose") % [data.bag_binding, data.info_binding]
	for index in vitals.size():
		var current: float = data.current_health if index == 0 else data.current_stamina
		vitals[index].label.text = tr("Health · %s / %s") % [_num(current), _num(data.rows[0].total)] if index == 0 else tr("Stamina · %s / %s") % [_num(current), _num(data.rows[1].total)]
		vitals[index].bar.value = 100.0 * current / maxf(1.0, data.rows[index].total)
	for index in mini(stat_rows.size(), data.rows.size()):
		var row: Dictionary = data.rows[index]
		var view: Dictionary = stat_rows[index]
		view.title.text = tr(str(row.title))
		view.value.text = _num(row.total, _precise(index)) + " " + tr(str(row.unit))
		view.bar.present(row)
		view.button.set_pressed_no_signal(index == selected_stat)
	_present_training(data)
	inspect_stat(selected_stat)

func _present_training(data: Dictionary) -> void:
	for index in mini(milestones.size(), data.journey.size()):
		var milestone: Dictionary = data.journey[index]
		var view: Dictionary = milestones[index]
		view.title.text = tr(str(milestone.name)) + "  " + str(milestone.rank) + "/5"
		view.bar.value = milestone.percent
		view.progress.text = tr("Mastered · Permanent bonus") if milestone.rank == 5 else "%d / %d %s" % [milestone.total, milestone.goal, tr(["metres", "confirmed hits", "HP restored"][index])]
	for key: String in skills:
		var info: Dictionary = data.skills[key]
		var view: Dictionary = skills[key]
		view.label.text = tr(view.title) + " · " + tr("Rank %d") % info.level
		view.bar.value = info.percent
		view.practice.text = tr("Mastered") if info.level >= 99 else tr("Practice toward the next rank · %d%%") % info.percent
		view.benefit.text = tr(str(data.skill_benefits[key]))
		var capped: bool = info.level >= 99 or data.get("skill_caps", {}).get(key, false)
		view.button.disabled = data.stat_points <= 0 or capped or key == "magic"
		view.button.text = tr("MAX") if capped else "—" if key == "magic" else "+1"
		view.button.tooltip_text = tr("Invest 1 point") + "\n" + tr("Permanent choice · Rank %d → %d") % [info.level, mini(99, info.level + 1)] + "\n" + view.benefit.text

func inspect_stat(index: int) -> void:
	selected_stat = index
	if _last.is_empty(): return
	var row: Dictionary = _last.rows[index]
	inspector_title.text = tr(str(row.title))
	inspector_value.text = _num(row.total, _precise(index)) + " " + tr(str(row.unit))
	inspector_description.text = tr(str(row.description))
	inspector_bar.present(row)
	var amounts: Array = [row.base, row.training, row.gear]
	if not _precise(index):
		# Round cumulative contributions so their displayed sum matches the total.
		amounts = [ceili(row.base), ceili(row.base + row.training) - ceili(row.base), ceili(row.total) - ceili(row.base + row.training)]
	for source in 3:
		inspector_sources[source].text = ("+" if source > 0 and amounts[source] >= 0 else "") + _num(amounts[source], _precise(index)) + " " + tr(str(row.unit))
	inspector_sources[2].add_theme_color_override("font_color", CharacterStatBar.PENALTY if row.gear < 0 else CharacterStatBar.EQUIPMENT)
	for stat in stat_rows.size(): stat_rows[stat].button.set_pressed_no_signal(stat == index)

func select_page(index: int) -> void:
	for page in pages.size():
		pages[page].visible = page == index
		page_buttons[page].set_pressed_no_signal(page == index)
		page_buttons[page].focus_neighbor_bottom = page_buttons[page].get_path_to(stat_rows[0].button if page == 0 else skills.fist.card) if not stat_rows.is_empty() else NodePath()

static func _precise(index: int) -> bool:
	return index in [2, 3]

static func _num(value: float, precise: bool = false) -> String:
	return String.num(value, 2) if precise else str(ceili(value))

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and not _last.is_empty(): present(_last)

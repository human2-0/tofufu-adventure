class_name ArenaLoadoutPanel
extends PanelContainer
## Explicit consent and independent optional melee choice; no gameplay decisions.

signal accepted(ranged: String, melee: String)
const RANGED: Array[String] = ["soy_gun", "sotjet"]
const MELEE: Array[String] = ["", "knife", "edamame_sword", "nori_katana", "sproutwood_staff", "celestial_sword", "celestial_staff"]
var ranged: OptionButton
var melee: OptionButton
var readiness: Label
var accept_button: Button
var _match: int = -1
var _choice: Dictionary = {}

func _ready() -> void:
	add_theme_stylebox_override("panel", MenuStyle.panel(Color("17383bf5")))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	add_child(column)
	MenuStyle.label(column, "CHOOSE YOUR ARENA KIT", 22)
	MenuStyle.paragraph(column, "Both fighters must accept the same ranged weapon.\nMelee is your own optional choice. All weapons are match loans.")
	MenuStyle.label(column, "RANGED · agree with your opponent", 14, MenuStyle.SOY_GOLD)
	ranged = OptionButton.new()
	ranged.add_item("Soygun · soybean bullets")
	ranged.add_item("Soyjet · soymilk stream")
	ranged.custom_minimum_size.y = 40
	column.add_child(ranged)
	MenuStyle.label(column, "MELEE · combat slot 1 (optional)", 14, MenuStyle.MINT)
	melee = OptionButton.new()
	for title in ["None · fists", "Knife", "Edamame Pod Sword", "Nori Katana", "Sproutwood Staff", "Celestial Sword", "Celestial Staff"]:
		melee.add_item(title)
	melee.custom_minimum_size.y = 40
	melee.select(1)
	column.add_child(melee)
	readiness = MenuStyle.paragraph(column, "Waiting for both fighters…")
	accept_button = MenuStyle.button(column, "ACCEPT & READY", _accept)
	ranged.item_selected.connect(func(_index: int) -> void: _refresh_button())
	melee.item_selected.connect(func(_index: int) -> void: _refresh_button())
	MenuStyle.paragraph(column, "Equal HP / SP · first to 10 · projectiles travel at 2× speed\n1 / 2 switch weapons. F8 twice: surrender. Leave setup to decline.")

func present(match_id: int, choice: Dictionary, status: String) -> void:
	if _match != match_id:
		_match = match_id
		ranged.select(RANGED.find(str(choice.get("ranged", "soy_gun"))))
		melee.select(MELEE.find(str(choice.get("melee", "knife"))))
	_choice = choice
	readiness.text = status
	_refresh_button()

func _refresh_button() -> void:
	var accepted_choice: bool = _choice.get("ready", false) and _choice.get("ranged") == RANGED[ranged.selected] and _choice.get("melee") == MELEE[melee.selected]
	accept_button.disabled = accepted_choice
	accept_button.text = "READY · WAITING FOR AGREEMENT" if accepted_choice else "ACCEPT & READY"

func _accept() -> void:
	accepted.emit(RANGED[ranged.selected], MELEE[melee.selected])

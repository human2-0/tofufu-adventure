class_name TofuPuzzleClues
extends RefCounted
## Inspect text describes evidence without selecting a puzzle answer.

const BRIEFING: String = "Your task is to make tofu. Follow the factory recipe: choose the right beans, make soy milk, discover the coagulant, set the firmness, cut equal portions and pack your batch. Other production lines are still running—check what each machine actually makes."
const NOTE: String = "Shift operator: Tofufu. Terminal access still matches the operator name."
const TERMINAL_HINT: String = "The last operator dropped the shift note below the service return."
const CHEMICAL_NOTE: String = "The batch specification requires Nigari. Other substances may make tofu in other processes."
const SACK_TEXT := {
	"sack_edamame": "Fresh-picked plump pods. Harvest tag: cold chain before waxy skins dry.",
	"sack_mature": "Dry pale round beans. Grain tag: high protein yield for curd.",
	"sack_high_fat": "Oil-stained seams. Harvest grade: high oil content for candle wax.",
}
const INTAKE_TEXT := {
	"intake_chilled": "Frost gathers around pod trays. Maintenance card: keep freshly picked pods cold.",
	"intake_tofu": "Soaked beans, filter cloth and protein-curd residue surround this grinder.",
	"intake_oil": "An oil gauge feeds a line of small candle moulds.",
}

static func describe(identity: String, attempt: TofuDungeonAttempt) -> String:
	if SACK_TEXT.has(identity): return SACK_TEXT[identity]
	if INTAKE_TEXT.has(identity): return INTAKE_TEXT[identity]
	if identity == "shift_note": return NOTE
	if identity == "lab_terminal":
		return CHEMICAL_NOTE if attempt.lab.formula_unlocked else "Optional recipe terminal · log in to learn the batch formula. You can try a bottle without logging in. [?] offers a password clue."
	if identity.begins_with("container_"):
		var content: String = attempt.lab.content_at(identity)
		return "Sealed bottle · %s" % content.replace("_", " ").capitalize() if not content.is_empty() else "Unknown container"
	if identity == "coagulation_tank": return "Milk enters from the mill's sight glass. Carry a bottle here and pour to try it. A wrong ingredient releases a penalty wave. The optional terminal reveals the batch recipe."
	if identity == "traditional_press": return "Cloth-lined vessel and three keyed stones. Texture card: soft drains lightly; firm drains longer."
	if identity == "modern_press": return "Calibration plate marks an extra-firm pressure band between 82 and 90."
	if identity == "cutter": return "Five guides divide the whole block into six portions; inspect both end pieces."
	return "Factory equipment"

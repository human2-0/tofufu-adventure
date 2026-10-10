class_name CastleTrialGeometry
extends Node3D
## Authored puzzle stations, clue inscriptions and sealed route/return passages.

const CLUES: Array[String] = [
	"WARD OF RESTRAINT\nLevers change the runes they touch.\nLeave ASH and CROWN burning.\nTIDE sleeps.",
	"WARD OF MEMORY\nASH precedes TIDE.\nCROWN follows TIDE; SPARK follows CROWN.\nRecall all four.",
	"WARD OF MEASURE\nTIDE is twice ASH. CROWN is ASH + TIDE.\nTogether they weigh SIX.\nConfirm the balance."]
const LABELS: Array[Array] = [["ASH + TIDE", "TIDE + CROWN", "ALL THREE", "RESET"],
	["TIDE", "SPARK", "ASH", "CROWN"], ["ASH", "TIDE", "CROWN", "CONFIRM"]]
var layout: CastleMazeLayout
var deck: int
var gate: CastleGate
var shortcut: CastleGate
var shortcut_at := Vector3.INF
var controls: Array[Node3D] = []
var runes: Array[MeshInstance3D] = []
var handles: Array[Node3D] = []
var status: Label3D
var feedback := CastleGlyphFeedback.new()

func _ready() -> void:
	var hub := CastleMazeLayout.center(layout.solution[8], 0)
	_build_station(hub)
	feedback.build(runes)
	var a := CastleMazeLayout.center(layout.solution[-6], 0)
	var b := CastleMazeLayout.center(layout.solution[-5], 0)
	gate = _gate((a + b) * 0.5, a.x != b.x)
	_find_shortcut()
	if shortcut_at.is_finite(): shortcut = _gate(shortcut_at, absf(shortcut_at.x / 6.0 - roundf(shortcut_at.x / 6.0)) > 0.1)
	for index in [2, 6]:
		var at := CastleMazeLayout.center(layout.solution[index], 0)
		CastleGeometry.title(self, at + Vector3(0, 2.0, -2.6), "THE KING HELD BACK THE SEA'S FIRE.\nHis wards remember what his anger forgot.", 20)

func _build_station(hub: Vector3) -> void:
	for i in 4:
		var control := Node3D.new()
		control.position = hub + Vector3(-1.7 if i % 2 == 0 else 1.7, 0, -1.7 if i < 2 else 1.7)
		add_child(control)
		controls.append(control)
		CastleGeometry.solid(control, Vector3(0, 0.5, 0), Vector3(0.65, 1, 0.65), Color("3d313e"))
		var rune := MeadowGeometry.box(control, Vector3(0, 1.08, 0), Vector3(0.52, 0.18, 0.52), Color("c99d59"))
		runes.append(rune)
		var handle := Node3D.new()
		handle.position.y = 1.1
		control.add_child(handle)
		handles.append(handle)
		if deck == 0 and i < 3:
			MeadowGeometry.box(handle, Vector3(0, 0.3, 0), Vector3(0.09, 0.65, 0.09), Color("ddc39a"))
			MeadowGeometry.box(handle, Vector3(0, 0.6, 0), Vector3(0.4, 0.13, 0.13), Color("a84b37"))
		elif deck == 2 and i < 3:
			MeadowGeometry.box(handle, Vector3(0, 0.17, 0), Vector3(0.7, 0.14, 0.15), Color("e8be74"))
		feedback.glyphs.append_array(CastleTrialSigns.station(control, LABELS[deck][i], ["≋", "✦", "△", "♛"][i] if deck == 1 else "◆"))
	var signs := CastleTrialSigns.new()
	add_child(signs)
	signs.build(hub, CLUES[deck])
	status = signs.status

func _gate(at: Vector3, sideways: bool) -> CastleGate:
	var result := CastleGate.new()
	result.position = at
	result.rotation.y = PI * 0.5 if sideways else 0.0
	add_child(result)
	return result

func _find_shortcut() -> void:
	var best := 2
	for i in layout.solution.size():
		for j in range(i + 3, layout.solution.size()):
			var a := layout.solution[i]
			var b := layout.solution[j]
			if absi(a.x - b.x) + absi(a.y - b.y) != 1 or j - i <= best: continue
			best = j - i
			shortcut_at = (CastleMazeLayout.center(a, 0) + CastleMazeLayout.center(b, 0)) * 0.5

func present_state(solved: bool, opened: bool, bits: int, sequence: int, dials: Array[int], revision: int = 0, action: int = -1, accepted: bool = false) -> void:
	feedback.present(deck, solved, sequence, revision, action, accepted)
	gate.set_open(opened)
	if shortcut != null: shortcut.set_open(opened)
	if deck == 0:
		var positions: Array[int] = [((bits >> 2) ^ (bits >> 1)) & 1, (bits ^ (bits >> 1)) & 1, (bits ^ (bits >> 1) ^ (bits >> 2)) & 1]
		for i in 3: handles[i].rotation.x = -0.55 if positions[i] else 0.55
		status.text = "ASH %s · TIDE %s · CROWN %s" % ["●" if bits & 1 else "○", "●" if bits & 2 else "○", "●" if bits & 4 else "○"]
	elif deck == 1: status.text = "MEMORY %d / 4" % sequence
	else:
		status.text = "ASH %d · TIDE %d · CROWN %d" % dials
		for i in 3: handles[i].rotation.y = dials[i] * PI * 0.5
	if solved: status.text += "\nWARD RESTORED" if not opened else "SEAL OPEN · SHORTCUT OPEN"

func _process(delta: float) -> void:
	if feedback.pulse > 0: feedback.step(delta)

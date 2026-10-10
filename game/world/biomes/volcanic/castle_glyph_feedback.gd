class_name CastleGlyphFeedback
extends RefCounted
## Acknowledged presses pulse, while the remembered glyphs stay emissive.

const ORDER: Array[int] = [2, 0, 3, 1]
var materials: Array[StandardMaterial3D] = []
var glyphs: Array[Label3D] = []
var resting: Array[Color] = []
var last_revision: int = -1
var selected: int = -1
var pulse: float = 0.0
var success: bool = false

func build(runes: Array[MeshInstance3D]) -> void:
	for rune in runes:
		var material := MeadowGeometry.material(Color("cf9d59"))
		material.emission_enabled = true
		rune.material_override = material
		materials.append(material)
		resting.append(Color("cf9d59"))

func present(deck: int, solved: bool, sequence: int, revision: int, action: int, accepted: bool) -> void:
	for i in 4:
		var remembered := deck == 1 and ORDER.find(i) < sequence
		resting[i] = Color("6de4cf") if solved or remembered else Color("cf9d59")
	if revision != last_revision and last_revision >= 0 and action / 4 == deck and action >= 0:
		selected = action % 4
		success = accepted
		pulse = 0.9
	last_revision = revision
	step(0)

func step(delta: float) -> void:
	pulse = maxf(0, pulse - delta)
	for i in materials.size():
		var color := resting[i]
		var energy := 0.65 if color.g > 0.7 else 0.12
		if i == selected and pulse > 0:
			color = Color("b6fff0") if success else Color("ff6955")
			energy = 1.5 + sin(pulse * 22) * 0.4
		materials[i].albedo_color = color
		materials[i].emission = color
		materials[i].emission_energy_multiplier = energy
		for face in 4: glyphs[i * 4 + face].modulate = color

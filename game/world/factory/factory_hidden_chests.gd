class_name FactoryHiddenChests
extends Node3D
## Authored discoverable manufacturing stashes with hinged, cosmetic lids.

const IDS: Array[String] = ["stash_mill", "stash_press", "stash_pack"]
const POSITIONS: Array[Vector3] = [Vector3(308, 0.2, -188), Vector3(352, 0.2, -188), Vector3(332, 4.2, -213)]
var _lids: Array[Node3D] = []
var _opened: int = 0
var _initialized: bool = false
var _effects: FactoryEffectPool

func _ready() -> void:
	_effects = FactoryEffectPool.new()
	add_child(_effects)
	for index in 3: _build(index)

func _build(index: int) -> void:
	var chest := Node3D.new()
	chest.name = IDS[index]
	chest.position = POSITIONS[index] - Vector3.UP * 0.2
	add_child(chest)
	var base := MeadowGeometry.box(chest, Vector3(0, 0.3, 0), Vector3(1.05, 0.6, 0.75), Color("947049"), true)
	FactorySurfaceMaterials.apply_to(base, "wood", Color("947049"))
	var hinge := Node3D.new()
	hinge.position = Vector3(0, 0.6, -0.375)
	chest.add_child(hinge)
	_lids.append(hinge)
	var lid := MeadowGeometry.box(hinge, Vector3(0, 0.07, 0.375), Vector3(1.1, 0.14, 0.8), Color("c09a67"))
	FactorySurfaceMaterials.apply_to(lid, "wood", Color("c09a67"))
	(lid.material_override as StandardMaterial3D).uv1_world_triplanar = false
	for x in [-0.34, 0.34]:
		var band := MeadowGeometry.box(chest, Vector3(x, 0.3, 0.39), Vector3(0.08, 0.58, 0.04), Color("4a6260"))
		FactorySurfaceMaterials.apply_to(band, "iron", Color("4a6260"))
	var latch := MeadowGeometry.box(chest, Vector3(0, 0.57, 0.4), Vector3(0.16, 0.2, 0.06), Color("c9b274"))
	latch.name = "Latch"

func present(opened: int) -> void:
	if _lids.size() != 3: return
	for index in 3:
		var angle: float = -1.8 if (opened & (1 << index)) != 0 else 0.0
		if not _initialized: _lids[index].rotation.x = angle
		elif (opened & (1 << index)) != (_opened & (1 << index)):
			create_tween().tween_property(_lids[index], "rotation:x", angle, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			if angle != 0.0: _effects.burst("crumbs", POSITIONS[index] + Vector3.UP * 0.6)
	_opened = opened
	_initialized = true

static func position_for(id: String) -> Vector3:
	var index: int = IDS.find(id)
	return POSITIONS[index] if index >= 0 else Vector3.INF

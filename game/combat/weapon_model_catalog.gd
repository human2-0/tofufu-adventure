class_name WeaponModelCatalog
extends RefCounted
## Supplied 3D weapon assets and their calibrated source-space landmarks.

const KNIFE: PackedScene = preload("res://assets/weapons/sword/source/Knife_simple_texture.glb")
const NORI: PackedScene = preload("res://assets/weapons/nori/source/Nori_katana_texture.glb")
const SOYJET: PackedScene = preload("res://assets/weapons/sotjet/source/Soyjet_gun_texture.glb")
const SOYPOD: PackedScene = preload("res://assets/weapons/edamame/source/Soypod_blade_texture.glb")

const TIPS: Dictionary = {
	"knife": Vector3(-0.94835, 0.0, 0.0),
	"nori_katana": Vector3(0.0, 0.947337, 0.0),
	"edamame_sword": Vector3(0.0, 0.943018, 0.0),
	"sotjet": Vector3(-0.951424, 0.0, 0.0),
}
const GUARDS: Dictionary = {
	"knife": Vector3(0.16, 0.0, 0.0),
	"nori_katana": Vector3(0.0, -0.4, 0.0),
	"edamame_sword": Vector3(0.0, -0.44, 0.0),
	"sotjet": Vector3(0.42, -0.31, 0.0),
}
const GRIPS: Dictionary = {
	"knife": Vector3(0.55, 0.0, 0.0),
	"nori_katana": Vector3(0.0, -0.67, 0.0),
	"edamame_sword": Vector3(0.0, -0.72, 0.0),
	"sotjet": Vector3(0.42, -0.31, 0.0),
}

static func scene_for(item_id: String) -> PackedScene:
	match item_id:
		"knife": return KNIFE
		"nori_katana": return NORI
		"edamame_sword": return SOYPOD
		"sotjet": return SOYJET
	return null

static func calibration(item_id: String, reach: float) -> Transform3D:
	var tip: Vector3 = TIPS.get(item_id, Vector3.ZERO)
	var guard: Vector3 = GUARDS.get(item_id, Vector3.ZERO)
	var source_length := tip.distance_to(guard)
	if source_length <= 0.0: return Transform3D.IDENTITY
	var scale_factor := reach / source_length
	var correction := _source_to_weapon_axis(item_id)
	var basis := correction.scaled(Vector3.ONE * scale_factor)
	return Transform3D(basis, -(basis * guard))

static func grip_local(item_id: String, reach: float) -> Vector3:
	return calibration(item_id, reach) * GRIPS.get(item_id, Vector3.ZERO)

static func tip(item_id: String) -> Vector3:
	return TIPS.get(item_id, Vector3.ZERO)

static func _source_to_weapon_axis(item_id: String) -> Basis:
	if item_id in ["knife", "sotjet"]:
		# These models point toward local -X; rotate their barrel/blade to local -Z.
		return Basis(Vector3.UP, -PI * 0.5)
	# Nori and Soypod blades point up on source +Y.
	return Basis(Vector3.RIGHT, -PI * 0.5)

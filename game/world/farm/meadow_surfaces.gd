@static_unload
class_name MeadowSurfaces
extends RefCounted
## Shared painted surface materials, projected at a fixed world scale before baking.

const TEXTURES := {
	"brick": preload("res://assets/environment/meadow/brick.png"),
	"timber": preload("res://assets/environment/meadow/timber.png"),
	"roof": preload("res://assets/environment/meadow/roof.png"),
	"concrete": preload("res://assets/environment/meadow/concrete.png")
}
const SCALE := {"brick": 0.42, "timber": 0.65, "roof": 0.55, "concrete": 0.5}
const WOOD := ["78543a", "71503a", "946342", "bb8754", "ba9967", "75543b", "84684d", "a57a4c", "9b7047", "725946", "8d694e", "9d6c50", "c79b7b", "997252", "81603f", "80573b", "8c7854", "675442", "403f36", "b18a5e", "d6b685", "956948", "a57750", "665443", "766044", "80634b", "89694b"]
const CONCRETE := ["a8a493", "aaa99f", "a2a498", "b4a38a", "9a8a71"]
static var _materials: Dictionary[String, StandardMaterial3D] = {}

static func material(kind: String, tint: Color = Color.WHITE) -> StandardMaterial3D:
	var key := kind + tint.to_html()
	if _materials.has(key): return _materials[key]
	var result := MeadowGeometry.material(tint)
	result.albedo_texture = TEXTURES[kind]
	result.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	result.uv1_triplanar = true
	result.uv1_world_triplanar = true
	result.uv1_scale = Vector3.ONE * float(SCALE[kind])
	result.uv1_triplanar_sharpness = 8.0
	result.set_meta("meadow_surface", kind)
	_materials[key] = result
	return result

static func apply(view: MeshInstance3D, kind: String, tint: Color = Color.WHITE) -> void:
	view.material_override = material(kind, tint)

static func apply_tree(parent: Node3D) -> void:
	for child in parent.get_children():
		if not child is Node3D: continue
		if child is MeshInstance3D and child.mesh is BoxMesh:
			var view := child as MeshInstance3D
			var source := view.material_override if view.material_override != null else view.mesh.surface_get_material(0)
			if source is StandardMaterial3D and not source.has_meta("meadow_surface"):
				var hex: String = source.albedo_color.to_html(false)
				if hex in WOOD: apply(view, "timber", Color.WHITE.lerp(source.albedo_color, 0.22))
				elif hex in CONCRETE: apply(view, "concrete")
				elif hex in ["493d35", "493024"]: apply(view, "roof")
		apply_tree(child)

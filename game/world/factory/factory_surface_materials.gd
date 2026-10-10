class_name FactorySurfaceMaterials
extends RefCounted
## Metre-scaled authored surface paint; appearance never changes collision.

const SURFACES := {
	"floor": preload("res://assets/factory/surfaces/floor.svg"),
	"plaster": preload("res://assets/factory/surfaces/plaster.svg"),
	"roof": preload("res://assets/factory/surfaces/roof.svg"),
	"grip": preload("res://assets/factory/surfaces/grip.svg"),
	"iron": preload("res://assets/factory/surfaces/iron.svg"),
	"wood": preload("res://assets/factory/surfaces/wood.svg"),
	"linen": preload("res://assets/factory/surfaces/linen.svg"),
	"cream": preload("res://assets/factory/surfaces/cream.svg"),
}

static func material(kind: String, color: Color, outlined: bool = true) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.albedo_texture = SURFACES.get(kind, SURFACES.iron)
	result.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	result.uv1_triplanar = true
	result.uv1_world_triplanar = true
	var repeats: float = 0.5 if kind in ["floor", "plaster", "roof"] else 1.0
	result.uv1_scale = Vector3.ONE * repeats
	result.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	result.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	result.roughness = 1.0
	if outlined: result.next_pass = preload("res://game/world/factory/props/factory_ink.tres")
	result.set_meta("factory_surface", kind)
	return result

static func apply_to(visual: MeshInstance3D, kind: String, color: Color, outlined: bool = true) -> void:
	visual.material_override = material(kind, color, outlined)
	visual.set_meta("factory_surface", kind)

static func paint_local(visual: MeshInstance3D, kind: String) -> void:
	# A rotating gear, carried prop or raised lid keeps its original outline and
	# paint attached to its own mesh rather than drifting through world mapping.
	var source: StandardMaterial3D = (visual.material_override if visual.material_override != null else visual.mesh.surface_get_material(0)) as StandardMaterial3D
	var painted := material(kind, source.albedo_color)
	painted.uv1_world_triplanar = false
	painted.next_pass = source.next_pass
	visual.material_override = painted
	visual.set_meta("factory_surface", kind)
	visual.set_meta("factory_procedural_surface", true)

static func apply_building(factory: Node3D) -> void:
	# Authored building boxes are direct children. Prop scenes retain their own
	# object-space materials so carrying/animation cannot swim through a texture.
	for child in factory.get_children():
		if not child is MeshInstance3D: continue
		var visual := child as MeshInstance3D
		if visual.has_meta("factory_collision_support") or visual.has_meta("factory_surface"): continue
		if not visual.mesh is BoxMesh: continue
		var size: Vector3 = (visual.mesh as BoxMesh).size
		var color := _base_color(visual)
		var kind: String = "iron"
		if visual.name == "RampSurface": kind = "grip"
		elif size.y >= 3.5 and minf(size.x, size.z) < 1.0:
			kind = "wood" if color.r > color.g * 1.15 else "plaster"
		apply_to(visual, kind, color, visual.name != "RampSurface")

static func _base_color(visual: MeshInstance3D) -> Color:
	var source: Material = visual.material_override
	if source == null: source = visual.mesh.surface_get_material(0)
	return (source as StandardMaterial3D).albedo_color if source is StandardMaterial3D else Color.WHITE

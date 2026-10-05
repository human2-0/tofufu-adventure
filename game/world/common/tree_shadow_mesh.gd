@tool
class_name TreeShadowMesh
extends RefCounted
## A shared low-poly canopy/trunk shadow, independent of the detailed leaf mesh.

static var _mesh: ArrayMesh

static func build(parent: Node3D) -> void:
	if _mesh == null:
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		var crown := SphereMesh.new()
		crown.radius = 1.0
		crown.height = 2.0
		crown.radial_segments = 8
		crown.rings = 4
		for at: Vector3 in [Vector3(-0.5, 2.4, 0), Vector3(0.5, 2.5, 0.2), Vector3(0, 2.9, -0.3)]:
			surface.append_from(crown, 0, Transform3D(Basis.IDENTITY.scaled(Vector3(0.7, 0.6, 0.7)), at))
		var trunk := CylinderMesh.new()
		trunk.top_radius = 0.15
		trunk.bottom_radius = 0.30
		trunk.height = 2.0
		trunk.radial_segments = 8
		surface.append_from(trunk, 0, Transform3D(Basis.IDENTITY, Vector3.UP))
		_mesh = surface.commit()
	var shadow := MeshInstance3D.new()
	shadow.name = "CanopyShadow"
	shadow.mesh = _mesh
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	parent.add_child(shadow)

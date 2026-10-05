class_name SnowflakeMesh
extends RefCounted
## Tiny crossed six-arm crystals read in 3D without textures or per-flake nodes.

static func build() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for plane in 3:
		var basis := Basis(Vector3.UP, plane * PI / 3.0)
		for arm in 6:
			var direction := Vector2.from_angle(arm * TAU / 6.0)
			var side := Vector2(-direction.y, direction.x) * 0.008
			var a := Vector3(side.x, side.y, 0)
			var b := Vector3(-side.x, -side.y, 0)
			var tip := Vector3(direction.x, direction.y, 0) * 0.075
			for vertex in [a, b, tip + a, b, tip + b, tip + a]:
				surface.add_vertex(basis * vertex)
	surface.generate_normals()
	return surface.commit()

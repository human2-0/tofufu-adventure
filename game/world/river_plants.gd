class_name RiverPlants
extends RefCounted
## Batched bank reeds, cattails and notched lily pads, planted against collision terrain.

static func populate(parent: Node3D, ground_point: Callable) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8361
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 250:
		var z := rng.randf_range(-78.0, 155.0)
		if absf(z - 4.0) < 3.5: continue
		var side := -1.0 if i % 2 == 0 else 1.0
		var x := RiverCourse.center_x(z) + side * (RiverCourse.half_width(z) + rng.randf_range(0.4, 1.6))
		if i >= 170:
			var angle := rng.randf_range(0.0, TAU)
			x = -38.0 + cos(angle) * rng.randf_range(11.7, 14.0)
			z = 148.0 + sin(angle) * rng.randf_range(9.7, 12.0)
			if RiverCourse.bank_distance(x, z) < 0.3: continue
		var at: Vector3 = ground_point.call(x, z, 0.02)
		for blade in 7:
			var angle := rng.randf_range(0.0, TAU)
			var height := rng.randf_range(0.35, 0.95)
			var direction := Vector3(cos(angle), 0, sin(angle))
			var wide := direction.cross(Vector3.UP) * 0.07
			var tip := at + Vector3.UP * height + direction * 0.3
			_triangle(surface, at - wide, at + wide, tip, Color("65955c").lerp(Color("b0c77b"), rng.randf()))
		if i % 3 == 0:
			var top := at + Vector3.UP * rng.randf_range(0.9, 1.35)
			_triangle(surface, at - Vector3(0.025, 0, 0), at + Vector3(0.025, 0, 0), top, Color("668653"))
			for face in 5:
				var a := face * TAU / 5.0
				var b := (face + 1) * TAU / 5.0
				var left := Vector3(cos(a), 0, sin(a)) * 0.065
				var right := Vector3(cos(b), 0, sin(b)) * 0.065
				_triangle(surface, top + left, top + right, top + left + Vector3.UP * 0.27, Color("88664c"), false)
				_triangle(surface, top + right, top + right + Vector3.UP * 0.27, top + left + Vector3.UP * 0.27, Color("88664c"), false)
	for i in 22:
		var z := rng.randf_range(141.0, 154.0)
		var at := RiverCourse.point(z, rng.randf_range(-0.85, 0.85), 0.045)
		var radius := rng.randf_range(0.24, 0.52)
		for sector in range(1, 14):
			var a := sector * TAU / 15.0
			var b := (sector + 1) * TAU / 15.0
			_triangle(surface, at, at + Vector3(cos(a), 0, sin(a)) * radius, at + Vector3(cos(b), 0, sin(b)) * radius, Color("719e66"), false)
		if i % 4 == 0:
			MeadowGeometry.rock(parent, at + Vector3.UP * 0.08, Vector3(0.13, 0.09, 0.13), Color("f7c6bb"))
	surface.generate_normals()
	var plants := MeshInstance3D.new()
	plants.name = "RiverReedsAndLilies"
	plants.mesh = surface.commit()
	var material := ShaderMaterial.new()
	material.shader = preload("res://game/world/river_plants.gdshader")
	plants.material_override = material
	parent.add_child(plants)

static func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color, sway: bool = true) -> void:
	for i in 3:
		surface.set_color(color)
		surface.set_uv(Vector2(0.0, 1.0 if i == 2 and sway else 0.0))
		surface.add_vertex([a, b, c][i])

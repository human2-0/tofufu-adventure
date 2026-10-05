class_name RainforestGarden
extends RefCounted
## Layered broadleaf canopy, cliff creepers and reeds around the sanctuary.

static func build(falls: JungleWaterfall) -> void:
	for i in 16:
		var angle := i * TAU / 16.0
		var at := Vector3(cos(angle) * 23.5, 0, sin(angle) * 17.0)
		# Keep the approach open and retain a broad view of the cascade and sky.
		if at.z < -7.0: continue
		at.y = falls.ground_height(at)
		var tree := Node3D.new()
		tree.position = at
		tree.scale = Vector3(3.0, 3.5 + (i % 3) * 0.5, 3.0)
		falls.add_child(tree)
		NaturalTreeVisuals.build(tree)
		var trunk := StaticBody3D.new()
		trunk.collision_layer = 1
		trunk.collision_mask = 0
		tree.add_child(trunk)
		var collider := CollisionShape3D.new()
		var cylinder := CylinderShape3D.new()
		cylinder.radius = 0.22
		cylinder.height = 1.8
		collider.shape = cylinder
		collider.position.y = 0.9
		trunk.add_child(collider)
	for i in 14:
		var x := -12.0 + i * 1.85
		if absf(x) < 3.5: continue
		var top := 9.5 + cos(x * 0.2) * 2.0
		var length := 3.0 + fposmod(i * 1.7, 3.0)
		var stem := CylinderMesh.new()
		stem.top_radius = 0.028
		stem.bottom_radius = 0.045
		stem.height = length
		stem.radial_segments = 5
		stem.material = MeadowGeometry.material(Color("3c6743"))
		var vine := MeshInstance3D.new()
		vine.mesh = stem
		vine.position = Vector3(x, top - length * 0.5, 8.1)
		falls.add_child(vine)
		for leaf in 5:
			var side := -1.0 if leaf % 2 else 1.0
			JungleProps.leaf(falls, Vector3(x, top - leaf * length / 5, 8.0), Vector3(side, -0.2, -0.2), 0.65, Color("4d9257"))
	for i in 12:
		var angle := i * TAU / 12.0
		var at := Vector3(cos(angle) * 13.5, 0.1, sin(angle) * 9.0)
		if at.z > 4.0: continue
		for blade in 3:
			JungleProps.leaf(falls, at + Vector3(blade * 0.1, 0, 0), Vector3(0.2, 1.0, 0.2), 1.1, Color("408b69"))

static func wet_rock(falls: JungleWaterfall, at: Vector3, size: Vector3) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	var material := ShaderMaterial.new()
	material.shader = preload("res://game/world/biomes/jungle/waterfall_rock.gdshader")
	mesh.material = material
	var rock := MeshInstance3D.new()
	rock.mesh = mesh
	rock.position = at
	rock.scale = size
	rock.rotation.z = sin(at.x * 3.0) * 0.13
	falls.add_child(rock)
	rock.create_convex_collision()

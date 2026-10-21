class_name GigalopolisGeometry
extends RefCounted
## Small textured solids, guarded stairs and scout camp furnishings.

static func box(parent: Node3D, at: Vector3, size: Vector3, kind: String = "stone", solid: bool = false) -> MeshInstance3D:
	var view := MeadowGeometry.box(parent, at, size, Color.WHITE, solid)
	view.material_override = GigalopolisMaterials.surface(kind)
	view.set_meta("gigalopolis_surface", kind)
	return view

static func stair(parent: Node3D, start: Vector3, finish: Vector3, width: float = 3.2) -> void:
	var delta := finish - start
	var run := Vector2(delta.x, delta.z).length()
	var rotation := Basis(Vector3.UP, atan2(delta.x, delta.z)) * Basis(Vector3.RIGHT, -atan2(delta.y, run))
	var normal := rotation * Vector3.UP
	var ramp := box(parent, (start + finish) * 0.5 - normal * 0.15, Vector3(width, 0.3, delta.length()), "paving", true)
	ramp.basis = rotation
	var count := maxi(1, ceili(run / 0.45))
	for index in count:
		var at := start.lerp(finish, (index + 0.5) / count)
		var tread := box(parent, at, Vector3(width, 0.035, 0.10), "brass")
		tread.basis = rotation
	for side in [-1.0, 1.0]:
		var rail := box(parent, (start + finish) * 0.5 + rotation * Vector3(side * (width * 0.5 + 0.12), 0.65, 0), Vector3(0.16, 1.3, delta.length()), "metal", true)
		rail.basis = rotation

static func lamp(parent: Node3D, at: Vector3) -> void:
	box(parent, at + Vector3.UP * 1.7, Vector3(0.18, 3.4, 0.18), "metal", true)
	box(parent, at + Vector3.UP * 3.35, Vector3(0.7, 0.18, 0.7), "brass")
	MeadowGeometry.box(parent, at + Vector3.UP * 3.13, Vector3(0.45, 0.4, 0.45), Color("ffe8ac"))

static func camp(parent: Node3D, at: Vector3) -> void:
	# Open-front canvas shelter; the sleeping roll and roof never block the approach.
	box(parent, at + Vector3(-2.4, 0.12, -2), Vector3(2.5, 0.24, 2.8), "canvas")
	for side in [-1.0, 1.0]:
		var flap := box(parent, at + Vector3(-2.4 + side * 0.85, 1.2, -2), Vector3(0.12, 2.7, 3.4), "canvas")
		flap.rotation.z = side * 0.59
	box(parent, at + Vector3(-2.4, 1.1, -3.6), Vector3(2.7, 2.2, 0.12), "canvas", true)
	box(parent, at + Vector3(2.5, 0.55, -2), Vector3(2.4, 1.1, 1.5), "metal", true)
	box(parent, at + Vector3(2.5, 1.13, -2), Vector3(2.1, 0.06, 1.2), "canvas")
	for side in [-1.0, 1.0]:
		box(parent, at + Vector3(side * 2, 0.3, 2), Vector3(1.8, 0.6, 0.6), "stone", true)
	for index in 8:
		var angle := index * TAU / 8
		box(parent, at + Vector3(cos(angle) * 0.65, 0.13, sin(angle) * 0.65 + 1.5), Vector3(0.35, 0.26, 0.35), "stone")
	box(parent, at + Vector3(0, 0.17, 1.5), Vector3(0.7, 0.22, 0.7), "dark")
	var ember := MeadowGeometry.box(parent, at + Vector3(0, 0.32, 1.5), Vector3(0.45, 0.16, 0.45), Color("e99a55"))
	var glow := MeadowGeometry.material(Color("e99a55"))
	glow.emission_enabled = true
	glow.emission = Color("c86632")
	ember.material_override = glow

static func recon(parent: Node3D, at: Vector3) -> void:
	box(parent, at + Vector3.UP * 0.65, Vector3(0.22, 1.3, 0.22), "brass", true)
	var tube := box(parent, at + Vector3(0.3, 1.4, 0), Vector3(1.5, 0.4, 0.4), "metal")
	tube.rotation.z = -0.18
	box(parent, at + Vector3(1.05, 1.54, 0), Vector3(0.12, 0.5, 0.5), "brass")

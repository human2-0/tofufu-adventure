class_name GigalopolisCivic
extends RefCounted
## Open arcades, a U-shaped civic courtyard and a three-tier clocktower.

static func arcade(parent: Node3D) -> void:
	for side: float in [-1, 1]:
		for x: float in [-18, -6, 6, 18]:
			GigalopolisGeometry.box(parent, Vector3(x, 2.7, side * 11), Vector3(1.4, 6.2, 1.4), "stone", true)
			GigalopolisGeometry.box(parent, Vector3(x, 5.7, side * 11), Vector3(2.1, 0.5, 2.1), "frieze")
		for x: float in [-12, 0, 12]: _arch(parent, Vector3(x, 3.6, side * 11))
		for x: float in [-12, 12]:
			GigalopolisGeometry.box(parent, Vector3(x, 0.55, side * 7), Vector3(7, 1.1, 2.2), "brick", true)
			GigalopolisGeometry.box(parent, Vector3(x, 3, side * 7), Vector3(7.5, 0.16, 3), "canvas")
	_arcade_deck(parent)
	GigalopolisBuildingDetails.parapet(parent, Vector3(0, 8, 0), Vector2(41.5, 29.5), Vector2(-13, -5))
	GigalopolisBuildingDetails.stair(parent, Vector2(23, 26), Vector2(23, -8), 8)
	GigalopolisBuildingDetails.landing(parent, Vector3(22, 8, -10), 6)
	GigalopolisGeometry.camp(parent, Vector3(-14, 8, -3))
	GigalopolisGeometry.recon(parent, Vector3(15, 8, 7))

static func _arcade_deck(parent: Node3D) -> void:
	# The central skylight keeps ground-level walkers visible to the overhead camera.
	for side: float in [-1, 1]:
		GigalopolisGeometry.box(parent, Vector3(side * 15, 7.85, 0), Vector3(12, 0.3, 30), "metal", true)
		GigalopolisGeometry.box(parent, Vector3(0, 7.85, side * 13), Vector3(42, 0.3, 4), "metal", true)
		GigalopolisGeometry.box(parent, Vector3(side * 18, 7, 0), Vector3(1.8, 1.5, 28), "frieze", true)
		GigalopolisGeometry.box(parent, Vector3(0, 7, side * 11), Vector3(41, 1.5, 1.8), "frieze", true)
		GigalopolisGeometry.box(parent, Vector3(side * 9, 8.6, 0), Vector3(0.18, 1.2, 22), "metal", true)
		GigalopolisGeometry.box(parent, Vector3(0, 8.6, side * 11), Vector3(18, 1.2, 0.18), "metal", true)

static func _arch(parent: Node3D, at: Vector3) -> void:
	for index in 11:
		var angle: float = (index + 0.5) * PI / 11
		var piece := GigalopolisGeometry.box(parent, at + Vector3(cos(angle) * 5.5, sin(angle) * 2.5, 0), Vector3(1.8, 0.55, 1.25), "stone", true)
		piece.rotation.z = atan2(-cos(angle) * 2.5, sin(angle) * 5.5)

static func hall(parent: Node3D) -> void:
	var back := GigalopolisInterior.shell(parent, Vector3(0, 0, -12), Vector3(36, 12, 8))
	GigalopolisGeometry.box(back, Vector3(0, 11.85, 0), Vector3(40, 0.3, 12), "metal", true)
	GigalopolisGeometry.box(back, Vector3(0, 10.7, 4.2), Vector3(36, 1.1, 0.4), "frieze").set_meta("city_wall", true)
	for side: float in [-1, 1]:
		var wing := GigalopolisInterior.shell(parent, Vector3(side * 14, 0, 3), Vector3(8, 8, 22), "brick")
		GigalopolisProfiles.roof(wing, Vector3(0, 8, 0), 10, 24, 2.5)
		GigalopolisBuildingDetails.door(wing, Vector3(0, 0, 11.15), 3)
		for z: float in [-6, 1, 8]:
			GigalopolisBuildingDetails.windows(wing, Vector3(-side * 4.1, 4, z), 4, 2.3, Vector3(-side, 0, 0))
		GigalopolisInterior.finish(wing, "civic")
	for x: float in [-12, -4, 4, 12]:
		GigalopolisBuildingDetails.windows(back, Vector3(x, 6, 4.15), 5, 3.3, Vector3.BACK)
	GigalopolisBuildingDetails.door(back, Vector3(0, 0, 4.15), 3)
	GigalopolisBuildingDetails.parapet(parent, Vector3(0, 12, -12), Vector2(39.5, 11.5), Vector2(-4, 1))
	GigalopolisBuildingDetails.stair(parent, Vector2(23, 28), Vector2(23, -12), 12)
	GigalopolisBuildingDetails.landing(parent, Vector3(21, 12, -14), 8)
	GigalopolisGeometry.camp(back, Vector3(-6, 12, 0))
	GigalopolisGeometry.recon(back, Vector3(14, 12, 2))
	GigalopolisInterior.finish(back, "civic")
	GigalopolisProfiles.cylinder(parent, Vector3(0, 0.4, 4), 3, 0.8, "stone", true)
	GigalopolisProfiles.cylinder(parent, Vector3(0, 0.87, 4), 2.5, 0.15, "metal")

static func clocktower(parent: Node3D) -> void:
	var room := GigalopolisInterior.shell(parent, Vector3.ZERO, Vector3(15, 12, 15))
	GigalopolisBuildingDetails.door(room, Vector3(0, 0, 7.65), 3)
	GigalopolisGeometry.box(room, Vector3(0, 15, 0), Vector3(11, 6, 11), "brick", true)
	GigalopolisGeometry.box(room, Vector3(0, 18.85, 0), Vector3(14, 5.7, 14), "frieze", true)
	GigalopolisGeometry.box(room, Vector3(0, 21.85, 0), Vector3(20, 0.3, 20), "metal", true)
	for side: float in [-1, 1]:
		for x: float in [-4, 4]:
			GigalopolisBuildingDetails.windows(room, Vector3(x, 6, side * 7.6), 2.6, 4.5, Vector3(0, 0, side))
		_clock_face(room, Vector3(0, 19, side * 7.12), 0 if side > 0 else PI)
		_clock_face(room, Vector3(side * 7.12, 19, 0), side * PI / 2)
	GigalopolisBuildingDetails.parapet(room, Vector3(0, 22, 0), Vector2(19.5, 19.5), Vector2(-8, -2))
	GigalopolisBuildingDetails.stair(parent, Vector2(14, 46), Vector2(14, -3), 22)
	GigalopolisBuildingDetails.landing(parent, Vector3(12, 22, -5), 8)
	GigalopolisGeometry.camp(room, Vector3(-3, 22, 1))
	GigalopolisGeometry.recon(room, Vector3(5, 22, 6))

	GigalopolisInterior.finish(room, "civic")

static func _clock_face(parent: Node3D, at: Vector3, facing: float) -> void:
	var root := Node3D.new()
	root.position = at
	root.rotation.y = facing
	parent.add_child(root)
	GigalopolisGeometry.box(root, Vector3.ZERO, Vector3(5.4, 5.4, 0.2), "metal")
	GigalopolisGeometry.box(root, Vector3(0, 0, 0.15), Vector3(4.9, 4.9, 0.15), "stone")
	for index in 12:
		var angle: float = index * TAU / 12
		var tick := GigalopolisGeometry.box(root, Vector3(sin(angle) * 2, cos(angle) * 2, 0.27), Vector3(0.14, 0.5, 0.06), "brass")
		tick.rotation.z = -angle
	GigalopolisGeometry.box(root, Vector3(0, 0.7, 0.32), Vector3(0.15, 1.6, 0.08), "metal")
	var hand := GigalopolisGeometry.box(root, Vector3(0.5, 0.15, 0.33), Vector3(1.25, 0.18, 0.08), "metal")
	hand.rotation.z = 0.3

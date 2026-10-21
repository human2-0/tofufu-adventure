class_name GigalopolisIndustry
extends RefCounted
## Vaulted depots, sawtooth workshops and raised cylindrical water towers.

static func warehouse(parent: Node3D) -> void:
	var room := GigalopolisInterior.shell(parent, Vector3.ZERO, Vector3(38, 7, 28), "brick", 6)
	GigalopolisProfiles.roof(room, Vector3(0, 7, 0), 40, 31, 5.8, true)
	for side: float in [-1, 1]:
		if side < 0: GigalopolisGeometry.box(room, Vector3(0, 3, side * 14.12), Vector3(12, 6, 0.2), "metal").set_meta("city_wall", true)
		for x: float in [-13, 13]:
			GigalopolisBuildingDetails.windows(room, Vector3(x, 4, side * 14.15), 7, 2.6, Vector3(0, 0, side))
	for x: float in [-14, -7, 7, 14]:
		var y: float = 7.1 + 5.8 * sqrt(1.0 - x * x / 400.0)
		GigalopolisGeometry.box(room, Vector3(x, y, 0), Vector3(0.2, 0.2, 31.5), "brass")

	GigalopolisBuildingDetails.door(room, Vector3(0, 0, 14.12), 6)
	GigalopolisInterior.finish(room, "work")

static func workshop(parent: Node3D) -> void:
	var room := GigalopolisInterior.shell(parent, Vector3.ZERO, Vector3(35, 6, 28), "stone", 4)
	for index in 3:
		var x: float = -12.0 + index * 12
		GigalopolisProfiles.sawtooth(room, Vector3(x, 6, 0), 12, 31, 3)
		GigalopolisBuildingDetails.windows(room, Vector3(x, 5.15 if index == 1 else 4.2, 14.12), 8, 1.0 if index == 1 else 2.5, Vector3.BACK)
		GigalopolisGeometry.box(room, Vector3(x - 4, 9, -8), Vector3(1.2, 5, 1.2), "metal", true)
	GigalopolisBuildingDetails.door(room, Vector3(0, 0, 14.25), 4)

	GigalopolisInterior.finish(room, "work")

static func water_tower(parent: Node3D) -> void:
	GigalopolisProfiles.cylinder(parent, Vector3(0, 0.025, 0), 8, 0.05, "paving")
	for x: float in [-5, 5]:
		for z: float in [-5, 5]:
			GigalopolisGeometry.box(parent, Vector3(x, 5, z), Vector3(0.75, 10, 0.75), "metal", true)
	for side: float in [-1, 1]:
		var brace := GigalopolisGeometry.box(parent, Vector3(0, 5, side * 5), Vector3(12.2, 0.35, 0.35), "brass")
		brace.rotation.z = side * 0.55
	GigalopolisProfiles.cylinder(parent, Vector3(0, 11, 0), 6.6, 6, "metal", true)
	for y: float in [8.1, 11, 13.9]: GigalopolisProfiles.cylinder(parent, Vector3(0, y, 0), 6.85, 0.3, "brass")
	GigalopolisProfiles.cylinder(parent, Vector3(0, 14.2, 0), 7, 0.4, "roof", true)
	GigalopolisGeometry.box(parent, Vector3(7.7, 3.5, 0), Vector3(0.7, 7, 0.7), "metal", true)
	GigalopolisGeometry.box(parent, Vector3(4, 7, 0), Vector3(8, 0.7, 0.7), "metal")

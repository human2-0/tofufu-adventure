class_name GigalopolisHousing
extends RefCounted
## Gabled terrace houses, L-shaped apartments and smaller shopfront courts.

static func terraces(parent: Node3D) -> void:
	for index in 4:
		var x: float = (index - 1.5) * 8
		var height: float = 6.0 + (index % 3) * 2
		var room := GigalopolisInterior.shell(parent, Vector3(x, 0, 0), Vector3(7.6, height, 16), "brick" if index % 2 == 0 else "stone")
		GigalopolisProfiles.roof(room, Vector3(0, height, 0), 8.4, 18, 2.8)
		GigalopolisGeometry.box(room, Vector3(-2, height + 2.4, -4), Vector3(0.9, 3.4, 0.9), "brick", true)
		GigalopolisBuildingDetails.door(room, Vector3(0, 0, 8.12), 3.0)
		for side: float in [-1, 1]:
			for floor_index in int(height / 3):
				if side > 0 and floor_index == 0:
					for dx: float in [-2.5, 2.5]: GigalopolisBuildingDetails.windows(room, Vector3(dx, 2.1, side * 8.12), 1.6, 1.4, Vector3.BACK)
				else:
					GigalopolisBuildingDetails.windows(room, Vector3(0, 2.1 + floor_index * 3, side * 8.12), 4.4, 1.4, Vector3(0, 0, side))

		GigalopolisInterior.finish(room, "home")

static func apartments(parent: Node3D) -> void:
	for index in 2:
		var x: float = -9.0 if index == 0 else 9.0
		var z: float = 0.0 if index == 0 else -7.0
		var height: float = 12.0 if index == 0 else 8.0
		var depth: float = 26.0 if index == 0 else 12.0
		var room := GigalopolisInterior.shell(parent, Vector3(x, 0, z), Vector3(15, height, depth))
		GigalopolisGeometry.box(room, Vector3(0, height - 0.15, 0), Vector3(17, 0.3, depth + 2), "metal", true)
		for level in int(height / 3):
			if level == 0:
				for dx: float in [-4, 4]: GigalopolisBuildingDetails.windows(room, Vector3(dx, 2, depth * 0.5 + 0.12), 3.5, 1.7, Vector3.BACK)
			else:
				GigalopolisBuildingDetails.windows(room, Vector3(0, 2 + level * 3, depth * 0.5 + 0.12), 11, 1.7, Vector3.BACK)
			if level > 0: GigalopolisGeometry.box(room, Vector3(0, 1.3 + level * 3, depth * 0.5 + 0.7), Vector3(12, 0.12, 1.3), "brass").set_meta("city_wall", true)
		GigalopolisBuildingDetails.door(room, Vector3(0, 0, depth * 0.5 + 0.15))
		GigalopolisInterior.finish(room, "home")
	GigalopolisGeometry.box(parent, Vector3(7, 0.4, 6), Vector3(10, 0.8, 2), "stone", true)
	GigalopolisGeometry.box(parent, Vector3(7, 1.2, 6), Vector3(9, 1, 1.5), "canvas")

static func shops(parent: Node3D) -> void:
	for side: float in [-1, 1]:
		var room := GigalopolisInterior.shell(parent, Vector3(side * 10, 0, 0), Vector3(9, 4.8, 12), "brick")
		GigalopolisProfiles.roof(room, Vector3(0, 4.8, 0), 10, 14, 1.7)
		for x: float in [-2.9, 2.9]:
			GigalopolisBuildingDetails.windows(room, Vector3(x, 2.5, 6.12), 2, 2, Vector3.BACK)
		GigalopolisBuildingDetails.door(room, Vector3(0, 0, 6.12), 3)
		GigalopolisInterior.finish(room, "shop")

class_name FactoryMachines
extends RefCounted
## Authored production equipment, independent of quest outcomes.

static func build(parent: Node3D, index: int) -> void:
	var z := 0.0
	# Machines sit along the side aisles; the center remains clear for fights.
	var x := -6.0 if index % 2 == 0 else 6.0
	match index:
		0: # Bean receiving: chute, sacks and a conveyor.
			MeadowGeometry.box(parent, Vector3(x, 0.7, z), Vector3(2.2, 1.4, 4.5), Color("a47b57"), true)
			for dz in [-1.5, 0.0, 1.5]: MeadowGeometry.rock(parent, Vector3(6, 0.6, z + dz), Vector3(0.7, 0.8, 0.6), Color("c3b986"))
		1: # Wash basins with light blue water.
			for dz in [-1.8, 1.8]:
				MeadowGeometry.box(parent, Vector3(x, 0.7, z + dz), Vector3(2.5, 1.4, 2.3), Color("668783"), true)
				MeadowGeometry.box(parent, Vector3(x, 1.43, z + dz), Vector3(2.1, 0.04, 1.9), Color("83c8ca"))
		2: # Soak vats and delivery pipe.
			for dz in [-1.8, 1.8]: MeadowGeometry.rock(parent, Vector3(x, 0.8, z + dz), Vector3(1.2, 1.0, 1.2), Color("a5b9ae"), true)
			MeadowGeometry.box(parent, Vector3(x, 1.9, z), Vector3(0.25, 0.25, 5.6), Color("d0c6a5"))
		3: # Grinder drums.
			for dz in [-1.6, 1.6]: MeadowGeometry.rock(parent, Vector3(x, 1.05, z + dz), Vector3(1.2, 1.2, 0.7), Color("798b8b"), true)
			MeadowGeometry.box(parent, Vector3(x, 1.4, z), Vector3(0.6, 0.6, 3.0), Color("c7b595"))
		4: # Coagulant kettle with milk-white surface.
			MeadowGeometry.box(parent, Vector3(x, 0.8, z), Vector3(3.0, 1.6, 5.0), Color("818e8b"), true)
			MeadowGeometry.box(parent, Vector3(x, 1.63, z), Vector3(2.6, 0.05, 4.6), Color("f4f0d9"))
		5: # Press plates and finished tofu stacks.
			MeadowGeometry.box(parent, Vector3(x, 0.75, z), Vector3(3, 1.5, 4.5), Color("82796d"), true)
			for height in [1.65, 2.05]: MeadowGeometry.box(parent, Vector3(x, height, z), Vector3(2.2, 0.3, 2.2), Color("e9e4cd"))
			for dz in [-2.0, 0.0, 2.0]: MeadowGeometry.box(parent, Vector3(6, 0.5, z + dz), Vector3(0.9, 1, 0.9), Color("f6f2dd"))


		6: # Packing conveyor with cartons and sealed white tofu portions.
			MeadowGeometry.box(parent, Vector3(5,0.8,0), Vector3(3,1.6,9), Color("56776d"), true)
			for dz in [-3.0,-1.0,1.0,3.0]:
				MeadowGeometry.box(parent, Vector3(5,1.7,dz), Vector3(2,0.12,1.5), Color("cab080"))
				MeadowGeometry.box(parent, Vector3(5,2,dz), Vector3(1.3,0.5,1), Color("f9f1dc"))

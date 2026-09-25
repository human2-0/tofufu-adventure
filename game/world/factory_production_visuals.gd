class_name FactoryProductionVisuals
extends RefCounted
## Industrial dressing and visible production outputs for the six stations.

static func build(parent: Node3D, stage: int) -> void:
	for x in [-8.0,-4.0,0.0,4.0,8.0]:
		MeadowGeometry.box(parent, Vector3(x,0.025,0), Vector3(0.035,0.02,19), Color("87978e"))
	for z in [-8.0,-4.0,0.0,4.0,8.0]:
		MeadowGeometry.box(parent, Vector3(0,0.025,z), Vector3(21,0.02,0.035), Color("87978e"))
	# Feed and return pipes, elbows, bolted machine plinths, safety paint.
	for z in [-8.3,-7.7]:
		MeadowGeometry.box(parent, Vector3(0,2.8,z), Vector3(20,0.25,0.25), Color("b9c9bb"))
	MeadowGeometry.box(parent, Vector3(6,1.6,-8), Vector3(0.3,2.5,0.3), Color("b9c9bb"))
	for x in [-7.8,-4.2,4.2,7.8]:
		for z in [-3.5,3.5]: MeadowGeometry.box(parent, Vector3(x,0.06,z), Vector3(1.2,0.06,0.4), Color("ebc477"))
	if stage == 0:
		# Receiving belt rolls towards a blue wash trough.
		for z in [-1.8,-1.2,-0.6,0.0,0.6,1.2,1.8]:
			MeadowGeometry.box(parent, Vector3(-6,1.45,z), Vector3(2,0.12,0.22), Color("5d716a"))
		MeadowGeometry.box(parent, Vector3(6,0.7,-5), Vector3(3,1.4,3), Color("607b79"), true)
		MeadowGeometry.box(parent, Vector3(6,1.43,-5), Vector3(2.6,0.04,2.6), Color("8ecdd0"))
	if stage == 1 or stage == 3:
		for z in [-2.0,2.0]:
			MeadowGeometry.box(parent, Vector3(-6,1.85,z), Vector3(1.5,0.05,1.5), Color("b3d9d4") if stage == 1 else Color("fff4d5"))
	if stage == 2:
		MeadowGeometry.box(parent, Vector3(6,1,-4), Vector3(2.5,2,2.5), Color("e9e3cc"), true)
		MeadowGeometry.box(parent, Vector3(6,2.1,-4), Vector3(1.3,0.15,1.3), Color("576f65"))
	if stage == 3:
		# Nigari ingredient dispenser feeding the curd kettle.
		MeadowGeometry.box(parent, Vector3(0,1.6,-5), Vector3(0.65,0.75,0.65), Color("88c4b7"))
		MeadowGeometry.box(parent, Vector3(0,2.05,-5), Vector3(0.45,0.15,0.45), Color("e6cd91"))
	if stage == 4:
		for x in [-1.5,1.5]: MeadowGeometry.box(parent, Vector3(x,1.8,-5), Vector3(0.15,3,0.15), Color("67756c"))
		MeadowGeometry.box(parent, Vector3(0,2.9,-5), Vector3(3,0.7,0.12), Color("bdccc1"))
		MeadowGeometry.box(parent, Vector3(0,1.45,-5), Vector3(1.8,0.35,0.9), Color("fff3d6"))
	if stage == 5:
		for x in [-7.0,-5.0]:
			for z in [-3.0,0.0,3.0]:
				MeadowGeometry.box(parent, Vector3(x,0.6,z), Vector3(1.5,1.2,1.5), Color("b99b6d"), true)
				MeadowGeometry.box(parent, Vector3(x,1.22,z), Vector3(0.15,0.04,1.5), Color("f1d695"))

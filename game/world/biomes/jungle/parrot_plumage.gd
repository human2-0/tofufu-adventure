class_name ParrotPlumage
extends RefCounted
## Scarlet macaw silhouette, layered coverts, fanned primaries and a long tapered tail.

static var _body: ArrayMesh
static var _wing: ArrayMesh
static var _tail: ArrayMesh

static func body() -> ArrayMesh:
	if _body != null: return _body
	var tool := ParrotMesh.surface()
	ParrotMesh.oval(tool, Vector3(0, 0.64, 0.12), Vector3(0.93, 1.1, 1.42), Color("d62e49"), true, -0.15)
	ParrotMesh.oval(tool, Vector3(0, 0.67, -0.43), Vector3(0.67, 0.76, 0.62), Color("ff8555"), true)
	ParrotMesh.oval(tool, Vector3(0, 1.22, -0.58), Vector3(0.74, 0.89, 0.86), Color("f7444f"), true)
	ParrotMesh.oval(tool, Vector3(0, 1.24, -1.04), Vector3(0.38, 0.46, 0.5), Color("ffe9b1"))
	ParrotMesh.hooked_bill(tool)
	ParrotMesh.oval(tool, Vector3(0, 0.94, -1.05), Vector3(0.27, 0.22, 0.24), Color("3c455d"))
	for side in [-1.0, 1.0]: _face(tool, side)
	for i in 3:
		ParrotMesh.feather(tool, Vector3((i - 1) * 0.12, 1.49, -0.45), Vector3((i - 1) * 0.18, 1.68, -0.11), 0.07, Color("f86757"))
	# A leather saddle with gold piping, a raised pommel and tucked gripping toes.
	ParrotMesh.oval(tool, Vector3(0, 1.0, 0.24), Vector3(0.71, 0.14, 0.66), Color("e9b566"))
	ParrotMesh.oval(tool, Vector3(0, 1.04, 0.24), Vector3(0.64, 0.12, 0.59), Color("503d63"))
	ParrotMesh.oval(tool, Vector3(0, 1.12, -0.01), Vector3(0.55, 0.18, 0.16), Color("70507b"))
	_body = ParrotMesh.finish(tool)
	return _body

static func _face(tool: SurfaceTool, side: float) -> void:
	ParrotMesh.oval(tool, Vector3(side * 0.327, 1.24, -0.72), Vector3(0.13, 0.44, 0.44), Color("fff8df"))
	for line in 3:
		ParrotMesh.oval(tool, Vector3(side * 0.388, 1.12 + line * 0.038, -0.64 + line * 0.014), Vector3(0.013, 0.013, 0.17), Color("773c4a"))
	ParrotMesh.oval(tool, Vector3(side * 0.386, 1.33, -0.78), Vector3(0.052, 0.235, 0.19), Color("25313f"))
	ParrotMesh.oval(tool, Vector3(side * 0.413, 1.32, -0.785), Vector3(0.018, 0.14, 0.125), Color("fbb652"))
	ParrotMesh.oval(tool, Vector3(side * 0.425, 1.33, -0.80), Vector3(0.014, 0.112, 0.065), Color("15293b"))
	ParrotMesh.oval(tool, Vector3(side * 0.434, 1.36, -0.812), Vector3(0.011, 0.039, 0.033), Color("ffffff"))
	ParrotMesh.oval(tool, Vector3(side * 0.371, 1.47, -0.78), Vector3(0.067, 0.065, 0.23), Color("af293b"))
	ParrotMesh.oval(tool, Vector3(side * 0.16, 1.35, -1.12), Vector3(0.018, 0.027, 0.052), Color("5d4147"))
	for toe in 3:
		ParrotMesh.oval(tool, Vector3(side * (0.20 + toe * 0.06), 0.065, -0.15), Vector3(0.052, 0.10, 0.27), Color("526275"))
		ParrotMesh.oval(tool, Vector3(side * (0.20 + toe * 0.06), 0.07, -0.29), Vector3(0.044, 0.053, 0.09), Color("eee6c9"))

static func wing() -> ArrayMesh:
	if _wing != null: return _wing
	var tool := ParrotMesh.surface()
	ParrotMesh.oval(tool, Vector3(0.46, 0, 0.07), Vector3(1.15, 0.23, 0.74), Color("db3549"), true)
	for i in 9:
		var reach := 1.72 + sin(i / 8.0 * PI) * 0.38
		ParrotMesh.feather(tool, Vector3(0.55 + i * 0.07, -0.035, -0.15 + i * 0.052), Vector3(reach - i * 0.032, -0.08, -0.38 + i * 0.18), 0.16, Color("287ccb") if i % 2 == 0 else Color("379ede"))
	for i in 8:
		ParrotMesh.feather(tool, Vector3(0.25 + i * 0.07, 0.09, -0.18 + i * 0.07), Vector3(1.35 + i * 0.025, 0.02, -0.13 + i * 0.105), 0.13, Color("34b8a0"))
	for i in 7:
		ParrotMesh.feather(tool, Vector3(0.14 + i * 0.09, 0.14, -0.21 + i * 0.052), Vector3(0.93 + i * 0.045, 0.11, -0.10 + i * 0.08), 0.12, Color("ffce58"))
	for i in 5:
		ParrotMesh.feather(tool, Vector3(0.10 + i * 0.10, 0.18, -0.20 + i * 0.065), Vector3(0.54 + i * 0.10, 0.16, 0.07 + i * 0.08), 0.11, Color("f55459"))
	_wing = ParrotMesh.finish(tool)
	return _wing

static func tail() -> ArrayMesh:
	if _tail != null: return _tail
	var tool := ParrotMesh.surface()
	for i in 7:
		var side := float(i - 3)
		ParrotMesh.feather(tool, Vector3(side * 0.045, 0, 0), Vector3(side * 0.16, -0.32, 1.65 + (3 - absf(side)) * 0.18), 0.115, Color("e74555") if i in [2, 3, 4] else Color("278bc8"))
	_tail = ParrotMesh.finish(tool)
	return _tail

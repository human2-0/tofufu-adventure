class_name RainforestArt
extends RefCounted
## Recognizable toucan bills, iridescent hummingbirds, morpho wings and tree frogs.

static func bird(toucan: bool) -> Node3D:
	var body := Node3D.new()
	oval(body, Vector3.ZERO, Vector3(0.34, 0.42, 0.68), Color("243c42") if toucan else Color("29bca8"))
	oval(body, Vector3(0, 0.18, -0.29), Vector3(0.31, 0.32, 0.32), Color("243c42") if toucan else Color("419f88"))
	oval(body, Vector3(0, 0.04, -0.30), Vector3(0.25, 0.30, 0.15), Color("fff0b5") if toucan else Color("d679b3"))
	oval(body, Vector3(0, 0.16, -0.59), Vector3(0.20, 0.23, 0.60) if toucan else Vector3(0.035, 0.035, 0.48), Color("ffb838") if toucan else Color("304750"))
	if toucan: oval(body, Vector3(0, 0.12, -0.83), Vector3(0.18, 0.17, 0.17), Color("e77940"))
	for side in [-1.0, 1.0]:
		oval(body, Vector3(side * 0.15, 0.22, -0.37), Vector3.ONE * 0.055, Color("111e24"))
		var wing := Node3D.new()
		wing.name = "LeftWing" if side < 0 else "RightWing"
		body.add_child(wing)
		oval(wing, Vector3(side * 0.35, 0.08, 0.08), Vector3(0.67, 0.065, 0.29), Color("334d56") if toucan else Color("88dfe4"))
	oval(body, Vector3(0, -0.05, 0.44), Vector3(0.18, 0.10, 0.48), Color("243c42"))
	return body

static func butterfly() -> Node3D:
	var body := Node3D.new()
	oval(body, Vector3.ZERO, Vector3(0.035, 0.035, 0.20), Color("253d44"))
	for side in [-1.0, 1.0]:
		var wing := Node3D.new()
		wing.name = "LeftWing" if side < 0 else "RightWing"
		body.add_child(wing)
		oval(wing, Vector3(side * 0.15, 0, 0), Vector3(0.29, 0.018, 0.32), Color("205a94"))
		oval(wing, Vector3(side * 0.14, 0.012, -0.02), Vector3(0.22, 0.014, 0.23), Color("49b8f5"))
	return body

static func frog() -> Node3D:
	var body := Node3D.new()
	oval(body, Vector3.ZERO, Vector3(0.24, 0.13, 0.30), Color("63ba6b"))
	for side in [-1.0, 1.0]:
		oval(body, Vector3(side * 0.09, 0.065, -0.09), Vector3.ONE * 0.10, Color("faab58"))
		oval(body, Vector3(side * 0.09, 0.078, -0.135), Vector3.ONE * 0.045, Color("23353c"))
		oval(body, Vector3(side * 0.14, -0.025, 0.09), Vector3(0.16, 0.06, 0.22), Color("348c63"))
	return body

static func oval(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 10
	mesh.rings = 5
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.65
	mesh.material = material
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = at
	part.scale = size
	parent.add_child(part)

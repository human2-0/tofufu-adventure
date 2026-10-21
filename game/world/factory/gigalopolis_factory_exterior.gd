class_name GigalopolisFactoryExterior
extends RefCounted
## Sealed two-storey industrial shell. Entry loads the camera-cutaway production decks.

static func build(parent: Node3D) -> void:
	var at := Vector3(158,0,6)
	GigalopolisGeometry.box(parent, at + Vector3(0,4,0), Vector3(26,8,24), "stone", true)
	GigalopolisGeometry.box(parent, at + Vector3(0,8.3,0), Vector3(28,0.6,26), "metal", true)
	for x in [-8.0,0.0,8.0]:
		GigalopolisGeometry.box(parent, at + Vector3(x,9,0), Vector3(5,1.2,16), "metal", true)
		MeadowGeometry.box(parent, at + Vector3(x,5.6,12.05), Vector3(4,1.8,0.1), Color("e9d5a0"))
	for z in [-8.0,8.0]:
		MeadowGeometry.box(parent, at + Vector3(-13.05,5.5,z), Vector3(0.1,2,4), Color("e9d5a0"))
		GigalopolisGeometry.box(parent, at + Vector3(9,10.5,z), Vector3(1.8,5,1.8), "brass", true)
	MeadowGeometry.box(parent, Vector3(144.8,1.7,6), Vector3(0.2,3.4,5), Color("283e3d"))
	for z in [3.3,8.7]: MeadowGeometry.box(parent, Vector3(144.6,1.8,z), Vector3(0.3,3.6,0.3), Color("e4ba6c"))
	MeadowGeometry.signpost(parent, Vector3(141,0,10), "TOFU FACTORY · ENTER", -PI / 2.0)
	var sign_label := Label3D.new()
	sign_label.visibility_range_end = 32.0
	sign_label.visibility_range_end_margin = 2.0
	sign_label.double_sided = false
	sign_label.text = "GIGALOPOLIS\nTOFU FACTORY"
	sign_label.position = Vector3(142.8,6,6)
	sign_label.rotation.y = -PI / 2.0
	sign_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	sign_label.font_size = 40
	sign_label.no_depth_test = false
	sign_label.pixel_size = 0.016
	sign_label.modulate = Color("fff0bd")
	parent.add_child(sign_label)

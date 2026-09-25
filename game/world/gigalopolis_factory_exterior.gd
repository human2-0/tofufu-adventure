class_name GigalopolisFactoryExterior
extends RefCounted
## Sealed two-storey industrial shell. Entry loads the camera-cutaway production decks.

static func build(parent: Node3D) -> void:
	var at := Vector3(158,0,6)
	MeadowGeometry.box(parent, at + Vector3(0,4,0), Vector3(26,8,24), Color("6f9186"), true)
	MeadowGeometry.box(parent, at + Vector3(0,8.3,0), Vector3(28,0.6,26), Color("3b5957"), true)
	for x in [-8.0,0.0,8.0]:
		MeadowGeometry.box(parent, at + Vector3(x,9,0), Vector3(5,1.2,16), Color("9cbaae"), true)
		MeadowGeometry.box(parent, at + Vector3(x,5.6,12.05), Vector3(4,1.8,0.1), Color("e9d5a0"))
	for z in [-8.0,8.0]:
		MeadowGeometry.box(parent, at + Vector3(-13.05,5.5,z), Vector3(0.1,2,4), Color("e9d5a0"))
		MeadowGeometry.box(parent, at + Vector3(9,10.5,z), Vector3(1.8,5,1.8), Color("a59982"), true)
	MeadowGeometry.box(parent, Vector3(144.8,1.7,6), Vector3(0.2,3.4,5), Color("283e3d"))
	for z in [3.3,8.7]: MeadowGeometry.box(parent, Vector3(144.6,1.8,z), Vector3(0.3,3.6,0.3), Color("e4ba6c"))
	MeadowGeometry.signpost(parent, Vector3(141,0,10), "TOFU FACTORY · ENTER")
	var sign := Label3D.new()
	sign.text = "GIGALOPOLIS\nTOFU FACTORY"
	sign.position = Vector3(142.8,6,6)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.font_size = 40
	sign.no_depth_test = true
	sign.pixel_size = 0.016
	sign.modulate = Color("fff0bd")
	parent.add_child(sign)

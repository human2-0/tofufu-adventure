class_name FirstPersonBow
extends RefCounted
## Camera-space bow and drawing hand; all clocks come from authoritative combat.

var model: AngelBowModel

func build(view: FirstPersonWeapon) -> void:
	model = AngelBowModel.new()
	view._rig.add_child(model)
	model.hide()

func present(view: FirstPersonWeapon) -> void:
	var bow := view.combat.bow
	model.visible = bow.selected
	if not bow.selected: return
	var progress := bow.charge / AngelBow.CHARGE
	var reload_weight := sin(bow.reload_remaining / AngelBow.RELOAD * PI)
	model.position = Vector3(0.08, 0.10, -0.25)
	model.scale = Vector3.ONE * 0.65
	model.rotation = Vector3(0, 0.28, -0.08 + reload_weight * 0.65)
	model.present(progress, bow.reload_remaining <= 0.0 or bow.reload_remaining < 0.5)
	view._hands[0].position = model.position
	view._hands[1].position = model.position + Vector3(0, 0, 0.08 + progress * 0.22)
	view._hands[1].visible = true
	if bow.reload_remaining > 0:
		view._hands[1].position += Vector3(0.13, -reload_weight * 0.25, 0)

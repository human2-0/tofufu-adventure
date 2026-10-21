class_name BattleOutfitView
extends Node
## Outfit art stays on Fufu; badges and the existing aura identify gear on every skin.
var fighter: BattleFighter
var badge: Label3D

func _ready() -> void:
	badge = Label3D.new()
	badge.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	badge.position.y = 1.25
	badge.font_size = 18
	badge.pixel_size = 0.008
	badge.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	badge.visibility_range_end = 22
	fighter.actor.add_child(badge)
	fighter.gear_refreshed.connect(refresh)
	refresh()

func refresh() -> void:
	var equipment := fighter.loadout.equipment
	var set_id := equipment.complete_set()
	var count := 0
	for slot in CharacterEquipment.APPAREL_SLOTS:
		if equipment.get_slot(slot) != null: count += 1
	badge.text = tr(ApparelSetBonus.name_for(set_id)) if not set_id.is_empty() else (tr("Armour %d / 4") % count if count > 0 else "")
	badge.modulate = Color("ffdf85") if set_id == "celestial" else Color("d0edbb")
	fighter.actor.visuals.celestial_aura.set_active(set_id == "celestial")

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and badge != null: refresh()

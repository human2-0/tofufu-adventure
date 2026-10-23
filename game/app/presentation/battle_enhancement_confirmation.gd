class_name BattleEnhancementConfirmation
extends WeaponEnhancementConfirmation
## Same revalidated transaction, with truthful temporary-match bonuses and wording.

func _update_text() -> void:
	title = tr("Enhance match weapon?")
	get_ok_button().text = tr("Spend 1 chunk")
	cancel_button_text = tr("Cancel")
	if _weapon == null: return
	dialog_text = tr("Enhance %s for this match?\n\n%s\n\nConsumes 1 Magical Tofufu Chunk. Once per weapon. Dropping it keeps the upgrade; the next match starts fresh.") % [BattleItems.label(_weapon.item), tr(BattleWeaponUpgrade.bonus(_weapon.item.id))]

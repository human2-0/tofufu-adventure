class_name BattleLoadout
extends ActorLoadout
## Match gear refreshes retain live magazines, cadence and recoil across every swap.

func refresh(_show_feedback: bool = true) -> void:
	if _restoring: return
	var clock := combat.gun.cooldown
	var magazine := combat.gun.magazine
	var heat := combat.gun.recoil.heat
	var quiet := combat.gun.recoil.quiet_time
	var click := combat.equipment._click_remaining
	var special := combat.rules.cooldown
	var milk := combat.sotjet.milk
	var refill := combat.sotjet._refill_wait
	var previous := _active
	super.refresh(false)
	BattleBalance.apply(combat, BattleItems.weapon_kind(equipment.get_slot("combat_%d" % active_slot)))
	BattleWearStats.apply(combat, equipment)
	BattleWeaponUpgrade.apply(combat)
	combat.gun.magazine_capacity = BattleWeaponUpgrade.capacity(self)
	combat.gun.cooldown = clock
	combat.gun.magazine = mini(magazine, combat.gun.magazine_capacity)
	combat.gun.recoil.heat = heat
	combat.gun.recoil.quiet_time = quiet
	combat.equipment._click_remaining = click
	combat.rules.cooldown = special
	if _active == previous or _active == null or _active.item.id != "sotjet": combat.sotjet.milk = milk
	combat.sotjet._refill_wait = refill
